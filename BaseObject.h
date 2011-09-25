#import <Foundation/Foundation.h>

/**
 * No implementation.
 */
@interface BaseObject : NSObject <NSCopying>
{
}

- (NSString *) logWithIndent: (unsigned int)i;

@end
