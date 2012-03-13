#import <Foundation/Foundation.h>

NSArray *CODiffArrays(NSArray *arrayA, NSArray *arrayB, id sourceIdentifier);

void COApplyEditsToArray(NSMutableArray *array, NSArray *edits);

NSArray *COArrayByApplyingEditsToArray(NSArray *array, NSArray *edits);