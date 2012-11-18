#import <Foundation/Foundation.h>

#import "COUUID.h"
#import "COPersistentRootEditQueue.h"
#import "COPersistentRootState.h"
#import "COStore.h"

/**
 * High-level store API which provides access to COPersistentRootEditQueue objects,
 * which are managed/mutable models for the persistent roots
 */
@interface COStoreEditQueue : NSObject
{
    COStore *store_;
    
    // FIXME: Should be weak so if createPersistentRoot
    // is called and the result is not used, it'll be dealloced?
    NSMutableDictionary *rootForUUID_;
}

- (id)initWithURL: (NSURL*)aURL;
- (NSURL*)URL;

- (NSArray *) allPersistentRootUUIDs;

- (COPersistentRootEditQueue *) persistentRootWithUUID: (COUUID *)aUUID;

/** @taskunit writing */

/**
 * Creates a persistent root in memory, which will be committed once you call -commit on it
 */
- (COPersistentRootEditQueue *) createPersistentRoot;

- copy;

/**
 * Deletes the requested persistent root immediately
 */
- (void) deletePersistentRootWithUUID: (COUUID *)aUUID;

@end
