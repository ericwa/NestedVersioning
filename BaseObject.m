#import "BaseObject.h"

@implementation BaseObject

@synthesize parent;

- (id)copyWithZone:(NSZone *)zone
{
    [self doesNotRecognizeSelector: _cmd];
    return nil;
}

@end
