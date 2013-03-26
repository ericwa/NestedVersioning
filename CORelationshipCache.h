#import <Foundation/Foundation.h>

@class COUUID;
@class COType;
@class COItem;

/**
 * Simple wrapper around an NSMutableDictionary mapping COUUID's to mutable sets of COUUID's.
 */
@interface CORelationshipCache : NSObject
{
    NSMutableDictionary *embeddedObjectParentUUIDForUUID_;
    NSMutableDictionary *referrerUUIDsForUUID_;
}

- (void) updateRelationshipCacheWithOldValue: (id)oldVal
                                     oldType: (COType *)oldType
                                    newValue: (id)newVal
                                     newType: (COType *)newType
                                 forProperty: (NSString *)aProperty
                                    ofObject: (COUUID *)anObject;

- (void) updateRelationshipCacheWithOldItems: (NSArray *)oldItems
                                    newItems: (NSArray *)newItems;

- (NSSet *) referrersForUUID: (COUUID *)anObject;
- (COUUID *) parentForUUID: (COUUID *)anObject;

@end
