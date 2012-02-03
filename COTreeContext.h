#import <Foundation/Foundation.h>

@class ETUUID;

/**
 * An immutable tree of objects.
 *
 * For now, the main way to create one would be to create a mutable tree,
 * build it, and then make an immutable copy.
 *
 * Supports diffing trees. Has no notion of persistence - simply an in-memory
 * construct for working with trees of items.
 * Guarantees consitency (not more than one copy of an item per tree) and
 * implements all algorithms previously determined for subtrees.
 *
 * Two options:
 * 1) No class representing a single item; all methods are directly in 
 *    the tree context class with an additional "forItem: (ETUUID*)aUUID"
 *    parameter.
 * 2) Have a COObject-like class, owned by the tree context, for putting
 *    the various access/mutation methods in.
 * 
 * The options would work essentially the same way, it's just a stylistic
 * difference that separates them.
 */
@interface COTreeContext : NSObject <NSMutableCopying>

- (ETUUID*) rootItem;

- (id)copyWithZone: (NSZone*)aZone;
- (id)mutableCopyWithZone: (NSZone*)aZone;

@end


@interface COMutableTreeContext : COTreeContext


/**
 * can handle COSubtree
 */
- (void) setPrimitiveValue: (id)aValue
			  forAttribute: (NSString*)anAttribute
					  type: (COType *)aType;


- (void)removeValueForAttribute: (NSString*)anAttribute;

/**
 * Inserts the given subtree at the given item path.
 * The provided subtree is removed from its parent, if it has one.
 * i.e. [aSubtree parent] is mutated by the method call!
 *
 * Works regardless of whether aSubtree is a descendant of
 * [self parent].
 */
- (void) addSubtree: (COSubtree *)aSubtree
		 atItemPath: (COItemPath *)aPath;

/**
 * Removes a subtree (regardless of where in the receiver or the receiver's children
 * it is located.) Throws an exception if the guven UUID is not present in the receiver.
 */
- (void) removeSubtreeWithUUID: (ETUUID *)aUUID;

- (void) moveSubtreeWithUUID: (ETUUID *)aUUID
				  toItemPath: (COItemPath *)aPath;



@end