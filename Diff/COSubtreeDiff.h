#import <Foundation/Foundation.h>

#import "COArrayDiff.h"

@class ETUUID;
@class COSubtree;
@class COMutableItem;

@class COSubtreeEdit;
@class COSubtreeConflict;
@class COSubtreeDiff;
@class COSetDiff, COArrayDiff;
@class COType;

/**
 * abstracts the storage of edits... currently just an NSSet.
 */
@interface CODiffDictionary : NSObject <NSCopying>
{
	@public
	NSMutableSet *diffDictStorage;
}

- (NSSet *) modifiedAttributesForUUID: (ETUUID *)aUUID;
- (NSSet *) editsForUUID: (ETUUID *)aUUID;
- (NSSet *) editsForUUID: (ETUUID *)aUUID attribute: (NSString *)aString;
- (void) addEdit: (COSubtreeEdit *)anEdit;
- (void) removeEdit: (COSubtreeEdit *)anEdit;
- (NSSet *)allEditedUUIDs;
- (NSSet *)allEdits;

@end


@interface COSubtreeConflict : NSObject // not publically copyable.
{
	@public
	COSubtreeDiff *parentDiff; /* weak reference */
	NSMutableDictionary *editsForSourceIdentifier; /* id => NSMutableSet of COSubtreeEdit*/
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

- (void) removeEdit: (COSubtreeEdit *)anEdit;
- (void) addEdit: (COSubtreeEdit *)anEdit;

@end




/**
 * Concerns for COSubtreeDiff:
 * - conflicts arise when the same subtree is inserted in multiple places.
 * - note that a _COSubtree_ cannot exist in an inconsistent state.
 */
@interface COSubtreeDiff : NSObject <NSCopying, CODiffArraysDelegate>
{
	ETUUID *oldRoot;
	ETUUID *newRoot;
	CODiffDictionary *diffDict;
	
	// right now, the conflicts are purely derived from the set of edits.
	// it could be conceivably useful to be able to insert conflicts
	// that weren't auto-detected by COSubtreeDiff from looking at the edits, 
	// but that is not currently supported.
	
	NSMutableSet *conflicts;
}

+ (COSubtreeDiff *) diffSubtree: (COSubtree *)a
					withSubtree: (COSubtree *)b
			   sourceIdentifier: (id)aSource;

- (COSubtree *) subtreeWithDiffAppliedToSubtree: (COSubtree *)aSubtree;

- (COSubtreeDiff *)subtreeDiffByMergingWithDiff: (COSubtreeDiff *)other;

- (BOOL) hasConflicts;

- (void) _applyEdits: (NSSet *)edits;


#pragma mark access (sub-objects may be mutated by caller)

- (NSSet *)allEdits;
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

