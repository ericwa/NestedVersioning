#import <Foundation/Foundation.h>

@class ETUUID;
@class COSubtree;
@class COMutableItem;

@class COSubtreeEdit;
@class COSubtreeConflict;
@class COSubtreeDiff;
@class COSetDiff, COArrayDiff;
@class COType;



@interface COSubtreeConflict : NSObject // not publically copyable.
{
	COSubtreeDiff *parentDiff; /* weak reference */
	NSMutableDictionary *editsForSourceIdentifier;
}

- (COSubtreeDiff *) parentDiff;

- (NSSet *) sourceIdentifiers;

/**
 * @returns a set of COEdit objects owned by the parent
 * diff. the caller could for example, modify them, 
 * or remove some from the parent diff
 */
- (NSSet *) editsForSourceIdentifier: (id)anIdentifier;

- (NSSet *) allEdits;

- (BOOL) isNonconflicting;

// private

- (void) removeEdit: (COSubtreeEdit *)anEdit

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
	NSMutableDictionary *dict;
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

- (void) _applyEdits: (NSSet *)edits;


#pragma mark access (sub-objects may be mutated by caller)

- (NSSet *)edits;
- (NSSet *) editsForUUID: (ETUUID *)aUUID attribute: (NSString *)aString;
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

