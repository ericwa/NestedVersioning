#import <Foundation/Foundation.h>
#import "COMergeResult.h"

/**
 * Superclass of COStringDiff and COArrayDiff, which implements merging.
 */
@interface COSequenceDiff : NSObject
{
	NSMutableArray *ops;
}

- (id) initWithOperations: (NSArray*)opers;
- (NSArray *)operations;

- (COMergeResult *)mergeWith: (COSequenceDiff *)other;

@end




@interface COSequenceEdit : NSObject
{
	NSRange range;
	id sourceIdentifier;
}
@property (nonatomic, assign, readonly) NSRange range;
@property (nonatomic, assign, readonly) id sourceIdentifier;

- (NSComparisonResult) compare: (id)otherObject;

@end





@interface COSequenceConflictingEditGroup : NSObject
{
	NSArray *conflictingEdits;
}
@property (nonatomic, assign, readonly) NSArray *conflictingEdits;

@end





@interface COSequenceInsertion : COSequenceEdit 
{
	id insertedObject;
}

@property (nonatomic, retain, readonly)  id insertedObject;

+ (COSequenceInsertion*)insertionWithLocation: (NSUInteger)aLocation
							   insertedObject: (id)anObject
							 sourceIdentifier: (id)aSource;

@end



@interface COSequenceDeletion : COSequenceEdit

+ (COSequenceDeletion*)deletionWithRange: (NSRange)aRange
						sourceIdentifier: (id)aSource;

@end




@interface COSequenceModification : COSequenceEdit
{
	id insertedObject;
}

@property (nonatomic, retain, readonly)  id insertedObject;

+ (COSequenceModification*)modificationWithRange: (NSRange)aRange
								  insertedObject: (id)anObject
								sourceIdentifier: (id)aSource;

@end