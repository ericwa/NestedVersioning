#import <Foundation/Foundation.h>

@class ETUUID;
@class COSubtree;
@class COMutableItem;

@class COSubtreeEdit;
@class COSubtreeConflict;
@class COSubtreeDiff;
@class COSetDiff, COArrayDiff;
@class COType;

@interface COUUIDAttributeTuple : NSObject <NSCopying>
{
	ETUUID *uuid;
	NSString *attribute;
}

+ (COUUIDAttributeTuple *) tupleWithUUID: (ETUUID *)aUUID attribute: (NSString *)anAttribute;
- (ETUUID *) UUID;
- (NSString *) attribute;

@end


@interface CODiffDictionary : NSObject <NSCopying>
{
	NSMutableDictionary *dict;
}

- (NSSet *) editsForTuple: (COUUIDAttributeTuple *)aTuple;
- (NSSet *) editsForUUID: (ETUUID *)aUUID attribute: (NSString *)aString;
- (void) addEdit: (COSubtreeEdit *)anEdit;
- (void) removeEdit: (COSubtreeEdit *)anEdit;
- (NSArray *)allTuples;

@end


@interface COSubtreeConflict : NSObject <NSCopying>
{
	COSubtreeDiff *parentDiff; /* weak reference */
	NSMutableDictionary *editsForSourceIdentifier;
	BOOL isReallyConflicting;
}

- (COSubtreeDiff *) parentDiff;

- (NSSet *) sourceIdentifiers;

/**
 * @returns a set of COEdit objects owned by the parent
 * diff. the caller could for example, modify them, 
 * or remove some from the parent diff
 */
- (NSSet *) editsForSourceIdentifier: (id)anIdentifier;

- (BOOL) isReallyConflicting;

@end




/**
 * Concerns for COSubtreeDiff:
 * - conflicts arise when the same subtree is inserted in multiple places.
 * - note that a _COSubtree_ cannot exist in an inconsistent state.
 */
@interface COSubtreeDiff : NSObject <NSCopying>
{
	ETUUID *oldRoot;
	ETUUID *newRoot;
	CODiffDictionary *diffDict;
	NSMutableSet *conflicts;
}

+ (COSubtreeDiff *) diffSubtree: (COSubtree *)a
					withSubtree: (COSubtree *)b
			   sourceIdentifier: (id)aSource;

- (COSubtree *) subtreeWithDiffAppliedToSubtree: (COSubtree *)aSubtree;

/**
 * Throws an exception if either diff has conflicts
 *
 * Caller owns the return value with respect to mutation
 * - they may freely modify it.
 */
- (COSubtreeDiff *)subtreeDiffByMergingWithDiff: (COSubtreeDiff *)other;

- (BOOL) hasConflicts;

#pragma mark access (sub-objects may be mutated by caller)

- (NSSet *)edits;
- (NSSet *)conflicts;

#pragma mark access

- (NSSet *)modifiedItemUUIDs;

#pragma mark mutation

/**
 * removes conflict (by extension, all the conflicting changes)... 
 * caller should subsequently insert or update edits to reflect the
 * resolution of the conflict.
 */
- (void) removeConflict: (COSubtreeConflict *)aConflict;
- (void) addEdit: (COSubtreeEdit *)anEdit;
- (void) removeEdit: (COSubtreeEdit *)anEdit;

@end



#pragma mark operation classes

@interface COSubtreeEdit : NSObject <NSCopying>
{
	ETUUID *UUID;
	NSString *attribute;
}

@property (readwrite, nonatomic, copy) ETUUID *UUID;
@property (readwrite, nonatomic, copy) NSString *attribute;

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



/**
 * Set diffs can always be merged without conflict
 */
@interface COSetDiff : COSubtreeEdit
{
	NSDictionary *insertionsForSourceIdentifier;
	NSDictionary *deletionsForSourceIdentifier;
}

// Creating

- (id) initWithFirstSet: (NSSet *)first
              secondSet: (NSSet *)second
	   sourceIdentifier: (id)aSource;

// Examining

- (NSSet *)insertionSet;
- (NSSet *)deletionSet;

- (NSSet *)insertionSetForSourceIdentifier: (id)anIdentifier;
- (NSSet *)deletionSetForSourceIdentifier: (id)anIdentifier;

// Applying

- (void) applyTo: (NSMutableSet*)array;
- (NSSet *)setWithDiffAppliedTo: (NSSet *)array;
- (id) valueWithDiffAppliedToValue: (id)aValue;

// Merging with another COSetDiff

- (COSetDiff *)setDiffByMergingWithDiff: (COSetDiff *)other;

@end
