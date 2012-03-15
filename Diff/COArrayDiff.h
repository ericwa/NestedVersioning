#import <Foundation/Foundation.h>

@protocol CODiffArraysDelegate

- (id)insertionWithLocation: (NSUInteger)aLocation
			 insertedObject: (id)anObject
		   sourceIdentifier: (id)aSource;

- (id)deletionWithRange: (NSRange)aRange
	   sourceIdentifier: (id)aSource;

- (id)modificationWithRange: (NSRange)aRange
			 insertedObject: (id)anObject
		   sourceIdentifier: (id)aSource;

@end

NSArray *CODiffArrays(NSArray *arrayA, NSArray *arrayB, id<CODiffArraysDelegate>delegate, id sourceIdentifier);

void COApplyEditsToArray(NSMutableArray *array, NSArray *edits);

NSArray *COArrayByApplyingEditsToArray(NSArray *array, NSArray *edits);