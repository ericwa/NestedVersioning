#import <Foundation/Foundation.h>

@class ETUUID;
@class COSubtree;

@class COSubtreeEdit;
@class COSubtreeConflict;

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
 */
- (COSubtreeDiff *)subtreeDiffByMergingWithDiff: (COSubtreeDiff *)other;

- (BOOL) hasConflicts;

#pragma mark access (sub-objects may be mutated by caller)

- (NSSet *)edits;
- (NSSet *)conflicts;

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



// edit classes


@interface COSubtreeEdit : NSObject
{
	ETUUID *itemUUID;
	NSString *attribute;
}
- (id) initWithItemUUID: (ETUUID*)aUUID attribute: (NSString*)anAttribute;
- (void) applyTo: (COMutableItem *)anItem;

@end



@interface COSubtreeSetAttribute : COSubtreeEdit 
{
	id value;
}
- (id) initWithItemUUID: (ETUUID*)aUUID
			  attribute: (NSString*)anAttribute
				   type: (COType*)aType
				  value: (id)aValue;

@end



@interface COSubtreeDeleteAttribute : COSubtreeEdit
@end
