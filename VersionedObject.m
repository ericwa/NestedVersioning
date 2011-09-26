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
    NSArray *newUndoNodes = [[[NSArray alloc] initWithArray: undoNodes copyItems: YES] autorelease];
    return [[[self class] objectWithUndoNodes: newUndoNodes
                             currentNodeIndex: self.currentNodeIndex] retain];
}

+ (VersionedObject *) versionedObjectWrappingEmbeddedObject: (EmbeddedObject*)object
{
    HistoryNode *firstHistoryNode = [HistoryNode historyNodeWithParentHistoryNodeIndices: [NSIndexSet indexSet]                                     
                                                                     historyNodeMetadata: [NSDictionary dictionary]
                                                                     childEmbeddedObject: object];
    
    NamedBranch *defaultBranch = [NamedBranch namedBranchWithName: @"Default Branch"                                                     
                                          currentHistoryNodeIndex: 0];
    
    UndoNode *firstUndoNode = [UndoNode undoNodeWithParentUndoNodeIndices: [NSIndexSet indexSet]
                                                            namedBranches: [NSArray arrayWithObject: defaultBranch]
                                                       currentBranchIndex: 0
                                                             historyNodes: [NSArray arrayWithObject: firstHistoryNode]];
    
    VersionedObject *versionedobject = [VersionedObject objectWithUndoNodes: [NSArray arrayWithObject: firstUndoNode]
                                                           currentNodeIndex: 0];    
    return versionedobject;
}

// manipulation by returning modified copies (side-effect free)

- (VersionedObject *) versionedObjectNavigatedToUndoNodeAtIndex: (NSUInteger)index
{
    VersionedObject *copy = [[self copy] autorelease];
    copy.currentNodeIndex = index;
    return copy;
}

- (VersionedObject *) versionedObjectWithNewVersionOfEmbeddedObject: (BaseObject*)object
                                                 withCommitMetadata: (NSDictionary*)metadata
{
    VersionedObject *copy = [[self copy] autorelease];
    
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
    
    UndoNode *oldUndoNode = [copy currentUndoNode];
    
    UndoNode *newUndoNode = [oldUndoNode copy]; // deep-copies the contained history graph
    
    [newUndoNode setParentUndoNodeIndices: [NSIndexSet indexSetWithIndex: currentNodeIndex]];
    
    [copy.undoNodes addObject: newUndoNode];
    [newUndoNode release];
    copy.currentNodeIndex = [copy.undoNodes count] - 1; // index of new node
    
    
    HistoryNode *oldHistoryNodeInNewUndoNode = [newUndoNode currentHistoryNode];
    HistoryNode *newHistoryNode = [oldHistoryNodeInNewUndoNode copy]; // another deep copy
    [newHistoryNode setParentHistoryNodeIndices: [NSIndexSet indexSetWithIndex: 
                                                  [newUndoNode currentBranch].currentHistoryNodeIndex]];
    [newUndoNode.historyNodes addObject: newHistoryNode];
    [newHistoryNode release];
    [newUndoNode currentBranch].currentHistoryNodeIndex = [newUndoNode.historyNodes count] - 1;
    
    [newHistoryNode setChildEmbeddedObject: object];    
    
    return copy;
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
