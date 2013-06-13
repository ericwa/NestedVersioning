#import "COEditingContext.h"
#import "COEditingContextPrivate.h"
#import "COItemTree.h"
#import "COMacros.h"
#import "CORelationshipCache.h"


/**
 * COEditingContext semantics:
 *
 * A mutable view on a set of COItem objects which materializes the relationships
 * as actual ObjC object references.
 *
 * The main feature is that the underlying objects can be changed arbitrairly and
 * the view will update accordingly.
 *
 * The COItems are garbage collected. See discussion in COItemTree.h.
 * The main motivation is to avoid having to store semantically redundant
 * "explicit delete" operations in diffs.
 *
 * Garbage collection shouldn't need to be invoked by the user. It happens
 * at commit time, and when loading a new object graph.
 *
 * TODO: Fit in change notifications
 *
 * Behaviours:
 *  - record which objects were edited/inserted
 *  - maintain consistency of composite relationship, for edits
 *    made through the COObject api (but not through addItem: api)
 *  - maintain relationship cache, for all edits
 *  - post notifications
 */
@implementation COEditingContext

#pragma mark Creation

- (id) initWithSchemaRegistry: (COSchemaRegistry *)aRegistry
{
    SUPERINIT;
    objectsByUUID_ = [[NSMutableDictionary alloc] init];
    insertedObjects_ = [[NSMutableSet alloc] init];
    modifiedObjects_ = [[NSMutableSet alloc] init];
    schemaRegistry_ = [aRegistry retain];
    relationshipCache_ = [[CORelationshipCache alloc] init];
    return self;
}

+ (COEditingContext *) editingContext
{
    return [[[self alloc] initWithSchemaRegistry: nil] autorelease];
}

+ (COEditingContext *) editingContextWithSchemaRegistry: (COSchemaRegistry *)aRegistry
{
    return [[[self alloc] initWithSchemaRegistry: aRegistry] autorelease];
}

- (void) dealloc
{
    [objectsByUUID_ release];
    [rootObjectUUID_ release];
    [insertedObjects_ release];
    [modifiedObjects_ release];
    [schemaRegistry_ release];
    [relationshipCache_ release];
    [super dealloc];
}

#pragma mark Schema

- (COSchemaRegistry *) schemaRegistry
{
    return schemaRegistry_;
}

#pragma mark begin COItemGraph protocol

- (COUUID *) rootItemUUID
{
    return rootObjectUUID_;
}

/**
 * Returns immutable item
 */
- (COItem *) itemForUUID: (COUUID *)aUUID
{
    COObject *object = [objectsByUUID_ objectForKey: aUUID];
    if (nil != object)
    {
        // FIXME: return an immutable copy
        return [object->item_ copy];
    }
    return nil;
}

- (NSArray *) itemUUIDs
{
    return [objectsByUUID_ allKeys];
}

/**
 * Insert or update an item.
 */
- (void) addItem: (COItem *)item
{
    NSParameterAssert(item != nil);
    
    COUUID *uuid = [item UUID];
    COObject *currentObject = [objectsByUUID_ objectForKey: uuid];
    
    if (currentObject == nil)
    {
        currentObject = [[[COObject alloc] initWithItem: item
                                          parentContext: self] autorelease];
        [objectsByUUID_ setObject: currentObject forKey: uuid];
        [relationshipCache_ addItem: item];
        [insertedObjects_ addObject: uuid];
    }
    else
    {
        [relationshipCache_ removeItem: currentObject->item_];
        [currentObject setItem: item];
        [relationshipCache_ addItem: item];
        [modifiedObjects_ addObject: uuid];
    }
}

#pragma mark end COItemGraph protocol

/**
 * Replaces the editing context.
 *
 * There are 3 kinds of change:
 *  - New objects are inserted
 *  - Removed objects are removed
 *  - Changed objects are updated. (sub-case: identical objects)
 */
- (void) setItemTree: (id <COItemGraph>)aTree
{
    [self clearChangeTracking];

    // 1. Do updates.
    
    ASSIGN(rootObjectUUID_, [aTree rootItemUUID]);
    
    for (COUUID *uuid in [aTree itemUUIDs])
    {
        [self addItem: [aTree itemForUUID: uuid]];
    }
    
    // 3. Do GC
    
    [self gc_];
}

- (COObject *) rootObject
{
    return [self objectForUUID: [self rootItemUUID]];
}

- (void) setRootObject: (COObject *)anObject
{
    NSParameterAssert([anObject editingContext] == self);
    ASSIGN(rootObjectUUID_, [anObject UUID]);
}

#pragma mark change tracking

/**
 * Returns the set of objects inserted since change tracking was cleared
 */
- (NSSet *) insertedObjectUUIDs
{
    return insertedObjects_;
}
/**
 * Returns the set of objects modified since change tracking was cleared
 */
- (NSSet *) modifiedObjectUUIDs
{
    return modifiedObjects_;
}
- (NSSet *) insertedOrModifiedObjectUUIDs
{
    return [insertedObjects_ setByAddingObjectsFromSet: modifiedObjects_];
}

- (void) clearChangeTracking
{
    [insertedObjects_ removeAllObjects];
    [modifiedObjects_ removeAllObjects];
}

- (COObject *) insertObjectWithSchemaName: (NSString *)aSchemaName
{
    COMutableItem *item = [COMutableItem item];
    // FIXME: Decide between this and the schemaName_ ivar in COItem
    if (aSchemaName != nil)
    {
        [item setValue: aSchemaName forAttribute: kCOSchemaName type: kCOStringType];
    }
    
    COObject *object = [[[COObject alloc] initWithItem: item parentContext: self] autorelease];
    [objectsByUUID_ setObject: object forKey: [object UUID]];
    
    NSLog(@"Inserting object %@", [object UUID]);
    return object;
}

- (COObject *) insertObject
{
    return [self insertObjectWithSchemaName: nil];
}

#pragma mark access

- (COObject *) objectForUUID: (COUUID *)aUUID
{
    return [objectsByUUID_ objectForKey: aUUID];
}

/**
 * @return If there exists an object which has a [COType embeddedObjectType] reference to
 * anObject, return that object. Otherwise return nil.
 */
- (COObject *) embeddedObjectParent: (COObject *)anObject
{
    CORelationshipRecord *record = [relationshipCache_ parentForUUID: [anObject UUID]];
    
    return [objectsByUUID_ objectForKey: record.uuid];
}

// FIXME: How should this api look?
- (NSSet *) referrersForUUID: (COUUID *)anObject
{
    return [relationshipCache_ referrersForUUID: anObject];
}

#pragma mark garbage collection

/**
 * Call to update the view to reflect one object becoming unavailable.
 *
 * Preconditions:
 *  - No objects in the context should have composite relationsips
 *    to uuid.
 *
 * Postconditions:
 *  - objectForUUID: will return nil
 *  - the COObject previously held by the context will be turned into a "zombie"
 *    and the COEditingContext will release it, so it will be deallocated if
 *    no user code holds a reference to it.
 */
- (void) removeSingleObject_: (COUUID *)uuid
{
    COObject *anObject = [objectsByUUID_ objectForKey: uuid];
    COItem *item = anObject->item_;
    
    // Update relationship cache
    
    [relationshipCache_ removeItem: item];
    
    // Update change tracking
    
    [insertedObjects_ removeObject: uuid];
    [modifiedObjects_ removeObject: uuid];
    
    // Mark the object as a "zombie"
    
    [anObject markAsRemovedFromContext];
    
    // Release it from the objects dictionary (may release it)
    
    [objectsByUUID_ removeObjectForKey: uuid];
    anObject = nil;
}

- (void) gcDeadObjects: (NSSet *)dead
{
    for (COUUID *deadUUID in dead)
    {
        [self removeSingleObject_: deadUUID];
    }
}

- (void) gcDfs_: (COObject *)anObject uuids: (NSMutableSet *)set
{
    COUUID *uuid = anObject->item_->uuid;
    if ([set containsObject: uuid])
    {
        return;
    }
    [set addObject: uuid];
    
    // Call recursively on all composite and referenced objects
    for (COObject *obj in [anObject embeddedOrReferencedObjects])
    {
        [self gcDfs_: obj uuids: set];
    }
}

- (void) gc_
{
    NSArray *allKeys = [objectsByUUID_ allKeys];
    
    NSMutableSet *live = [NSMutableSet setWithCapacity: [allKeys count]];
    [self gcDfs_: [self rootObject] uuids: live];
    
    NSMutableSet *dead = [NSMutableSet setWithArray: allKeys];
    [dead minusSet: live];
    
    [self gcDeadObjects: dead];
}

#pragma mark copy, equality, hash

/**
 * Returns a copy of the reciever, not including any change tracking
 * information.
 */
- (id) copyWithZone: (NSZone *)aZone
{
    COEditingContext *aCopy = [COEditingContext editingContextWithSchemaRegistry: schemaRegistry_];
    [aCopy setItemTree: self];
    return aCopy;
}

- (BOOL) isEqual:(id)object
{
    if (object == self)
    {
        return YES;
    }
	if (![object isKindOfClass: [self class]])
	{
		return NO;
	}
    
    COEditingContext *otherContext = (COEditingContext *)object;
    
    if (!((rootObjectUUID_ == nil && otherContext->rootObjectUUID_ == nil)
          || [rootObjectUUID_ isEqual: otherContext->rootObjectUUID_]))
    {
        return NO;
    }
    
    if (![[NSSet setWithArray: [self itemUUIDs]]
          isEqual: [NSSet setWithArray: [otherContext itemUUIDs]]])
    {
        return NO;
    }
    
    for (COUUID *aUUID in [self itemUUIDs])
    {
        COItem *selfItem = [self objectForUUID: aUUID]->item_;
        COItem *otherItem = [otherContext objectForUUID: aUUID]->item_;
        if (![selfItem isEqual: otherItem])
        {
            return NO;
        }
    }
    return YES;
}

- (NSUInteger) hash
{
	return [rootObjectUUID_ hash] ^ 13803254444065375360ULL;
}

// Relationship cache

- (void) updateRelationshipIntegrityWithOldValue: (id)oldVal
                                         oldType: (COType)oldType
                                        newValue: (id)newVal
                                         newType: (COType)newType
                                     forProperty: (NSString *)aProperty
                                        ofObject: (COUUID *)anObject
{
    [relationshipCache_ updateRelationshipCacheWithOldValue: oldVal
                                                    oldType: oldType
                                                   newValue: newVal
                                                    newType: newType
                                                forProperty: aProperty
                                                   ofObject: anObject];
    [modifiedObjects_ addObject: anObject];
}

@end
