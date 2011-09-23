#import "UndoNode.h"

@implementation UndoNode

@synthesize parentUndoNode;
@synthesize childUndoNodes;
@synthesize namedBranches;
@synthesize currentBranchIndex;
@synthesize  historyNodes;

- (id)init
{
    self = [super init];
    if (self)
    {
    }    
    return self;
}

+ (UndoNode *) undoNodeWithParentUndoNode: (UndoNode *)parentUndoNode
                           childUndoNodes: (NSArray *)childUndoNodes
                            namedBranches: (NSArray *)namedBranches
                       currentBranchIndex: (NSUInteger)currentBranchIndex
                             historyNodes: (NSArray*)historyNodes
{
    UndoNode *obj = [[self alloc] init];
    obj.parentUndoNode = parentUndoNode;
    obj.childUndoNodes = childUndoNodes;
    obj.namedBranches = namedBranches;
    obj.currentBranchIndex = currentBranchIndex;
    obj.historyNodes = historyNodes;
    
    // Check types and set parent pointers of objects in namedBranches
    for (NamedBranch *branch in obj.namedBranches)
    {
        if (![branch isKindOfClass: [NamedBranch class]])
        {
            [NSException raise: NSInvalidArgumentException
                        format: @"%@ not a NamedBranch", branch];
        }
        branch.parent = obj;
    }
    
    // Check types and set parent pointers of objects in historyNodes
    for (HistoryNode *node in obj.historyNodes)
    {
        if (![node isKindOfClass: [HistoryNode class]])
        {
            [NSException raise: NSInvalidArgumentException
                        format: @"%@ not a HistoryNode", node];
        }
        node.parent = obj;
    }
    
    return [obj autorelease];
}

- (id) copyWithZone:(NSZone *)zone;
{
    NSArray *newChildUndoNodes = [[self.childUndoNodes copyWithZone: zone] autorelease];
    NSArray *newNamedBranches = [[self.namedBranches copyWithZone: zone] autorelease];
    NSArray *newHistoryNodes = [[self.historyNodes copyWithZone: zone] autorelease];    

    return [[[self class] undoNodeWithParentUndoNode: self.parentUndoNode
                                      childUndoNodes: newChildUndoNodes
                                       namedBranches: newNamedBranches
                                  currentBranchIndex: self.currentBranchIndex
                                        historyNodes: newHistoryNodes] retain];
}

// access

- (NamedBranch *) currentBranch
{
    return [namedBranches objectAtIndex: currentBranchIndex];
}
- (HistoryNode *) currentHistoryNode
{
    return [historyNodes objectAtIndex: [self currentBranch].currentHistoryNodeIndex];
}

@end
