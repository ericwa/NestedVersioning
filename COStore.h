#import <Foundation/Foundation.h>

#import "COUUID.h"
#import "COPersistentRoot.h"
#import "COSQLiteStore.h"

@class COEditingContext;

/**
 * High-level store API which provides access to COPersistentRootEditQueue objects,
 * which are managed/mutable models for the persistent roots
 */
@interface COStore : NSObject
{
    COSQLiteStore *store_;
    
    // FIXME: Should be weak so if createPersistentRoot
    // is called and the result is not used, it'll be dealloced?
    NSMutableDictionary *rootForUUID_;
}

- (id)initWithURL: (NSURL*)aURL;
- (NSURL*)URL;

- (NSSet *) persistentRoots;
- (NSSet *) GCRoots;

- (COPersistentRoot *) persistentRootWithUUID: (COUUID *)aUUID;

/** @taskunit writing */

/**
 * Commits immediately.
 */
- (COPersistentRoot *) createPersistentRootWithInitialContents: (COEditingContext *)contents
                                                      metadata: (NSDictionary *)metadata
                                                      isGCRoot: (BOOL)isGCRoot;

// does a cheap copy
- (COPersistentRoot *) createPersistentRootWithInitialRevision: (CORevisionID *)aRevision
                                                      metadata: (NSDictionary *)metadata
                                                      isGCRoot: (BOOL)isGCRoot;

/**
 * Deletes the requested persistent root immediately
 */
- (void) deletePersistentRootWithUUID: (COUUID *)aUUID;

@end
