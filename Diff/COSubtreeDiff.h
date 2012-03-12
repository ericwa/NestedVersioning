#import <Foundation/Foundation.h>

@class ETUUID;
@class COSubtree;
@class COMutableItem;

@class COStoreItemDiffOperation;
@class COSubtreeConflict;
@class COSetDiff, COArrayDiff;
@class COType;

/**
 * Concerns for COSubtreeDiff:
 * - conflicts arise when the same subtree is inserted in multiple places.
 * - note that a _COSubtree_ cannot exist in an inconsistent state.
 */
@interface COSubtreeDiff : NSObject <NSCopying>
{
	ETUUID *oldRoot;
	ETUUID *newRoot;
	NSMutableSet *edits;
	NSMutableDictionary *insertedItemForUUID; // ETUUID : COItem
}

+ (COSubtreeDiff *) diffSubtree: (COSubtree *)a
					withSubtree: (COSubtree *)b;

- (COSubtree *) subtreeWithDiffAppliedToSubtree: (COSubtree *)aSubtree;

/**
 * apply in-place
 */
- (void) applyTo: (COSubtree *)aSubtree;

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
{
	ETUUID *uuid;
	NSString *attribute;
	COType *type;
}
- (id) initWithUUID: (ETUUID*)aUUID attribute: (NSString*)anAttribute type: (COType*)aType;
- (void) applyTo: (COMutableItem *)anItem;

- (NSString *) attribute;
- (ETUUID *) UUID;

@end

@interface COStoreItemDiffOperationSetAttribute : COStoreItemDiffOperation 
{
	id value;
}
- (id) initWithUUID: (ETUUID*)aUUID
		  attribute: (NSString*)anAttribute
			   type: (COType*)aType
			  value: (id)aValue;

@end

@interface COStoreItemDiffOperationDeleteAttribute : COStoreItemDiffOperation
@end


@interface COStoreItemDiffOperationModifyArray : COStoreItemDiffOperation
{
	COArrayDiff *arrayDiff;
}

- (id) initWithUUID: (ETUUID*)aUUID attribute: (NSString*)anAttribute type: (COType*)aType arrayDiff: (COArrayDiff *)aDiff;

@end


@interface COStoreItemDiffOperationModifySet : COStoreItemDiffOperation
{
	COSetDiff *setDiff;
}

- (id) initWithUUID: (ETUUID*)aUUID attribute: (NSString*)anAttribute type: (COType*)aType setDiff: (COSetDiff *)aDiff;

@end



