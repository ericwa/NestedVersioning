#import <Foundation/Foundation.h>

@class COUUID;
@class COItem;

/**
 * Change to a COPersistentRootState.
 *
 * The purpose of this object is to reduce the amount of reading/writing;
 *
 * Size is O(number of changes in delta * size of changed item data)
 * 
 */
@interface COPersistentRootStateDelta : NSObject
{
    COUUID *newRootItem;
    NSDictionary *itemForUUID;
}

- (NSArray *) modifiedItemUUIDs;
- (COItem *) itemForUUID: (COUUID *)aUUID;
- (COUUID *) rootItemUUID;

// Private

- (id) plist;
- (id) initWithPlist: (id)aPlist;

@end
