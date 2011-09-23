#import <Foundation/Foundation.h>
#import "Common.h"

@class VersionedObject;

/**
 * Container which would be stored on disk, holding a single (support many?)
 * versioned object.
 */
@interface Repository : NSObject
{
    VersionedObject *rootObject; // strong
}

@property (readwrite, nonatomic, retain) VersionedObject *rootObject;

/**
 * initialize a new repository by creating a versioned object wrapper
 * around the give embedded object.
 * historyNodeMetadata is the metadata attached to the initial commit
 * which should be populated with date, author, log message, etc.
 */
+ (Repository*) repositoryWithEmbeddedObject: (EmbeddedObject*)emb
                    firstHistoryNodeMetadata: (NSDictionary *)historyNodeMetadata;

// access

- (VersionedObject *) rootObject;

@end
