#import <Foundation/Foundation.h>

@class COUUID;
@class COType;
@class COItem;


@interface CORelationshipRecord : NSObject
{
@private
    COUUID *uuid_;
    NSString *property_;
}

+ (CORelationshipRecord *) recordWithUUID: (COUUID *)aUUID property: (NSString *)aProp;

// FIXME: Make not mutable to the public
@property (readwrite, nonatomic, retain) COUUID *uuid;
@property (readwrite, nonatomic, retain) NSString *property;
@end

/**
 * Simple wrapper around an NSMutableDictionary mapping COUUID's to mutable sets of COUUID's.
 */
@interface CORelationshipCache : NSObject
{
    NSMutableDictionary *embeddedObjectParentUUIDForUUID_;
    NSMutableDictionary *referrerUUIDsForUUID_;
    CORelationshipRecord *tempRecord_;
}

- (void) updateRelationshipCacheWithOldValue: (id)oldVal
                                     oldType: (COType *)oldType
                                    newValue: (id)newVal
                                     newType: (COType *)newType
                                 forProperty: (NSString *)aProperty
                                    ofObject: (COUUID *)anObject;

/**
 * @returns a set of CORelationshipRecord
 */
- (NSSet *) referrersForUUID: (COUUID *)anObject;
- (CORelationshipRecord *) parentForUUID: (COUUID *)anObject;

/**
 * @returns a set of COUUID
 */
- (NSSet *) referrersForUUID: (COUUID *)anObject
            propertyInParent: (NSString*)propInParent;

@end
