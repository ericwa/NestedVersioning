#import "COEdit.h"

@interface COEditSetMetadata : COEdit
{
    NSDictionary *old_;
    NSDictionary *new_;
}

- (id) initWithOldMetadata: (NSDictionary *)oldMeta
               newMetadata: (NSDictionary *)newMeta
                      UUID: (COUUID*)aUUID
                      date: (NSDate*)aDate
               displayName: (NSString*)aName
         operationMetadata: (NSDictionary *)opMetadata;
@end
