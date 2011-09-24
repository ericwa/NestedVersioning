#import <Foundation/Foundation.h>

/**
 * Object with weak reference to its "parent".
 * No implementation.
 */
@interface BaseObject : NSObject <NSCopying>
{
    BaseObject *parent; // weak
}

@property (readwrite, nonatomic, assign) BaseObject *parent;

- (NSString *) logWithIndent: (unsigned int)i;

@end
