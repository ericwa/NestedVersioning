#import "COType.h"

@interface COType (String)

- (BOOL) supportsRepresentationAsString;
- (BOOL) isValidStringValue: (NSString *)aString;

- (NSString *) stringValueForValue: (id)aValue;
- (id) valueForStringValue: (NSString *)aString;

@end