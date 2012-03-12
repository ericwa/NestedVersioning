#import <Foundation/Foundation.h>

@class ETUUID;
@class COSubtree;
@class COMutableItem;

@class COStoreItemDiffOperation;
@class COSubtreeConflict;
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

- (NSArray *) editsForTuple: (COUUIDAttributeTuple *)aTuple;
- (NSArray *) editsForUUID: (ETUUID *)aUUID attribute: (NSString *)aString;
- (void) addEdit: (COStoreItemDiffOperation *)anEdit forUUID: (ETUUID *)aUUID attribute: (NSString *)aString;
- (NSArray *)allTuples;

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
}

+ (COSubtreeDiff *) diffSubtree: (COSubtree *)a
					withSubtree: (COSubtree *)b;

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
- (void) addEdit: (COStoreItemDiffOperation *)anEdit;
- (void) removeEdit: (COStoreItemDiffOperation *)anEdit;

@end



// operation classes

@interface COStoreItemDiffOperation : NSObject

- (void) applyTo: (COMutableItem *)anItem attribute: (NSString *)anAttribute;

@end

@interface COStoreItemDiffOperationSetAttribute : COStoreItemDiffOperation 
{
	COType *type;
	id value;
}
- (id) initWithType: (COType*)aType
			  value: (id)aValue;

@end

@interface COStoreItemDiffOperationDeleteAttribute : COStoreItemDiffOperation
@end


@interface COStoreItemDiffOperationModifyArray : COStoreItemDiffOperation
{
	COArrayDiff *arrayDiff;
}

- (id) initWithArrayDiff: (COArrayDiff *)aDiff;

@end


@interface COStoreItemDiffOperationModifySet : COStoreItemDiffOperation
{
	COSetDiff *setDiff;
}

- (id) initWithSetDiff: (COSetDiff *)aDiff;

@end



