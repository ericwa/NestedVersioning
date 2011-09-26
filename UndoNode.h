#import <Foundation/Foundation.h>
#import "Common.h"

@class NamedBranch;
@class HistoryNode;

/**
 * A node making up the undo tree for an undo track
 *
 * Will be in a VersionedObject
 */
@interface UndoNode : BaseObject
{    
    // The undo graph
    
    UndoNode *parentUndoNode; //weak
    NSMutableArray *childUndoNodes; //strong
    
    // The versioned object, underneath the outer undo layer
    
    NSMutableArray *namedBranches; // strong
    NSUInteger currentBranchIndex;
    
    /**
     * see comment in VersionedObject.h
     */
    NSMutableArray *historyNodes; // strong
    
    // note: the index of the current history node is stored in the current branch
}

@property (readwrite, nonatomic, assign) UndoNode *parentUndoNode;
@property (readwrite, nonatomic, retain) NSMutableArray *childUndoNodes;
@property (readwrite, nonatomic, retain) NSMutableArray *namedBranches;
@property (readwrite, nonatomic, assign) NSUInteger currentBranchIndex;
@property (readwrite, nonatomic, retain) NSMutableArray *historyNodes;

- (id) copyWithZone:(NSZone *)zone;

+ (UndoNode *) undoNodeWithParentUndoNode: (UndoNode *)parentUndoNode
                           childUndoNodes: (NSArray *)childUndoNodes
                            namedBranches: (NSArray *)namedBranches
                       currentBranchIndex: (NSUInteger)currentBranchIndex
                             historyNodes: (NSArray*)historyNodes;

// access

- (NamedBranch *) currentBranch;
- (HistoryNode *) currentHistoryNode;

@end
