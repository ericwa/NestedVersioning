#import <Foundation/Foundation.h>
#import "Common.h"

@class NamedBranch;
@class HistoryNode;

/**
 * A node making up the undo tree for an undo track
 */
@interface UndoNode : BaseObject
{
    // parent (inherited from BaseObject) is a VersionedObject
    
    // The undo graph
    
    UndoNode *parentUndoNode; //weak
    NSArray *childUndoNodes; //strong
    
    // The versioned object, underneath the outer undo layer
    
    NSArray *namedBranches; // strong
    NSUInteger currentBranchIndex;
    
    /**
     * see comment in VersionedObject.h
     */
    NSArray *historyNodes; // strong
    
    // note: the index of the current history node is stored in the current branch
}

@property (readwrite, nonatomic, assign) UndoNode *parentUndoNode;
@property (readwrite, nonatomic, retain) NSArray *childUndoNodes;
@property (readwrite, nonatomic, retain) NSArray *namedBranches;
@property (readwrite, nonatomic, assign) NSUInteger currentBranchIndex;
@property (readwrite, nonatomic, retain) NSArray *historyNodes;

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
