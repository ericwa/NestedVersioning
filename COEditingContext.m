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

#pragma mark Schema

- (COSchemaRegistry *) schemaRegistry
{
    return schemaRegistry_;
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

#pragma mark begin COItemGraph protocol

- (COUUID *) rootItemUUID
{
    return rootObjectUUID_;
}

- (COItem *) itemForUUID: (COUUID *)aUUID
{
    COObject *object = [objectsByUUID_ objectForKey: aUUID];
    if (nil != object)
    {
        return object->item_;
    }
    return nil;
}

- (NSArray *) itemUUIDs
{
    return [objectsByUUID_ allKeys];
}

- (void) addItem: (COItem *)anItem
{
    
}

#pragma mark end COItemGraph protocol

- (id) copyWithZone: (NSZone *)aZone
{
    // FIXME: Handle copying 
    return [[[self class] alloc] initWithItemTree: [self itemTree]];
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
    
    if (![[self allObjectUUIDs] isEqual: [otherContext allObjectUUIDs]])
    {
        return NO;
    }
    
    for (COUUID *aUUID in [self allObjectUUIDs])
    {
        COItem *selfItem = [[self objectForUUID: aUUID] item];
        COItem *otherItem = [[otherContext objectForUUID: aUUID] item];
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
        [self createOrUpdateObjectForItem: [aTree itemForUUID: uuid]];
    }
    
    // 3. Do GC
    
    [self gc_];
    

    // TODO: Send change notification
}



- (COObject *) createOrUpdateObjectForItem: (COItem *)item
{
    COUUID *aUUID = [item UUID];
    COObject *currentObject = [objectsByUUID_ objectForKey: aUUID];
    
    if (currentObject == nil)
    {
        // Create new
        
        currentObject = [[[COObject alloc] initWithItem: item
                                          parentContext: self] autorelease];
        [objectsByUUID_ setObject: currentObject forKey: aUUID];
        
        // FIXME: Update relationship cache
    }
    else
    {
        // Update existing
        
        [currentObject setItem: item];
        
        // FIXME: update relationhsip cache
    }
    
    return currentObject;
}

- (void) setRootObject: (COObject *)anObject
{
    NSParameterAssert([anObject editingContext] == self);
    ASSIGN(rootObjectUUID_, [anObject UUID]);
}

#pragma mark change tracking

- (NSSet *) insertedObjectUUIDs
{
    return insertedObjects_;
}
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

@end



@implementation COEditingContext (Private)


- (void) recordInsertedObjectUUID: (COUUID *)aUUID
{
    [insertedObjects_ addObject: aUUID];
}

- (void) recordModifiedObjectUUID: (COUUID *)aUUID
{
    [modifiedObjects_ addObject: aUUID];
}

- (COObject *) insertObjectWithSchemaName: (NSString *)aSchemaName
{
    COMutableItem *item = [COMutableItem item];
    if (aSchemaName != nil)
    {
        [item setValue: aSchemaName forAttribute: kCOSchemaName type: kCOStringType];
    }
    
    COObject *object = [[[COObject alloc] initWithItem: item parentContext: self] autorelease];
    [objectsByUUID_ setObject: object forKey: [object UUID]];
//    NSLog(@"Inserting object %@", [object UUID]);
    return object;
}

- (COObject *) insertObject
{
    return [self insertObjectWithSchemaName: nil];
}

- (COObject *) embeddedObjectParent: (COObject *)anObject
{
    return [objectsByUUID_ objectForKey: [relationshipCache_ parentForUUID: [anObject UUID]]];
}

#pragma mark garbage collection

- (void) updateRelationshipCacheForItemRemoval: (COItem *)item
{
    for (COUUID *embeddedUUID in [item embeddedItemUUIDs])
    {
        [relationshipCache_ clearParentForUUID: embeddedUUID];
    }
    
    for (NSString *key in [item attributeNames])
	{
		if (COPrimitiveType([item typeForAttribute: key]) == kCOReferenceType)
		{
			for (COUUID *referenced in [item allObjectsForAttribute: key])
			{
                [relationshipCache_ removeReferrerUUID: item->uuid
                                               forUUID: referenced
                                           forProperty: key];
			}
		}
	}
}

- (void) updateRelationshipCacheForItemInsertion: (COItem *)item
{
    for (COUUID *embeddedUUID in [item embeddedItemUUIDs])
    {
        [relationshipCache_ set : embeddedUUID];
    }
    
    for (NSString *key in [item attributeNames])
	{
		if (COPrimitiveType([item typeForAttribute: key]) == kCOReferenceType)
		{
			for (COUUID *referenced in [item allObjectsForAttribute: key])
			{
                [relationshipCache_ removeReferrerUUID: item->uuid
                                               forUUID: referenced
                                           forProperty: key];
			}
		}
	}
}


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
    
    // Look at all outgoing references, and remove them from the
    // relationship cache.
    
    [self updateRelationshipCacheForItemRemoval: item];
    
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
    for (COUUID *deadUUID : dead)
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
//    for (COObject *obj : [anObject->item_ des])
    
    // Call recursively on all composite and referenced objects
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

#pragma mark end gc

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
}

@end
