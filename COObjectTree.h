#import <Foundation/Foundation.h>

@class COUUID;
@class COItem;

/**
 * Immutable.
 */
@interface COObjectTree : NSObject
{
    COUUID *root_;
    NSDictionary *itemForUUID_;
}

- (id) initWithItemForUUID: (NSDictionary *) itemForUUID
                      root: (COUUID *)root;

- (COUUID *) root;
- (COItem *) itemForUUID: (COUUID *)aUUID;
- (NSArray *) objectUUIDs;

- (COObjectTree *) objectTreeWithNameMapping: (NSDictionary *)aMapping;

@end
