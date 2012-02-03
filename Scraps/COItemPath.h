#import <Foundation/Foundation.h>
#import "ETUUID.h"

@class COMutableItem;
@class COType;

/**
 * COItemPath represents a _destination_ in a COSubtree for
 * inserting a value
 */
@interface COItemPath : NSObject <NSCopying>
{
	ETUUID *uuid;
	NSString *attribute;
	COType *type;
}

+ (COItemPath *) pathWithItemUUID: (ETUUID *)aUUID
		  unorderedCollectionName: (NSString *)collection
							 type: (COType *)aType;

+ (COItemPath *) pathWithItemUUID: (ETUUID *)aUUID
						arrayName: (NSString *)collection
				   insertionIndex: (NSUInteger)index
							 type: (COType *)aType;

+ (COItemPath *) pathWithItemUUID: (ETUUID *)aUUID
						valueName: (NSString *)aName
							 type: (COType *)aType;

@end

@interface COItemPath (Private)

- (ETUUID *)UUID;

- (void) insertValue: (id)aValue
		 inStoreItem: (COMutableItem *)aStoreItem;

@end