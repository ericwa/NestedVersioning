#import <Foundation/Foundation.h>

@class ETUUID;

@interface COSubtreeEdit : NSObject <NSCopying>
{
	ETUUID *UUID;
	NSString *attribute;
	id sourceIdentifier;
}

@property (readwrite, nonatomic, copy) ETUUID *UUID;
@property (readwrite, nonatomic, copy) NSString *attribute;
@property (readwrite, nonatomic, copy) id sourceIdentifier;

- (void) applyTo: (COMutableItem *)anItem;

@end

@interface COStoreItemDiffOperationSetAttribute : COSubtreeEdit 
{
	COType *type;
	id value;
}
- (id) initWithType: (COType*)aType
			  value: (id)aValue;

@end

@interface COStoreItemDiffOperationDeleteAttribute : COSubtreeEdit
@end




@interface COSetInsert : COSubtreeEdit
{
	id object;
}


@end


@interface COSetDeletion : COSubtreeEdit
{
	id object;
}


@end



@interface COSequenceEdit : COSubtreeEdit
{
	NSRange range;	
}

@property (nonatomic, readonly) NSRange range;

- (NSComparisonResult) compare: (id)otherObject;

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
	NSArray *insertedObject;
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
	NSArray *insertedObjects;
}
@property (nonatomic, retain, readonly)  id insertedObject;
+ (COSequenceModification*)modificationWithRange: (NSRange)aRange
								  insertedObject: (id)anObject
								sourceIdentifier: (id)aSource;
@end
