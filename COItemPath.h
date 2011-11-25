#import <Foundation/Foundation.h>
#import "ETUUID.h"

@interface COItemPath : NSObject
{

}

+ (COItemPath *) pathWithItemUUID: (ETUUID *)aUUID
		  unorderedCollectionName: (NSString *)collection;

+ (COItemPath *) pathWithItemUUID: (ETUUID *)aUUID
						arrayName: (NSString *)collection
							index: (NSUInteger)index;



@end
