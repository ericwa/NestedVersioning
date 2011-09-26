#import <Foundation/Foundation.h>

/**
 * No implementation.
 *
 * NSCopying is implemented to perform a deep copy; i.e., the entire subtree is copied.
 */
@interface BaseObject : NSObject <NSCopying>
{
}

- (NSString *) logWithIndent: (unsigned int)i;

- (void) checkSanityWithOwner: (BaseObject*)owner;

@end
