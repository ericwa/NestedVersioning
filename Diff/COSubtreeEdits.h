#import <Foundation/Foundation.h>
#import "COType.h"

@class ETUUID;

/**
 
 since we store these in NSSets, the should really be immutable (hash must not change)
 
 */

#pragma mark base class

@interface COSubtreeEdit : NSObject <NSCopying>
{
	ETUUID *UUID;
	NSString *attribute;
	id sourceIdentifier;
}

@property (readwrite, nonatomic, copy) ETUUID *UUID;
@property (readwrite, nonatomic, copy) NSString *attribute;
@property (readwrite, nonatomic, copy) id sourceIdentifier;

// NO applyTo: (applying a set of array edits requires a special procedure)
// NO doesntConflictWith: (checking a set of array edits for conflicts requires a special procedure)

- (BOOL) isEqualIgnoringSourceIdentifier: (id)other;


@end

#pragma mark set, delete attribute

@interface COSetAttribute : COSubtreeEdit 
{
	COType *type;
	id value;
}
@property (readwrite, nonatomic, copy) COType *type;
@property (readwrite, nonatomic, copy) id value;

@end


@interface CODeleteAttribute : COSubtreeEdit
@end


#pragma mark editing set multivalueds

@interface COSetInsertion : COSubtreeEdit
{
	id object;
}
@property (readwrite, nonatomic, copy) id object;
@end


@interface COSetDeletion : COSetInsertion
@end


#pragma mark editing array multivalueds


@interface COSequenceEdit : COSubtreeEdit
{
	NSRange range;
}

@property (readwrite, nonatomic) NSRange range;

- (NSComparisonResult) compare: (id)otherObject;

@end


@interface COSequenceInsertion : COSequenceEdit 
{
	NSArray *insertedObjects;
}
@property (readwrite, nonatomic, copy)  NSArray *insertedObjects; // shallow copy => you must not modify objects in the array
@end



@interface COSequenceDeletion : COSequenceEdit
@end


@interface COSequenceModification : COSequenceInsertion
@end
