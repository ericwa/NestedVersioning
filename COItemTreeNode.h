#import <Foundation/Foundation.h>

#import "ETUUID.h"


/**
 */
@interface COItemTreeNode : NSObject
{
	ETUUID *uuid;
	NSMutableDictionary *valueForAttribute; // string -> (COItemTreeNode, NString, ETUUID, NSNumber, NSData) or set/array
	NSMutableDictionary *typeForAttribute; // string-> COType
	COItemTreeNode *parent; // weak ref
}

/**
 * @returns nil if the receiver has no parent.
 * Otherwise, the item tree node in which the receiver is embedded.
 */
- (COItemTreeNode *) parent;

/**
 * Returns the root of the item tree
 */
- (COItemTreeNode *) root;

- (id) copyWithZone: (NSZone*)aZone;

@end
