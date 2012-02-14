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



/**
 * Abstract superclass for a sequence edit. Has a range (in the source sequence)
 * to which it applies.
 */
@interface COSequenceEdit : NSObject
{
	NSRange range;
}
@property (nonatomic, readonly) NSRange range;
- (NSComparisonResult) compare: (id)otherObject;
@end


@interface COPrimitiveSequenceEdit : COSequenceEdit
{
	id sourceIdentifier;
}
@property (nonatomic, readonly) id sourceIdentifier;
@end

@interface COOverlappingSequenceEditGroup : COSequenceEdit
{
	NSArray *overlappingEdits;
	/**
	 * determined at creation time by checking if all of the overlappingEdits
	 * are equal or not.
	 */
	BOOL conflicting;
}
/**
 * Array of COPrimitiveSequenceEdit
 */
@property (nonatomic, readonly) NSArray *overlappingEdits;
@property (nonatomic, readonly) BOOL conflicting;
/**
 * The receiver's range is computed by taking the union of the edits
 */
+ (COOverlappingSequenceEditGroup *)overlappingEditGroupWithEdits: (NSArray *)edits;
@end


@interface COSequenceInsertion : COPrimitiveSequenceEdit 
{
	id insertedObject;
}
@property (nonatomic, readonly)  id insertedObject;
+ (COSequenceInsertion*)insertionWithLocation: (NSUInteger)aLocation
							   insertedObject: (id)anObject
							 sourceIdentifier: (id)aSource;
@end



@interface COSequenceDeletion : COPrimitiveSequenceEdit
+ (COSequenceDeletion*)deletionWithRange: (NSRange)aRange
						sourceIdentifier: (id)aSource;
@end




@interface COSequenceModification : COPrimitiveSequenceEdit
{
	id insertedObject;
}
@property (nonatomic, retain, readonly)  id insertedObject;
+ (COSequenceModification*)modificationWithRange: (NSRange)aRange
								  insertedObject: (id)anObject
								sourceIdentifier: (id)aSource;
@end
