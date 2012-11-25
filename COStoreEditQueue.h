#import <Foundation/Foundation.h>

#import "COUUID.h"
#import "COPersistentRootEditQueue.h"
#import "COSQLiteStore.h"

@class COObjectTree;

/**
 * High-level store API which provides access to COPersistentRootEditQueue objects,
 * which are managed/mutable models for the persistent roots
 */
@interface COStoreEditQueue : NSObject
{
    COSQLiteStore *store_;
    
    // FIXME: Should be weak so if createPersistentRoot
    // is called and the result is not used, it'll be dealloced?
    NSMutableDictionary *rootForUUID_;
}

- (id)initWithURL: (NSURL*)aURL;
- (NSURL*)URL;

- (NSArray *) allPersistentRootUUIDs;

- (COPersistentRootEditQueue *) persistentRootWithUUID: (COUUID *)aUUID;

/** @taskunit writing */

// these 2 commit immediately
- (COPersistentRootEditQueue *) createPersistentRootWithInitialContents: (COObjectTree *)contents
                                                               metadata: (NSDictionary *)metadata;

// does a cheap copy
- (COPersistentRootEditQueue *) createPersistentRootWithInitialRevision: (CORevisionID *)aRevision
                                                               metadata: (NSDictionary *)metadata;

/**
 * Deletes the requested persistent root immediately
 */
- (void) deletePersistentRootWithUUID: (COUUID *)aUUID;

@end
