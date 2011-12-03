#import <Foundation/Foundation.h>

#import "COStoreItem.h"
#import "ETUUID.h"

/**
 * note: items retrieved from an item tree should be copied before being modified
 */
@interface COStoreItemTree : NSObject <NSCopying>
{
	ETUUID *root;
	NSMutableSet *items;
}

+ (COStoreItemTree *)itemTreeWithItems: (NSSet*)items root: (ETUUID*)aRoot;

- (NSSet *)items;
- (ETUUID *)root;

- (NSSet *)itemUUIDs;

- (COStoreItem *)rootItem;
+ (COStoreItemTree *)itemTreeWithItem: (COStoreItem*)anItem;

@end
