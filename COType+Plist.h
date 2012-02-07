#import "COType.h"

/**
 * COItem uses this to import/export item values to/from plist
 */
@interface COType (Plist)

- (id) plistValueForValue: (id)aValue;
- (id) valueForPlistValue: (id)aPlist;

@end