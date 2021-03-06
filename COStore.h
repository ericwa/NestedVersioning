#import <Foundation/Foundation.h>

#import <EtoileFoundation/ETUUID.h>
#import "COPersistentRoot.h"
#import "COSQLiteStore.h"

@class COObjectGraphContext;

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

- (COPersistentRoot *) persistentRootWithUUID: (ETUUID *)aUUID;

/** @taskunit writing */

/**
 * Commits immediately.
 */
- (COPersistentRoot *) createPersistentRootWithInitialContents: (COObjectGraphContext *)contents
                                                      metadata: (NSDictionary *)metadata;

// does a cheap copy
- (COPersistentRoot *) createPersistentRootWithInitialRevision: (CORevisionID *)aRevision
                                                      metadata: (NSDictionary *)metadata;

/**
 * Deletes the requested persistent root immediately
 */
- (void) deletePersistentRootWithUUID: (ETUUID *)aUUID;

@end
