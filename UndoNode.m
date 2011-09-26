#import "UndoNode.h"

@implementation UndoNode

@synthesize parentUndoNodeIndices;
@synthesize namedBranches;
@synthesize currentBranchIndex;
@synthesize historyNodes;

- (id)init
{
    self = [super init];
    if (self)
    {
    }    
    return self;
}

+ (UndoNode *) undoNodeWithParentUndoNodeIndices: (NSIndexSet *)parentUndoNodeIndices
                                   namedBranches: (NSArray *)namedBranches
                              currentBranchIndex: (NSUInteger)currentBranchIndex
                                    historyNodes: (NSArray*)historyNodes
{
    UndoNode *obj = [[self alloc] init];
    obj.parentUndoNodeIndices = [[[NSMutableIndexSet alloc] initWithIndexSet: parentUndoNodeIndices] autorelease];
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
    NSArray *newNamedBranches = [[self.namedBranches copyWithZone: zone] autorelease];
    NSArray *newHistoryNodes = [[self.historyNodes copyWithZone: zone] autorelease];    

    return [[[self class] undoNodeWithParentUndoNodeIndices: self.parentUndoNodeIndices
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
    [res appendFormat: @"%@{undonode=%p parents=%@\n", [LogIndent indent: i], self, [LogIndent logIndexSet:self.parentUndoNodeIndices]];
        
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

- (void) checkSanityWithOwner: (BaseObject*)owner
{
    for (NSUInteger index = [parentUndoNodeIndices firstIndex]; index != NSNotFound; index = [parentUndoNodeIndices indexGreaterThanIndex: index])
    {
        if (index >= [((VersionedObject*)owner).undoNodes count])
        {
            [NSException raise: NSInternalInconsistencyException
                        format: @"index in parentUndoNodeIndices out of bounds"];
        }
    }
    
    if (self.currentBranchIndex >= [namedBranches count])
    {
        [NSException raise: NSInternalInconsistencyException
                    format: @"currentBranchIndex out of bounds"];
    }
    
    for (NamedBranch *branch in namedBranches)
    {
        if (![branch isKindOfClass: [NamedBranch class]])
        {
            [NSException raise: NSInternalInconsistencyException
                        format: @"%@ not a NamedBranch", branch];
        }
        [branch checkSanityWithOwner: self];
    }
    
    for (HistoryNode *node in historyNodes)
    {
        if (![node isKindOfClass: [HistoryNode class]])
        {
            [NSException raise: NSInternalInconsistencyException
                        format: @"%@ not a HistoryNode", node];
        }
        [node checkSanityWithOwner: self];
    }
}

@end
