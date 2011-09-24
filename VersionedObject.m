#import <Foundation/Foundation.h>
#import "VersionedObject.h"

@implementation VersionedObject

@synthesize undoNodes;
@synthesize currentNodeIndex;

- (id) init
{
    self = [super init];
    if (self)
    {
    }    
    return self;
}

+ (VersionedObject *) objectWithUndoNodes: (NSArray*)undoNodes
                    currentNodeIndex: (NSUInteger)currentNodeIndex
{
    VersionedObject *obj = [[self alloc] init];
    obj.undoNodes = [NSMutableArray arrayWithArray: undoNodes];
    obj.currentNodeIndex = currentNodeIndex;
    
    // Check types and set parent pointers of objects in undoNodes
    for (UndoNode *node in obj.undoNodes)
    {
        if (![node isKindOfClass: [UndoNode class]])
        {
            [NSException raise: NSInvalidArgumentException
                        format: @"%@ not a UndoNode", node];
        }
        node.parent = obj;
    }
    
    return [obj autorelease];
}

- (id) copyWithZone:(NSZone *)zone;
{
    NSArray *newUndoNodes = [[undoNodes copyWithZone: zone] autorelease];
    return [[[self class] objectWithUndoNodes: newUndoNodes
                             currentNodeIndex: self.currentNodeIndex] retain];
}

+ (VersionedObject *) versionedObjectWrappingEmbeddedObject: (EmbeddedObject*)object
{
    return nil;
}

// manipulation

- (void)commitNewVersionOfEmbeddedObject: (BaseObject*)object
                      withCommitMetadata: (NSDictionary*)metadata
{
    /**
     * summary:
     *  - create a new undo node, branching off of the current one,
     *    containing a copy of the history graph
     *  - create a new hisory node in the copied undo node's history graph,
     *    branching off of the current history node
     *  - set the embedded object of the new history node to the given one,
     *    and set the commit metadata
     */
    
    UndoNode *oldUndoNode = [self currentUndoNode];
    
    UndoNode *newUndoNode = [oldUndoNode copy]; // deep-copies the contained history graph
    
    [oldUndoNode.childUndoNodes addObject: newUndoNode];
    newUndoNode.parentUndoNode = oldUndoNode;
    [newUndoNode.childUndoNodes removeAllObjects];
    
    HistoryNode *oldHistoryNodeInNewUndoNode = [newUndoNode currentHistoryNode];
    HistoryNode *newHistoryNode = [oldHistoryNodeInNewUndoNode copy]; // another deep copy
    [newHistoryNode setParentHistoryNode: oldHistoryNodeInNewUndoNode];
    [oldHistoryNodeInNewUndoNode.childHistoryNodes addObject: newHistoryNode];
    
    [newHistoryNode setChildEmbeddedObject: object];
    
    [newUndoNode release];
    [newHistoryNode release];
}

- (void)_navigateToUndoNodeAtIndex: (NSUInteger)index
{
    self.currentNodeIndex = index;
}

- (void)navigateToUndoNode: (UndoNode*)node
{
    NSUInteger i = 0;
    for (UndoNode *n in undoNodes)
    {
        if (n == node)
        {
            [self _navigateToUndoNodeAtIndex: i];
        }
        i++;
    }
    [NSException raise: NSInvalidArgumentException
                format: @"-[%@ %@]: Node not found",
                        NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
}

// access

- (UndoNode *) currentUndoNode
{
    return [undoNodes objectAtIndex: currentNodeIndex];
}
- (HistoryNode *) currentHistoryNode
{
    return [[self currentUndoNode] currentHistoryNode];
}
- (BaseObject *) currentEmbeddedObject
{
    return [self currentHistoryNode].childEmbeddedObject;
}

@end
