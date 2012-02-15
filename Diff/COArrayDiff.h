#import <Foundation/Foundation.h>
#import "COSequenceDiff.h"
#import "COType+Diff.h"

@interface COArrayDiff : COSequenceDiff <COValueDiff>

- (id) initWithFirstArray: (NSArray *)first
			  secondArray: (NSArray *)second
		 sourceIdentifier: (id)aSource;

- (void) applyTo: (NSMutableArray*)array;
- (NSArray *)arrayWithDiffAppliedTo: (NSArray *)array;

- (id) valueWithDiffAppliedToValue: (id)aValue;

@end


