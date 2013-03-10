#import "COEditingContext.h"
#import "COEditingContextPrivate.h"
#import "COItemTree.h"
#import "COMacros.h"


@implementation COEditingContext

#pragma mark Creation

- (id) initWithSchemaRegistry: (COSchemaRegistry *)aRegistry
{
    SUPERINIT;
    objectsByUUID_ = [[NSMutableDictionary alloc] init];
    insertedObjects_ = [[NSMutableSet alloc] init];
    deletedObjects_ = [[NSMutableSet alloc] init];
    modifiedObjects_ = [[NSMutableSet alloc] init];
    schemaRegistry_ = [aRegistry retain];
    embeddedObjectParentUUIDForUUID_ = [[NSMutableDictionary alloc] init];
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

- (NSSet *) allObjectUUIDs
{
    return [NSSet setWithArray: [objectsByUUID_ allKeys]];
}

- (void) dealloc
{
    [objectsByUUID_ release];
    [rootObjectUUID_ release];
    [insertedObjects_ release];
    [deletedObjects_ release];
    [modifiedObjects_ release];
    [schemaRegistry_ release];
    [embeddedObjectParentUUIDForUUID_ release];
    [super dealloc];
}

- (COObject *) rootObject
{
    if (rootObjectUUID_ != nil)
    {
        return [self objectForUUID: rootObjectUUID_];
    }
    return nil;
}

- (COObject *) objectForUUID: (COUUID *)uuid
{
    return [objectsByUUID_ objectForKey: uuid];
}

- (COItemTree *) itemTree
{
    if (rootObjectUUID_ == nil)
    {
        [NSException raise: NSGenericException format: @"no root object!"];
    }
    NSMutableDictionary *itemByUUID = [NSMutableDictionary dictionary];
    for (COUUID *uuid in objectsByUUID_)
    {
        [itemByUUID setObject: [[self objectForUUID: uuid] item]
                       forKey: uuid];
    }
    return [[[COItemTree alloc] initWithItemForUUID: itemByUUID
                                       rootItemUUID: rootObjectUUID_] autorelease];
}

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

    COObject *selfRoot = [self rootObject];
    COObject *otherRoot = [otherContext rootObject];
    
    // Deep equality test
    return [selfRoot isEqual: otherRoot];
}

- (NSUInteger) hash
{
	return [rootObjectUUID_ hash] ^ 13803254444065375360ULL;
}

- (void) setItemTree: (COItemTree *)aTree
{
    [self clearChangeTracking];
    
    NSSet *initialUUIDs = [[self rootObject] allObjectUUIDs];
    
    ASSIGN(rootObjectUUID_, [aTree rootItemUUID]);
    
    [self updateObject: rootObjectUUID_
        fromItemTree: aTree
             setParent: nil];
    
    // The update is now complete. Remove orphans
    
    NSMutableSet *orphanedUUIDs = [NSMutableSet setWithSet: [[self rootObject] allObjectUUIDs]];
    [orphanedUUIDs minusSet: initialUUIDs];
    
    NSLog(@"setObjectTree: orphaned objects: %@", orphanedUUIDs);
    
    for (COUUID *uuid in orphanedUUIDs)
    {
        COObject *orphan = [objectsByUUID_ objectForKey: uuid];
        [orphan markAsRemovedFromContext];
        [objectsByUUID_ removeObjectForKey: uuid];
    }
    
    // TODO: Send change notification
}

- (void) setRootObject: (COObject *)anObject
{
    if (anObject == nil)
    {
        DESTROY(rootObjectUUID_);
        return;
    }
    
    NSParameterAssert([anObject editingContext] == self);
    
    COObject *newRootParent = [anObject embeddedObjectParent];
    if (newRootParent != nil)
    {
        [newRootParent removeDescendentObject: anObject];
    }
    
    ASSIGN(rootObjectUUID_, [anObject UUID]);
}

#pragma mark change tracking

- (NSSet *) insertedObjectUUIDs
{
    return insertedObjects_;
}
- (NSSet *) deletedObjectUUIDs
{
    return deletedObjects_;
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
    [deletedObjects_ removeAllObjects];
    [modifiedObjects_ removeAllObjects];
}

@end



@implementation COEditingContext (Private)

- (void) removeUnreachableObjectAndChildren: (COUUID *)aUUID
{
//    NSParameterAssert(![aUUID isEqual: rootObjectUUID_]);
//
//    COObject *object = [objectsByUUID_ objectForKey: aUUID];
//    if (object == nil)
//    {
//        return; // nothing to do since the object is not in memory
//    }
//    
//    NSAssert(![[[object parentObject] directDescendentObjectUUIDs] containsObject: [object UUID]],
//             @"%@ should have already been detached from its parent", aUUID);
//    
//    for (COUUID *uuid in [object allDescendentObjectUUIDs])
//    {
//        COObject *objectToRemove = [self objectForUUID: uuid];
//        [objectToRemove markAsRemovedFromContext];
//        
//        [objectsByUUID_ removeObjectForKey: uuid]; // should free object unless there are external references
//    }
}

- (COObject *) updateObject: (COUUID *)aUUID
             fromObjectTree: (COItemTree *)aTree
                  setParent: (COObject *)parent
             updatedObjects: (NSMutableSet *)handledSet
{
    // Check for cycles.
    
    if ([handledSet containsObject: aUUID])
    {
        [NSException raise: NSGenericException format: @"Cycle detected"];
    }
    [handledSet addObject: aUUID];
    
    // Handle the object...
    
    COObject *currentObject = [objectsByUUID_ objectForKey: aUUID];
    COItem *item = [aTree itemForUUID: aUUID];
    
    if (currentObject == nil)
    {
        // Create new
        currentObject = [[[COObject alloc] initWithItem: item
                                          parentContext: self
                                                 parent: parent] autorelease];
        [objectsByUUID_ setObject: currentObject forKey: aUUID];
    }
    else
    {
        // Update existing
        
        [currentObject updateItem: item
                    parentContext: self // FIXME: unnecessary param
                           parent: parent];
    }
    
    // Process children recursively
    
    for (COUUID *descendent in [item embeddedItemUUIDs])
    {
        [self updateObject: descendent
            fromObjectTree: aTree
                 setParent: currentObject
            updatedObjects: handledSet];
    }
    
    return currentObject;
}

- (COObject *) updateObject: (COUUID *)aUUID
             fromItemTree: (COItemTree *)aTree
                  setParent: (COObject *)parent
{
    return [self updateObject: aUUID
               fromObjectTree: aTree
                    setParent: parent
               updatedObjects: [NSMutableSet set]];
}


- (void) recordInsertedObjectUUID: (COUUID *)aUUID
{
    [insertedObjects_ addObject: aUUID];
}

- (void) recordDeletedObjectUUID: (COUUID *)aUUID
{
    [deletedObjects_ addObject: aUUID];
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
        [item setValue: aSchemaName forAttribute: kCOSchemaName type: [COType stringType]];
    }
    
    COObject *object = [[[COObject alloc] initWithItem: item parentContext: self] autorelease];
    [objectsByUUID_ setObject: object forKey: [object UUID]];
    return object;
}

- (COObject *) insertObject
{
    return [self insertObjectWithSchemaName: nil];
}

- (COObject *) embeddedObjectParent: (COObject *)anObject
{
    return [self objectForUUID: [embeddedObjectParentUUIDForUUID_ objectForKey: [anObject UUID]]];
}

- (void) recordAddedEmbededObject: (COUUID *)aUUID toObject: (COUUID *)aTarget
{
    [embeddedObjectParentUUIDForUUID_ setObject:aTarget forKey: aUUID];
}

@end
