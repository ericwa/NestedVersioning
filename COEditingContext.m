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
        [itemByUUID setObject: [self objectForUUID: uuid]->item_
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

- (void) setItemTree: (COItemTree *)aTree
{
    [self clearChangeTracking];
    
    ASSIGN(rootObjectUUID_, [aTree rootItemUUID]);
    
    for (COUUID *uuid in [aTree itemUUIDs])
    {
        [self createOrUpdateObjectForItem: [aTree itemForUUID: uuid]];
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
    }
    else
    {
        // Update existing
        
        [currentObject setItem: item];
    }

    return currentObject;
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
//    NSLog(@"Inserting object %@", [object UUID]);
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

#if 0
- (COItemTree *) itemTreeWithNameMapping: (NSDictionary *)aMapping;
{
	NSMutableDictionary *newItems = [NSMutableDictionary dictionary];
	
	for (COUUID *uuid in itemForUUID_)
	{
        COItem *oldItem = [itemForUUID_ objectForKey: uuid];
        COItem *newItem = [[oldItem mutableCopyWithNameMapping: aMapping] autorelease];
        [newItems setObject: newItem forKey: [newItem UUID]];
	}
	
    COUUID *newRoot = [aMapping objectForKey: rootItemUUID_];
    if (newRoot == nil)
    {
        newRoot = rootItemUUID_;
    }
    
	return [[[[self class] alloc] initWithItemForUUID: newItems rootItemUUID:newRoot] autorelease];
}
#endif
- (COObject *) insertItemTree: (COItemTree *)aTree
{
    // see if there are any name conflicts
    
    NSMutableSet *conflictingNames = [NSMutableSet setWithSet: [self allObjectUUIDs]];
    [conflictingNames intersectSet: [NSSet setWithArray: [aTree itemUUIDs]]];
    
    if ([conflictingNames count] > 0)
    {
        NSLog(@"names %@ need to be remapped", conflictingNames);
        
        NSMutableDictionary *mapping = [NSMutableDictionary dictionary];
        for (COUUID *name in conflictingNames)
        {
            [mapping setObject: [COUUID UUID]
                        forKey: name];
        }
        
        aTree = [aTree itemTreeWithNameMapping: mapping];
    }
    
    // now, there are no name conflicts.
    
    COObject *result = [self updateObject: [aTree rootItemUUID]
                             fromItemTree: aTree];

    for (COUUID *uuid in [aTree itemUUIDs])
    {
        [self recordInsertedObjectUUID: uuid];
    }
    
    return result;
}

- (void) removeObject: (COObject *)anObject
{
    NSParameterAssert([anObject editingContext] == self);
 
    COUUID *uuid = [anObject UUID];
    
    // If it has a parent, remove it from the parent
    COObject *parent = [anObject embeddedObjectParent];
    if (parent != nil)
    {
        [parent removeDescendentObject: anObject];
    }
    
    [anObject markAsRemovedFromContext];

    // Update change tracking
    if ([insertedObjects_ containsObject: uuid])
    {
        [insertedObjects_ removeObject: uuid];
    }
    else
    {
        [deletedObjects_ addObject: uuid];
    }
    
    // Release it from the objects dictionary
    [objectsByUUID_ removeObjectForKey: uuid];
}

@end
