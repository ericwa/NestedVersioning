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
    
    // NOTE: this code completely violates encapsulation, and setting up the
    // graph relationships is quite messy and error-prone. It's probably a 
    // good idea to refactor this logic.
    
    UndoNode *oldUndoNode = [self currentUndoNode];
    
    UndoNode *newUndoNode = [oldUndoNode copy]; // deep-copies the contained history graph
    
    [newUndoNode setParentUndoNodeIndices: [NSIndexSet indexSetWithIndex: currentNodeIndex]];
    
    [self.undoNodes addObject: newUndoNode];
    [newUndoNode release];
    self.currentNodeIndex = [self.undoNodes count] - 1; // index of new node
    
    
    HistoryNode *oldHistoryNodeInNewUndoNode = [newUndoNode currentHistoryNode];
    HistoryNode *newHistoryNode = [oldHistoryNodeInNewUndoNode copy]; // another deep copy
    [newHistoryNode setParentHistoryNodeIndices: [NSIndexSet indexSetWithIndex: 
                                                  [newUndoNode currentBranch].currentHistoryNodeIndex]];
    [newUndoNode.historyNodes addObject: newHistoryNode];
    [newHistoryNode release];
    [newUndoNode currentBranch].currentHistoryNodeIndex = [newUndoNode.historyNodes count] - 1;
    
    [newHistoryNode setChildEmbeddedObject: object];
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

// debug

- (NSString *) logWithIndent: (unsigned int)i
{
    NSMutableString *res = [NSMutableString string];
    [res appendFormat: @"%@{versioned addr=%p\n", [LogIndent indent: i], self];
    for (NSUInteger j=0; j<[self.undoNodes count]; j++)        
    {
        if (j==currentNodeIndex) [res appendFormat: @">"];
        [res appendFormat: @"%@\n", [[self.undoNodes objectAtIndex: j] logWithIndent: i + 1]];
    }
    [res appendFormat: @"%@}", [LogIndent indent: i]];
    return res;        
}

- (void) checkSanityWithOwner: (BaseObject*)owner
{
    if ([undoNodes count] == 0)
    {
        [NSException raise: NSInternalInconsistencyException
                    format: @"VersionedObject must have at least one undo node"];
    }
    if (self.currentNodeIndex >= [undoNodes count])
    {
        [NSException raise: NSInternalInconsistencyException
                    format: @"currentNodeIndex out of bounds"];
    }
    for (UndoNode *node in undoNodes)
    {
        if (![node isKindOfClass: [UndoNode class]])
        {
            [NSException raise: NSInternalInconsistencyException
                        format: @"%@ not a UndoNode", node];
        }
        [node checkSanityWithOwner: self];
    }
}

@end
