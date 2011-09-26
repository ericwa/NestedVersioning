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
    obj.childUndoNodes = [NSMutableArray arrayWithArray: childUndoNodes];
    obj.namedBranches = [NSMutableArray arrayWithArray: namedBranches];
    obj.currentBranchIndex = currentBranchIndex;
    obj.historyNodes = [NSMutableArray arrayWithArray: historyNodes];
   
    // Check types and set parent pointers of objects in namedBranches
    for (NamedBranch *branch in obj.namedBranches)
    {
        if (![branch isKindOfClass: [NamedBranch class]])
        {
            [NSException raise: NSInvalidArgumentException
                        format: @"%@ not a NamedBranch", branch];
        }
    }
    
    // Check types and set parent pointers of objects in historyNodes
    for (HistoryNode *node in obj.historyNodes)
    {
        if (![node isKindOfClass: [HistoryNode class]])
        {
            [NSException raise: NSInvalidArgumentException
                        format: @"%@ not a HistoryNode", node];
        }
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

// debug

- (NSString *) logWithIndent: (unsigned int)i
{
    NSMutableString *res = [NSMutableString string];
    [res appendFormat: @"%@{undonode=%p parent=%p children=(", [LogIndent indent: i], self, parentUndoNode];
    
    // print the children (connections in the undo node graph)
    
    for (NSUInteger j=0; j<[self.childUndoNodes count]; j++)        
    {
        [res appendFormat: @"%p", [self.childUndoNodes objectAtIndex: j]];
        if (j < [self.childUndoNodes count] - 1)
            [res appendFormat: @", "];
    }
    
    [res appendFormat: @")\n"];
    
    [res appendFormat: @"%@named branches:\n", [LogIndent indent: i]];

    for (NSUInteger j=0; j<[self.namedBranches count]; j++)        
    {
        if (j==currentBranchIndex) [res appendFormat: @">"];
        [res appendFormat: @"%@\n", [[self.namedBranches objectAtIndex: j] logWithIndent: i + 1]];
    }
    
    [res appendFormat: @"%@history node graph:\n", [LogIndent indent: i]];
    
    for (NSUInteger j=0; j<[self.historyNodes count]; j++)        
    {
        [res appendFormat: @"%@\n", [[self.historyNodes objectAtIndex: j] logWithIndent: i + 1]];
    }
    
    [res appendFormat: @"%@}", [LogIndent indent: i]];
    return res;        
}

@end
