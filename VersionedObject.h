#import <Foundation/Foundation.h>
#import "Common.h"

@class EmbeddedObject;
@class UndoNode;
@class HistoryNode;

/**
 * VersionedObject - outer wrapper containing
 * the built-in undo track for every versioned object, which supports
 * undo/redo on all changes, including revision control operations,
 * done to the object.
 * implemented as branching undo but probably only linear
 * needs to be exposed to the ui.
 *
 * A versioned object won't usually be mutated,
 * but the top level one in a repository isn't itself versioned, so
 * it will be mutated when new undo nodes are added.
 *
 * Will be inside an EmbeddedObject or a Repository
 */
@interface VersionedObject : BaseObject
{    
    /**
     * Array of nodes making up the undo graph.
     * The order is insignificant except that
     * currentNodeIndex is the index of the current node.
     * This is just a quick-and-dirty way to let us refer to the current
     * node in a way that makes it easy to make a deep copy of the graph.
     * (if we just held a pointer to the current node, to copy the graph
     *  and get the pointer to the corresponding current node in the copy,
     *  we'd have to traverse the graph, build a list of objects to copy,
     *  build a mapping from old to new objects, etc, etc!)
     */
    NSMutableArray *undoNodes; // strong - should do a deep copy
    
    NSUInteger currentNodeIndex;
}

@property (readwrite, nonatomic, retain) NSMutableArray *undoNodes;
@property (readwrite, nonatomic, assign) NSUInteger currentNodeIndex;

- (id) copyWithZone:(NSZone *)zone;

// primitive constructor

+ (VersionedObject *) objectWithUndoNodes: (NSArray*)undoNodes
                    currentNodeIndex: (NSUInteger)currentNodeIndex;


// convenience constructor

/**
 * makes an embedded object versioned.
 */
+ (VersionedObject *) versionedObjectWrappingEmbeddedObject: (EmbeddedObject *)object;

// manipulation

- (VersionedObject *) versionedObjectNavigatedToUndoNodeAtIndex: (NSUInteger)index;

/**
 * Returns a copy of the receiver with a new commit added.
 * Side-effect free.
 */
- (VersionedObject *) versionedObjectWithNewVersionOfEmbeddedObject: (BaseObject*)object
                                                 withCommitMetadata: (NSDictionary*)metadata;

// access

- (UndoNode *) currentUndoNode;
- (HistoryNode *) currentHistoryNode;
- (EmbeddedObject *) currentEmbeddedObject;

@end
