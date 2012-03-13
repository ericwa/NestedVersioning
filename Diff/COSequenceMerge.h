#import <Foundation/Foundation.h>

@protocol COEdit <NSObject>
- (NSRange) range;
@end


/**
 * Linear-time version of:
 *
 * [[arrayA arrayByAddingObjectsFromArray: arrayB] sortedArrayUsingSelector: cmpSel]]
 *
 * for when the arrays are already sorted.
 */
NSArray *COMergeSortedArraysUsingSelector(NSArray *sortredArrayA, NSArray *sortedArrayB, SEL cmpSel);

/**
 * @returns an NSSet of NSIndexSets, where each index set is one set of conflicting indices in the
 * provided array.
 *
 * objects in sortedOps should conform to COEdit
 *
 * linear time.
 */
NSSet *COFindConflicts(NSArray *sortedOps);