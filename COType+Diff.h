#import "COType.h"

@protocol COValueDiff <NSObject>

- (id) valueWithDiffAppliedToValue: (id)aValue;

@end

@interface COType (Diff)

- (id <COValueDiff>) diffValue: (id)valueA withValue: (id)valueB;

@end
