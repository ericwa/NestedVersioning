#import <Foundation/Foundation.h>
#import "COType.h"

@class COUUID;


#pragma mark base class

@interface COSubtreeEdit : NSObject <NSCopying>
{
	COUUID *UUID;
	NSString *attribute;
	id sourceIdentifier;
}

@property (readonly, nonatomic) COUUID *UUID;
@property (readonly, nonatomic) NSString *attribute;
@property (readonly, nonatomic) id sourceIdentifier;

// NO applyTo: (applying a set of array edits requires a special procedure)
// NO doesntConflictWith: (checking a set of array edits for conflicts requires a special procedure)

- (BOOL) isEqualIgnoringSourceIdentifier: (id)other;

- (id) initWithUUID: (COUUID *)aUUID
		  attribute: (NSString *)anAttribute
   sourceIdentifier: (id)aSourceIdentifier;

// information

- (NSSet *) insertedEmbeddedItemUUIDs;

- (BOOL) isSameKindOfEdit: (COSubtreeEdit*)anEdit;

@end

#pragma mark set, delete attribute

@interface COSetAttribute : COSubtreeEdit 
{
	COType *type;
	id value;
}
@property (readonly, nonatomic) COType *type;
@property (readonly, nonatomic) id value;

- (id) initWithUUID: (COUUID *)aUUID
		  attribute: (NSString *)anAttribute
   sourceIdentifier: (id)aSourceIdentifier
			   type: (COType *)aType
			  value: (id)aValue;

@end


@interface CODeleteAttribute : COSubtreeEdit
@end


#pragma mark editing set multivalueds

@interface COSetInsertion : COSubtreeEdit
{
	COType *type;
	id object;
}
@property (readonly, nonatomic) COType *type;
@property (readonly, nonatomic) id object;

- (id) initWithUUID: (COUUID *)aUUID
		  attribute: (NSString *)anAttribute
   sourceIdentifier: (id)aSourceIdentifier
			   type: (COType *)aType
			 object: (id)anObject;

@end


@interface COSetDeletion : COSetInsertion
@end


#pragma mark editing array multivalueds


@interface COSequenceEdit : COSubtreeEdit
{
	NSRange range;
}
@property (readonly, nonatomic) NSRange range;

- (NSComparisonResult) compare: (id)otherObject;
- (BOOL) overlaps: (COSequenceEdit *)other;

- (id) initWithUUID: (COUUID *)aUUID
		  attribute: (NSString *)anAttribute
   sourceIdentifier: (id)aSourceIdentifier
			  range: (NSRange)aRange;

@end

@interface COSequenceModification : COSequenceEdit
{
	COType *type;
	NSArray *objects;
}
@property (readonly, nonatomic) COType *type;
@property (readonly, nonatomic) NSArray *objects;

- (id) initWithUUID: (COUUID *)aUUID
		  attribute: (NSString *)anAttribute
   sourceIdentifier: (id)aSourceIdentifier
			  range: (NSRange)aRange
			   type: (COType *)aType
			objects: (NSArray *)anArray;
@end


@interface COSequenceInsertion : COSequenceModification 

- (id) initWithUUID: (COUUID *)aUUID
		  attribute: (NSString *)anAttribute
   sourceIdentifier: (id)aSourceIdentifier
		   location: (NSUInteger)aLocation
			   type: (COType *)aType
			objects: (NSArray *)anArray;

@end



@interface COSequenceDeletion : COSequenceEdit
@end


