#import "Name.h"

@implementation Name

+ (Name *)name
{
    static NSUInteger counter = 0;    
    Name *name = [[[Name alloc] init] autorelease];
    name->n = counter;
    counter++;
    
    return name;
}
- (BOOL) isEqual: (Name*)aName
{
    return [aName isKindOfClass: [Name class]] && 
        (aName->n == self->n);
}
- (id)copyWithZone:(NSZone *)zone
{
    return [self retain];
}

@end
