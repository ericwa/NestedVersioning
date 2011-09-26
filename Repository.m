#import "Repository.h"

@implementation Repository

@synthesize rootObject;

- (id)init
{
    self = [super init];
    if (self)
    {
    }
    
    return self;
}

+ (Repository*) repositoryWithEmbeddedObject: (EmbeddedObject*)emb
                    firstHistoryNodeMetadata: (NSDictionary *)historyNodeMetadata
{
    HistoryNode *firstHistoryNode = [HistoryNode historyNodeWithParentHistoryNodeIndices: [NSIndexSet indexSet]                                     
                                                                     historyNodeMetadata: historyNodeMetadata
                                                                     childEmbeddedObject: emb];
    
    NamedBranch *defaultBranch = [NamedBranch namedBranchWithName: @"Default Branch"                                                     
                                          currentHistoryNodeIndex: 0];
    
    UndoNode *firstUndoNode = [UndoNode undoNodeWithParentUndoNodeIndices: [NSIndexSet indexSet]
                                                            namedBranches: [NSArray arrayWithObject: defaultBranch]
                                                       currentBranchIndex: 0
                                                             historyNodes: [NSArray arrayWithObject: firstHistoryNode]];
    
    VersionedObject *versionedobject = [VersionedObject objectWithUndoNodes: [NSArray arrayWithObject: firstUndoNode]
                                            currentNodeIndex: 0];    
    Repository *obj = [[self alloc] init];
    obj.rootObject = versionedobject;
    return [obj autorelease];
}

// debug

- (void)checkSanity
{
    [rootObject checkSanityWithOwner: nil];
}

@end
