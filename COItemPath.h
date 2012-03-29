#import <Foundation/Foundation.h>
#import "COUUID.h"

@class COMutableItem;
@class COType;

/**
 * COItemPath is a utiltiy class which represents a _destination_ in a COSubtree for
 * inserting a value.
 * 
 * see -[COSubtree moveSubtreeWithUUID:toItemPath:]
 */
@interface COItemPath : NSObject <NSCopying>
{
	COUUID *uuid;
	NSString *attribute;
	COType *type;
}

+ (COItemPath *) pathWithItemUUID: (COUUID *)aUUID
		  unorderedCollectionName: (NSString *)collection
							 type: (COType *)aType;

+ (COItemPath *) pathWithItemUUID: (COUUID *)aUUID
						arrayName: (NSString *)collection
				   insertionIndex: (NSUInteger)index
							 type: (COType *)aType;

+ (COItemPath *) pathWithItemUUID: (COUUID *)aUUID
						valueName: (NSString *)aName
							 type: (COType *)aType;

@end

@interface COItemPath (Private)

- (COUUID *)UUID;

- (void) insertValue: (id)aValue
		 inStoreItem: (COMutableItem *)aStoreItem;
- (void) removeValue: (id)aValue inStoreItem: (COMutableItem *)aStoreItem;

@end