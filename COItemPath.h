#import <Foundation/Foundation.h>
#import <EtoileFoundation/ETUUID.h>
#import "COType.h"

@class COMutableItem;


/**
 * COItemPath is a utiltiy class which represents a _destination_ in a COSubtree for
 * inserting a value.
 * 
 * see -[COSubtree moveSubtreeWithUUID:toItemPath:]
 */
@interface COItemPath : NSObject <NSCopying>
{
	ETUUID *uuid;
	NSString *attribute;
	COType type;
}

+ (COItemPath *) pathWithItemUUID: (ETUUID *)aUUID
		  unorderedCollectionName: (NSString *)collection
							 type: (COType)aType;

+ (COItemPath *) pathWithItemUUID: (ETUUID *)aUUID
						arrayName: (NSString *)collection
				   insertionIndex: (NSUInteger)index
							 type: (COType)aType;

+ (COItemPath *) pathWithItemUUID: (ETUUID *)aUUID
						valueName: (NSString *)aName
							 type: (COType)aType;

@end

@interface COItemPath (Private)

- (ETUUID *)UUID;

- (void) insertValue: (id)aValue
		 inStoreItem: (COMutableItem *)aStoreItem;
- (void) removeValue: (id)aValue inStoreItem: (COMutableItem *)aStoreItem;

@end