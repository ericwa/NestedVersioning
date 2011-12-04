#import <Foundation/Foundation.h>
#import "ETUUID.h"
#import "COStoreItem.h"

@interface COItemPath : NSObject <NSCopying>
{
	ETUUID *uuid;
	NSString *attribute;
}

+ (COItemPath *) pathWithItemUUID: (ETUUID *)aUUID
		  unorderedCollectionName: (NSString *)collection
				 uuidInCollection: (ETUUID*)aUUIDInCollection;
+ (COItemPath *) pathWithItemUUID: (ETUUID *)aUUID
						arrayName: (NSString *)collection
							index: (NSUInteger)index;

- (void) insertValue: (id)aValue
		 inStoreItem: (COStoreItem *)aStoreItem;

@end
