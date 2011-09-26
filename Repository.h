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
 * create a new repository
 */
+ (Repository*) repositoryWithVersionedObject: (VersionedObject*)obj;

// access

- (VersionedObject *) rootObject;

// debug

- (void)checkSanity;

@end
