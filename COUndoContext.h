#import <Foundation/Foundation.h>

@class COStore;
@class COUUID;

/**
 * A database view which aggregates the undo logs of a set
 * of persistent roots.
 *
 * Use this class when the user is editing a set of persistent
 * roots which conceptually form one document. Note that this is a bit dangerous,
 * since the undo will make them feel like one document, but the histories will
 * still be separate.
 */
@interface COUndoContext : NSObject
{
    COStore *store_;
    NSArray *persistentRootUUIDs_;
}

- (id) initWithPersistentRootUUIDs: (NSArray *)persistentRootUUIDs;

- (BOOL) canUndo;
- (BOOL) canRedo;

- (COUUID *) undoPersistentRootUUID;
- (COUUID *) redoPersistentRootUUID;

- (NSString *) undoMenuItemTitle;
- (NSString *) redoMenuItemTitle;

- (BOOL) undo;
- (BOOL) redo;

@end
