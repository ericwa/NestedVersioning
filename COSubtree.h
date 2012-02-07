#import <Foundation/Foundation.h>

#import "COItem.h"
#import "ETUUID.h"

@class COSubtreeCopy;
@class COItemPath;

/**
 * This is a mutable model object for modelling the contents of a persistent
 * root... high-level counterpart to COItem. See comment in COItem.h.
 * COSubtree instances are arranged in a tree structure following
 * normal ObjC container semantics.
 *
 * Comment on NestedVersioning data model:
 * 
 * Why is the data model a tree instead of a reference-counted graph?
 * We want our data model to have clear and simple semantics for copying
 * and moving sections of data, and by forcing users to structure data
 * in a tree they are defining the copying semantics of their data
 * as a side effect
 */
@interface COSubtree : NSObject <NSCopying>
{
	@private
	COMutableItem *root;
	NSMutableDictionary *embeddedSubtrees;
	COSubtree *parent; // weak reference
}

#pragma mark Creation

- (id) initWithUUID: (ETUUID*)aUUID;

/**
 * init with a new UUID
 */
- (id) init;

/**
 * new item with new UIID
 */
+ (COSubtree *)subtree;

/**
 * Builds a COSubtree from a set of items and the UUID
 * of the root item. Throws an exception under any of these circumstances:
 *  - items does not contain an item with UUID aRootUUID
 *  - items contains more than one item with the same UUID
 */
+ (COSubtree *)subtreeWithItemSet: (NSSet*)items
						 rootUUID: (ETUUID *)aRootUUID;

/**
 * @returns a mutable copy, with UUID's unmodified.
 */
- (id)copyWithZone:(NSZone *)zone;

/**
 * @returns a mutable copy with all items in the tree renamed.
 *
 * Implemented in terms of subtreeCopyWithNameMapping:
 */
- (COSubtreeCopy *)subtreeCopyRenamingAllItems;

/**
 * @returns a mutable copy with items specified in the mapping
 * dictionary renamed to the value specified in the dictionary,
 * and all other items keep their original names.
 *
 * Any items within receiver which have path attributes
 * pointing to items within the receiver will be updated to reflect
 * the new names.
 *
 * mapping can include the receiver's UUID
 */
- (COSubtreeCopy *)subtreeCopyWithNameMapping: (NSDictionary *)aMapping;


/*
 general comment on copying:
 
 - when we copy/move an embedded object from one persistent root to another, it keeps the same uuid. are there any cases where this could cause problems? what if the destination already has objects with some/all of those uuids? probably keep the familiar filesystem semantics:
 • copy & paste in the same directory (for CO: in the same persistent root), and it makes sense to assign new UUIDs since otherwise the copy&paste would do nothing. 
 • copy & paste in to another directory (for CO: into another persistent root), and it makes sense to keep the same UUIDs, and overwrite any existing destination objects(?)
 
 
 */



#pragma mark Access to the tree stucture



/**
 * @returns nil if the receiver has no parent.
 * Otherwise, the item tree node in which the receiver is embedded.
 */
- (COSubtree *) parent;

/**
 * Returns the root of the item tree
 */
- (COSubtree *) root;

/**
 * Returns YES if the uuid is contained
 * in the receiver (or if it is the receiver's UUID)
 */
- (BOOL) containsSubtreeWithUUID: (ETUUID *)aUUID;

- (NSSet *)allUUIDs;

/**
 * returns the set of all contained COItem instances, including self's
 */
- (NSSet *)allContainedStoreItems;

- (NSSet *)allDescendentSubtreeUUIDs;

- (NSSet *)directDescendentSubtreeUUIDs;
- (NSArray *)directDescendentSubtrees;

/**
 * Searches the receiver for the subtree with the givent UUID.
 * Returns nil if not present.
 * Returns self if given self's uuid
 */
- (COSubtree *) subtreeWithUUID: (ETUUID *)aUUID;

- (COItemPath *) itemPathOfSubtreeWithUUID: (ETUUID *)aUUID;



#pragma mark Access to the receiver's attributes/values



- (COItem *) item;

- (ETUUID *) UUID;

- (NSArray *) attributeNames;

- (COType *) typeForAttribute: (NSString *)anAttribute;

/**
 * @returns the value for the given
 * attribute, with the special case of embedded item
 * UUIDs are returned as COSubtree objects
 */
- (id) valueForAttribute: (NSString*)anAttribute;



#pragma mark Mutation


/**
 * can handle COSubtree
 */
- (void) setPrimitiveValue: (id)aValue
			  forAttribute: (NSString*)anAttribute
					  type: (COType *)aType;


- (void)removeValueForAttribute: (NSString*)anAttribute;

/**
 * Creates the container if needed. 
 */
- (void)   addObject: (id)aValue
toUnorderedAttribute: (NSString*)anAttribute
				type: (COType *)aType;

/**
 * Creates the container if needed. 
 */
- (void)   addObject: (id)aValue
  toOrderedAttribute: (NSString*)anAttribute
			 atIndex: (NSUInteger)anIndex
				type: (COType *)aType;

/**
 * Inserts the given subtree at the given item path.
 * The provided subtree is removed from its parent, if it has one.
 * i.e. [aSubtree parent] is mutated by the method call!
 *
 * Works regardless of whether aSubtree is a descendant of
 * [self parent].
 *
 * If the subtree being inserted has names which overlap with names in our
 * root's tree, what do we do? Silently rename those overlapping names in the
 * subtree being inserted?
 */
- (void) addSubtree: (COSubtree *)aSubtree
		 atItemPath: (COItemPath *)aPath;

- (COSubtreeCopy *) addSubtreeRenamingObjectsOnConflict: (COSubtree *)aSubtree
											 atItemPath: (COItemPath *)aPath;

/**
 * Removes a subtree (regardless of where in the receiver or the receiver's children
 * it is located.) Throws an exception if the guven UUID is not present in the receiver.
 */
- (void) removeSubtreeWithUUID: (ETUUID *)aUUID;

- (void) moveSubtreeWithUUID: (ETUUID *)aUUID
				  toItemPath: (COItemPath *)aPath;

/**
 * in-place rename
 */
- (void) renameWithNameMapping: (NSDictionary *)aMapping;

#pragma mark equality testing

- (BOOL) isEqual:(id)object;
- (NSUInteger) hash;


@end

/**
 * Convenience methods for interacting with the default
 * "contents" set attribute
 */
@interface COSubtree (ContentsProperty)

/**
 * See comments on -addSubtree:atItemPath:
 */
- (void) addTree: (COSubtree *)aValue;

/**
 * @returns a set of COSubtree
 */
- (NSSet*) contents;

@end