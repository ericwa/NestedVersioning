#import <Foundation/Foundation.h>
#import "ETUUID.h"

@class COMutableStoreItem;

/**
 * COItemPath represents a _destination_ in a COSubtree for
 * inserting a value
 */
@interface COItemPath : NSObject <NSCopying>
{
	ETUUID *uuid;
	NSString *attribute;
}

+ (COItemPath *) pathWithItemUUID: (ETUUID *)aUUID
		  unorderedCollectionName: (NSString *)collection;

+ (COItemPath *) pathWithItemUUID: (ETUUID *)aUUID
						arrayName: (NSString *)collection
				   insertionIndex: (NSUInteger)index;

+ (COItemPath *) pathWithItemUUID: (ETUUID *)aUUID
						valueName: (NSString *)aName;

@end

@interface COItemPath (Private)

- (void) insertValue: (id)aValue
		 inStoreItem: (COMutableStoreItem *)aStoreItem;

@end