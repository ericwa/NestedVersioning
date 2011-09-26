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
    
    /**
     * the indices in this index set refer to indices in the
     * undo nodes array in the VersionedObject which owns this undo node
     */
    NSMutableIndexSet *parentUndoNodeIndices;
    
    // The versioned object, underneath the outer undo layer
    
    NSMutableArray *namedBranches; // strong
    NSUInteger currentBranchIndex;
    
    /**
     * see comment in VersionedObject.h
     */
    NSMutableArray *historyNodes; // strong
    
    // note: the index of the current history node is stored in the current branch
}

@property (readwrite, nonatomic, retain) NSMutableIndexSet *parentUndoNodeIndices;
@property (readwrite, nonatomic, retain) NSMutableArray *namedBranches;
@property (readwrite, nonatomic, assign) NSUInteger currentBranchIndex;
@property (readwrite, nonatomic, retain) NSMutableArray *historyNodes;

- (id) copyWithZone:(NSZone *)zone;

+ (UndoNode *) undoNodeWithParentUndoNodeIndices: (NSIndexSet *)parentUndoNodeIndices
                                   namedBranches: (NSArray *)namedBranches
                              currentBranchIndex: (NSUInteger)currentBranchIndex
                                    historyNodes: (NSArray*)historyNodes;

// access

- (NamedBranch *) currentBranch;
- (HistoryNode *) currentHistoryNode;

@end
