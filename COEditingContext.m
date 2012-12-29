#import "COEditingContext.h"
#import "COEditingContextPrivate.h"
#import "COItemTree.h"
#import "COMacros.h"


@implementation COEditingContext

- (NSSet *)allUUIDs
{
    return [NSSet setWithArray: [objectsByUUID_ allKeys]];
}

/* @taskunit Creation */



- (id) initWithObjectTree: (COItemTree *)aTree
{
    NSParameterAssert(aTree != nil);
    NSParameterAssert([aTree itemForUUID: [aTree root]] != nil);
    
    SUPERINIT;
    ASSIGN(rootUUID_, [aTree root]);
    objectsByUUID_ = [[NSMutableDictionary alloc] init];
    insertedObjects_ = [[NSMutableSet alloc] init];
    deletedObjects_ = [[NSMutableSet alloc] init];
    modifiedObjects_ = [[NSMutableSet alloc] init];
    
    [self updateObject: rootUUID_ fromObjectTree: aTree setParent: nil];
    
    return self;
}

- (id) init
{
    COItem *item = [COItem itemWithTypesForAttributes: [NSDictionary dictionary]
                                  valuesForAttributes: [NSDictionary dictionary]];

    COItemTree *tree = [[[COItemTree alloc] initWithItemForUUID: [NSDictionary dictionaryWithObject: item forKey: [item UUID]]
                                                              root: [item UUID]] autorelease];
    
    return [self initWithObjectTree: tree];
}

- (void) dealloc
{
    [objectsByUUID_ release];
    [rootUUID_ release];
    [insertedObjects_ release];
    [deletedObjects_ release];
    [modifiedObjects_ release];
    [super dealloc];
}

- (COObject *) rootObject
{
    return [self objectForUUID: rootUUID_];
}

- (COObject *)objectForUUID: (COUUID *)uuid
{
    return [objectsByUUID_ objectForKey: uuid];
}

- (COItemTree *)objectTree
{
    NSMutableDictionary *itemByUUID = [NSMutableDictionary dictionary];
    for (COUUID *uuid in objectsByUUID_)
    {
        [itemByUUID setObject: [[self objectForUUID: uuid] item]
                       forKey: uuid];
    }
    return [[[COItemTree alloc] initWithItemForUUID: itemByUUID
                                                 root: rootUUID_] autorelease];
}

+ (COEditingContext *)editingContextWithObjectTree: (COItemTree *)aTree
{
    return [[[self alloc] initWithObjectTree: aTree] autorelease];
}

- (id) copyWithZone: (NSZone *)aZone
{
    return [[[self class] alloc] initWithObjectTree: [self objectTree]];
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
	return [rootUUID_ hash] ^ 13803254444065375360ULL;
}

- (void) setObjectTree: (COItemTree *)aTree
{
    [self clearChangeTracking];
    
    NSSet *initialUUIDs = [[self rootObject] allUUIDs];
    
    ASSIGN(rootUUID_, [aTree root]);
    
    [self updateObject: rootUUID_
        fromObjectTree: aTree
             setParent: nil];
    
    // The update is now complete. Remove orphans
    
    NSMutableSet *orphanedUUIDs = [NSMutableSet setWithSet: [[self rootObject] allUUIDs]];
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
    NSParameterAssert(![aUUID isEqual: rootUUID_]);

    COObject *object = [objectsByUUID_ objectForKey: aUUID];
    if (object == nil)
    {
        return; // nothing to do since the object is not in memory
    }
    
    NSAssert(![[[object parent] directDescendentSubtreeUUIDs] containsObject: [object UUID]],
             @"%@ should have already been detached from its parent", aUUID);
    
    for (COUUID *uuid in [object allDescendentSubtreeUUIDs])
    {
        COObject *objectToRemove = [self objectForUUID: uuid];
        [objectToRemove markAsRemovedFromContext];
        
        [objectsByUUID_ removeObjectForKey: uuid]; // should free object unless there are external references
    }
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
             fromObjectTree: (COItemTree *)aTree
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

@end
