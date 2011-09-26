#import <Foundation/Foundation.h>

/**
 * Immutable, general-purpose name/label. Currently just an integer.
 */
@interface Name : NSObject <NSCopying>
{
    NSUInteger n;
}

+ (Name *)name;
- (BOOL) isEqual: (Name*)aName;
- (id)copyWithZone:(NSZone *)zone;

@end
