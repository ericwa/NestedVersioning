#import <Foundation/Foundation.h>

#import "COStoreItem.h"
#import "ETUUID.h"

@interface COStoreItemTree : NSObject <NSCopying>
{
	ETUUID *root;
	NSMutableSet *items;
}

+ (COStoreItemTree *)itemTreeWithItems: (NSSet*)items root: (ETUUID*)aRoot;

- (NSSet *)items;
- (ETUUID *)root;

@end
