#import <Foundation/Foundation.h>

@protocol COEdit <NSObject>
- (NSRange) range;
@end

/**
 * @returns an NSSet of NSIndexSets, where each index set is one set of conflicting indices in the
 * provided array.
 *
 * objects in sortedOps should conform to COEdit
 *
 * linear time.
 */
NSSet *COFindConflicts(NSArray *sortedOps);

/**
 */
NSArray *COEditsByUniquingNonconflictingDuplicates(NSArray *edits);