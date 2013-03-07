#import "EWFormatBooleanValueTransformer.h"

@implementation EWFormatBooleanValueTransformer

+ (Class)transformedValueClass
{
    return [NSString class];
}
+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)transformedValue:(id)value
{
    if ([value boolValue])
    {
        return @"Yes";
    }
    return @"No";
}
- (id)reverseTransformedValue:(id)value
{
    return [NSNumber numberWithBool: [value isEqual: @"Yes"]];
}

@end
