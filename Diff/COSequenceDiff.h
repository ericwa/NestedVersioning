#import <Foundation/Foundation.h>

/**
 * Abstract superclass for a sequence edit. Has a range (in the source sequence)
 * to which it applies.
 *
 * For now, all subclasses are immutable.
 *
 * source identifier property, used to indicate where (which user/branch/commit etc)
 * a change originates.
 *
 * sourceIdentifier must be non-nil and sutible as a dictionary key.
 */
@interface COSequenceEdit : NSObject <NSCopying>
{
	NSRange range;
	id sourceIdentifier;
}

@property (nonatomic, readonly) NSRange range;
@property (nonatomic, readonly) id sourceIdentifier;

- (NSComparisonResult) compare: (id)otherObject;

- (BOOL) overlaps: (COSequenceEdit *)other;

/**
 * Convenience method which returns the reciever in an NSSet,
 * except for COOverlappingSequenceEditGroup, where it returns all overlapping edits.
 */
- (NSSet *)allEdits;

/**
 * Ignores sourceIdentifier
 */
- (BOOL) isEqualIgnoringSourceIdentifier:(id)object;

@end


/**
 * Concrete subclass of COPrimitiveSequenceEdit which represents
 * an insertion of one or more elements into the sequence.
 */
@interface COSequenceInsertion : COSequenceEdit 
{
	id insertedObject;
}
@property (nonatomic, readonly)  id insertedObject;
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
