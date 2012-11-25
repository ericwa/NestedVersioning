#import "COEditingContext.h"
#import "COEditingContextPrivate.h"
#import "COSubtreeCopy.h"
#import "COObjectTree.h"
#import "COMacros.h"


@implementation COEditingContext

- (NSSet *)allUUIDs
{
    return [NSSet setWithArray: [objectsByUUID_ allKeys]];
}

/* @taskunit Creation */

- (COObject *) createObjectWithDescendents: (COUUID *)aUUID
                            fromObjectTree: (COObjectTree *)aTree
                                    parent: (COObject *)parent
{
    COItem *item = [aTree itemForUUID: aUUID];
    COObject *result = [[[COObject alloc] initWithItem: item
                                         parentContext: self
                                                parent: parent] autorelease];
    
    for (COUUID *descendent in [item embeddedItemUUIDs])
    {
        [self createObjectWithDescendents: descendent fromObjectTree: aTree parent: result];
    }
    
    [objectsByUUID_ setObject: result forKey: aUUID];
    return result;
}


- (id) initWithObjectTree: (COObjectTree *)aTree
{
    NSParameterAssert(aTree != nil);
    
    SUPERINIT;
    ASSIGN(rootUUID_, [aTree root]);
    objectsByUUID_ = [[NSMutableDictionary alloc] init];
    dirtyObjects_ = [[NSMutableSet alloc] init];

    [self createObjectWithDescendents: rootUUID_ fromObjectTree: aTree parent: nil];
    
    return self;
}

- (void) dealloc
{
    [objectsByUUID_ release];
    [rootUUID_ release];
    [dirtyObjects_ release];
    [super dealloc];
}

- (COObjectTree *)objectTree
{
    NSMutableDictionary *itemByUUID = [NSMutableDictionary dictionary];
    for (COUUID *uuid in objectsByUUID_)
    {
        [itemByUUID setObject: [[self objectForUUID: uuid] item]
                       forKey: uuid];
    }
    return [[[COObjectTree alloc] initWithItemForUUID: itemByUUID
                                                 root: rootUUID_] autorelease];
}

+ (COEditingContext *)editingContextWithObjectTree: (COObjectTree *)aTree
{
    return [[[self alloc] initWithObjectTree: aTree] autorelease];
}

- (id) copyWithZone: (NSZone *)aZone
{
    return [[[self class] editingContextWithObjectTree: [self objectTree]] retain];
}

@end



@implementation COEditingContext (Private)

- (void) recordDirtyObject: (COObject *)anObject
{
    [dirtyObjects_ addObject: [anObject UUID]];
}

- (void) recordDirtyObjectUUID: (COUUID *)aUUID
{
    [dirtyObjects_ addObject: aUUID];
}

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

@end
