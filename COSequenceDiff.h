#import <Foundation/Foundation.h>


@interface COSequenceDiff : NSObject
{
	NSArray *ops;
}

- (id) initWithOperations: (NSArray*)opers;

/**
 * Guaranteed to be sorted using -[COSequenceEdit compare:]
 */
- (NSArray *)operations;

- (COSequenceDiff *)sequenceDiffByMergingWithDiff: (COSequenceDiff *)other;

@end



/**
 * Abstract superclass for a sequence edit. Has a range (in the source sequence)
 * to which it applies.
 *
 * For now, all subclasses are immutable.
 */
@interface COSequenceEdit : NSObject <NSCopying>
{
	NSRange range;
}
@property (nonatomic, readonly) NSRange range;
- (NSComparisonResult) compare: (id)otherObject;

- (BOOL) overlaps: (COSequenceEdit *)other;

@end



/**
 * Abstract subclass of COSequenceEdit which adds a 
 * source identifier property, used to indicate where (which user/branch/commit etc)
 * a change originates.
 */
@interface COPrimitiveSequenceEdit : COSequenceEdit
{
	id sourceIdentifier;
}
@property (nonatomic, readonly) id sourceIdentifier;
/**
 * Ignores sourceIdentifier
 */
- (BOOL) isEqualIgnoringSourceIdentifier:(id)object;
@end



/**
 * Concrete subclass of COSequenceEdit which represents
 * an overlapping group of edits; they may be conflicting or not.
 */
@interface COOverlappingSequenceEditGroup : COSequenceEdit
{
	NSSet *overlappingEdits;
	/**
	 * determined at creation time by checking if all of the overlappingEdits
	 * are equal or not.
	 */
	BOOL conflicting;
}
/**
 * Array of COPrimitiveSequenceEdit
 */
@property (nonatomic, readonly) NSSet *overlappingEdits;
@property (nonatomic, readonly) BOOL conflicting;
/**
 * The receiver's range is computed by taking the union of the edits
 */
+ (COOverlappingSequenceEditGroup *)overlappingEditGroupWithEdits: (NSSet *)edits;
@end



/**
 * Concrete subclass of COPrimitiveSequenceEdit which represents
 * an insertion of one or more elements into the sequence.
 */
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
