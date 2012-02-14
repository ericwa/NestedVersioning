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

// FIXME: keep in mind a user will likely write resolve a conflict
// by writing the correct result by hand, not by picking one
// side of the diff.
@interface COConflictingSequenceEditGroup : COSequenceEdit
{
	NSArray *conflictingEdits;
	COPrimitiveSequenceEdit *currentEdit; /* weak reference */
}
/**
 * Array of COPrimitiveSequenceEdit
 */
@property (nonatomic, readonly) NSArray *conflictingEdits;
/**
 * The current edit is which edit the user has picked to resolve
 * the conflict.
 * Returns nil if no edit is set as the current one.
 */
- (COPrimitiveSequenceEdit *) currentEdit;
- (void) setCurrentEdit: (COPrimitiveSequenceEdit *)anEdit;
/**
 * edits    an array of COPrimitiveSequenceEdit objects
 * The receiver's range is computed by taking the union of the edits
 */
+ (COConflictingSequenceEditGroup *)conflictingEditGroupWithEdits: (NSArray *)edits;
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