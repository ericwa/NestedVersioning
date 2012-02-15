#import <Foundation/Foundation.h>


@interface COSequenceDiff : NSObject
{
	NSArray *ops;
}

/**
 * Private, only for subclasses
 */
- (id) initWithOperations: (NSArray*)opers;

/**
 * Guaranteed to be sorted using -[COSequenceEdit compare:]
 */
- (NSArray *)operations;

- (COSequenceDiff *)sequenceDiffByMergingWithDiff: (COSequenceDiff *)other;

- (BOOL) hasConflicts;

@end


@class COPrimitiveSequenceEdit;

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

/**
 * Convenience method which returns the reciever in an NSSet,
 * except for COOverlappingSequenceEditGroup, where it returns all overlapping edits.
 */
- (NSSet *)allEdits;

/**
 * Convenience method which returns the reciever,
 * except for COOverlappingSequenceEditGroup, where if the receiver is nonconflicting,
 * (all contained edits are the same except for source identifier), it returns one
 * arbitrairly. Throws an exception if the receiver has conflicts.
 */
- (COPrimitiveSequenceEdit *)anyNonconflictingEdit;

- (BOOL) hasConflicts;

@end



/**
 * Abstract subclass of COSequenceEdit which adds a 
 * source identifier property, used to indicate where (which user/branch/commit etc)
 * a change originates.
 *
 * sourceIdentifier must be non-nil and sutible as a dictionary key.
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
 * an overlapping group of COPrimitiveSequenceEdit instances;
 * they may be conflicting or not.
 *
 * When presenting them to the user to resolve, the user should
 * see them grouped by sourceIdentifier; i.e. the user chooses
 * to use all edits with one sourceIdentifier, or all with another.
 */
@interface COOverlappingSequenceEditGroup : COSequenceEdit
{
	/**
	 * source identifier -> NSArray of COPrimitiveSequenceEdit
	 */
	NSDictionary *overlappingEdits; 
	/**
	 * determined at creation time by checking if all of the overlappingEdits
	 * are equal (ignoring sourceIdentifier) or not.
	 */
	BOOL conflicting;
}

/**
 * Sorted array of COPrimitiveSequenceEdit
 */
- (NSArray *) editsForSourceIdentifier: (id)anIdentifier;

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
