#import "COType.h"
#import "COValueDiff.h"

@interface COType (Diff)

- (COValueDiff *) diffValue: (id)valueA withValue: (id)valueB;

@end
