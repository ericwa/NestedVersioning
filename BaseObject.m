#import "BaseObject.h"

@implementation BaseObject

- (id)copyWithZone:(NSZone *)zone
{
    [self doesNotRecognizeSelector: _cmd];
    return nil;
}

- (NSString *) description
{
    return [self logWithIndent: 0];
}

// debug

- (NSString *) logWithIndent: (unsigned int)i
{
    [self doesNotRecognizeSelector: _cmd];
    return nil;
}

- (void) checkSanityWithOwner: (BaseObject*)owner
{
    [self doesNotRecognizeSelector: _cmd];
}

@end
