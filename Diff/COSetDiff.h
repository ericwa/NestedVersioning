#import <Foundation/Foundation.h>
#import "COType+Diff.h"

/**
 * Set diffs can always be merged without conflict
 */
@interface COSetDiff : NSObject <COValueDiff>
{
	NSDictionary *insertionsForSourceIdentifier;
	NSDictionary *deletionsForSourceIdentifier;
}

// Creating

- (id) initWithFirstSet: (NSSet *)first
              secondSet: (NSSet *)second
	   sourceIdentifier: (id)aSource;

// Examining

- (NSSet *)insertionSet;
- (NSSet *)deletionSet;

- (NSSet *)insertionSetForSourceIdentifier: (id)anIdentifier;
- (NSSet *)deletionSetForSourceIdentifier: (id)anIdentifier;

// Applying

- (void) applyTo: (NSMutableSet*)array;
- (NSSet *)setWithDiffAppliedTo: (NSSet *)array;
- (id) valueWithDiffAppliedToValue: (id)aValue;

// Merging with another COSetDiff

- (COSetDiff *)setDiffByMergingWithDiff: (COSetDiff *)other;

@end
