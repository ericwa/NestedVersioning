#import "COEdit.h"

@interface COEditSetBranchMetadata : COEdit
{
    COUUID *branch_;
    NSDictionary *old_;
    NSDictionary *new_;
}

- (id) initWithOldMetadata: (NSDictionary *)oldMeta
               newMetadata: (NSDictionary *)newMeta
                      UUID: (COUUID*)aUUID
                branchUUID: (COUUID*)aBranch
                      date: (NSDate*)aDate
               displayName: (NSString*)aName
         operationMetadata: (NSDictionary *)opMetadata;
@end
