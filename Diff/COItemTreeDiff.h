#import <Foundation/Foundation.h>

#import "COArrayDiff.h"
#import "COType.h"

@class COUUID;
@class COMutableItem;
@class COItemGraph;
@class COSubtreeEdit;
@class COItemTreeConflict;
@class COItemTreeDiff;
@class COSetDiff, COArrayDiff;

@class CODiffDictionary;

@interface COItemTreeConflict : NSObject // not publically copyable.
{
	@public
	COItemTreeDiff *parentDiff; /* weak reference */
	NSMutableDictionary *editsForSourceIdentifier; /* id => NSMutableSet of COSubtreeEdit*/
}

- (COItemTreeDiff *) parentDiff;

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
@interface COItemTreeDiff : NSObject <NSCopying, CODiffArraysDelegate>
{
	COUUID *oldRoot;
	COUUID *newRoot;
	CODiffDictionary *diffDict;
	
	// right now, the conflicts are purely derived from the set of edits.
	// it could be conceivably useful to be able to insert conflicts
	// that weren't auto-detected by COSubtreeDiff from looking at the edits, 
	// but that is not currently supported.
	
	NSMutableSet *embeddedItemInsertionConflicts; // insert item uuid X at two different places
	NSMutableSet *equalEditConflicts; // e.g. set [4:2] to ("h", "i") and [4:2] to ("h", "i")
	NSMutableSet *sequenceEditConflicts; // e.g. set [4:5] and [4:3]. doesn't include equal sequence edit conflicts
	NSMutableSet *editTypeConflicts; // e.g. set-value and delete-attribute
	NSMutableSet *valueConflicts; // e.g. set attr to "x" and set attr to "y"
}

+ (COItemTreeDiff *) diffItemTree: (id <COItemGraph>)a
                     withItemTree: (id <COItemGraph>)b
                 sourceIdentifier: (id)aSource;

- (COItemGraph *) itemTreeWithDiffAppliedToItemTree: (COItemGraph *)aSubtree;

- (COItemTreeDiff *)itemTreeDiffByMergingWithDiff: (COItemTreeDiff *)other;

- (BOOL) hasConflicts;

#pragma mark access (sub-objects may be mutated by caller)

- (NSSet *)allEdits;
/**
 * FIXME: Should this return "equal edit" conflicts?
 */
- (NSSet *)conflicts;

- (NSSet *) embeddedItemInsertionConflicts; // insert item uuid X at two different places
- (NSSet *) equalEditConflicts; // e.g. set [4:2] to ("h", "i") and [4:2] to ("h", "i")
- (NSSet *) sequenceEditConflicts; // e.g. set [4:5] and [4:3]. doesn't include equal sequence edit conflicts
- (NSSet *) editTypeConflicts; // e.g. delete + set
- (NSSet *) valueConflicts; // e.g. set attr to 'x' + set attr to 'y'

#pragma mark access

- (NSSet *)modifiedItemUUIDs;

- (NSSet *) modifiedAttributesForUUID: (COUUID *)aUUID;
- (NSSet *) editsForUUID: (COUUID *)aUUID;
- (NSSet *) editsForUUID: (COUUID *)aUUID attribute: (NSString *)aString;

#pragma mark mutation

/**
 * removes conflict (by extension, all the conflicting changes)... 
 * caller should subsequently insert or update edits to reflect the
 * resolution of the conflict.
 */
- (void) removeConflict: (COItemTreeConflict *)aConflict;
- (void) addEdit: (COSubtreeEdit *)anEdit;
- (void) removeEdit: (COSubtreeEdit *)anEdit;

@end

