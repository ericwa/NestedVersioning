#import <Foundation/Foundation.h>
#import "COType.h"

@class ETUUID;


#pragma mark base class

@interface COSubtreeEdit : NSObject <NSCopying>
{
	ETUUID *UUID;
	NSString *attribute;
	id sourceIdentifier;
}

@property (readonly, nonatomic) ETUUID *UUID;
@property (readonly, nonatomic) NSString *attribute;
@property (readonly, nonatomic) id sourceIdentifier;

// NO applyTo: (applying a set of array edits requires a special procedure)
// NO doesntConflictWith: (checking a set of array edits for conflicts requires a special procedure)

- (BOOL) isEqualIgnoringSourceIdentifier: (id)other;

- (id) initWithUUID: (ETUUID *)aUUID
		  attribute: (NSString *)anAttribute
   sourceIdentifier: (id)aSourceIdentifier;

@end

#pragma mark set, delete attribute

@interface COSetAttribute : COSubtreeEdit 
{
	COType *type;
	id value;
}
@property (readonly, nonatomic) COType *type;
@property (readonly, nonatomic) id value;

- (id) initWithUUID: (ETUUID *)aUUID
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
	id object;
}
@property (readonly, nonatomic) id object;

- (id) initWithUUID: (ETUUID *)aUUID
		  attribute: (NSString *)anAttribute
   sourceIdentifier: (id)aSourceIdentifier
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

- (id) initWithUUID: (ETUUID *)aUUID
		  attribute: (NSString *)anAttribute
   sourceIdentifier: (id)aSourceIdentifier
			  range: (NSRange)aRange;

@end


@interface COSequenceInsertion : COSequenceEdit 
{
	NSArray *objects;
}
@property (readonly, nonatomic)  NSArray *objects;

- (id) initWithUUID: (ETUUID *)aUUID
		  attribute: (NSString *)anAttribute
   sourceIdentifier: (id)aSourceIdentifier
		   location: (NSUInteger)aLocation
			objects: (NSArray *)anArray;

@end



@interface COSequenceDeletion : COSequenceEdit
@end


@interface COSequenceModification : COSequenceInsertion

- (id) initWithUUID: (ETUUID *)aUUID
		  attribute: (NSString *)anAttribute
   sourceIdentifier: (id)aSourceIdentifier
			  range: (NSRange)aRange
			objects: (NSArray *)anArray;
@end
