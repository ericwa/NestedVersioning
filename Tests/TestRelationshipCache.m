#import "TestCommon.h"

@interface TestRelationshipCache : NSObject <UKTest>
{
    CORelationshipCache *cache;
}
@end

@implementation TestRelationshipCache

- (id)init
{
    self = [super init];
    cache = [[CORelationshipCache alloc] init];
    return self;
}
- (void)dealloc
{
    [cache release];
    [super dealloc];
}

- (void) testParent
{
    UKNil([cache parentForUUID: nil]);
    
    COUUID *u1 = [COUUID UUID];
    COUUID *u2 = [COUUID UUID];
    COUUID *u3 = [COUUID UUID];
    
    [cache updateRelationshipCacheWithOldValue: nil
                                       oldType: nil
                                      newValue: u2
                                       newType: [COType embeddedItemType]
                                   forProperty: @"children"
                                      ofObject: u1];
    
    
    UKObjectsEqual([CORelationshipRecord recordWithUUID: u1 property: @"children"], [cache parentForUUID: u2]);

    [cache updateRelationshipCacheWithOldValue: nil
                                       oldType: nil
                                      newValue: u2
                                       newType: [COType embeddedItemType]
                                   forProperty: @"children"
                                      ofObject: u3];
    
    UKObjectsEqual([CORelationshipRecord recordWithUUID: u3 property: @"children"], [cache parentForUUID: u2]);
    
    [cache updateRelationshipCacheWithOldValue: u2
                                       oldType: [COType embeddedItemType]
                                      newValue: nil
                                       newType: [COType embeddedItemType]
                                   forProperty: @"children"
                                      ofObject: u3];
    
    UKNil([cache parentForUUID: u2]);
}

- (void) testParentWithEmbeddedItemSet
{
    
}

- (void) testReferences
{
    COUUID *u1 = [COUUID UUID];
    COUUID *u2 = [COUUID UUID];
    COUUID *u3 = [COUUID UUID];
    
    [cache updateRelationshipCacheWithOldValue: nil
                                       oldType: nil
                                      newValue: u2
                                       newType: [COType referenceType]
                                   forProperty: @"link1"
                                      ofObject: u1];
    
    [cache updateRelationshipCacheWithOldValue: nil
                                       oldType: nil
                                      newValue: u2
                                       newType: [COType referenceType]
                                   forProperty: @"link2"
                                      ofObject: u1];

    [cache updateRelationshipCacheWithOldValue: nil
                                       oldType: nil
                                      newValue: u2
                                       newType: [COType referenceType]
                                   forProperty: @"link1"
                                      ofObject: u3];
    
    UKObjectsEqual(S([CORelationshipRecord recordWithUUID: u1 property: @"link1"],
                     [CORelationshipRecord recordWithUUID: u1 property: @"link2"],
                     [CORelationshipRecord recordWithUUID: u3 property: @"link1"]), [cache referrersForUUID: u2]);
    
    [cache updateRelationshipCacheWithOldValue: u2
                                       oldType: [COType referenceType]
                                      newValue: nil
                                       newType: nil
                                   forProperty: @"link1"
                                      ofObject: u3];

    UKObjectsEqual(S([CORelationshipRecord recordWithUUID: u1 property: @"link1"],
                     [CORelationshipRecord recordWithUUID: u1 property: @"link2"]), [cache referrersForUUID: u2]);
}

@end