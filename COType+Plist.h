#import "COType.h"

@interface COType (Plist)

- (id) plistValueForValue: (id)aValue;
- (id) valueForPlistValue: (id)aPlist;

@end