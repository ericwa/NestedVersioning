#import "COEdit.h"

@interface COEditSetMetadata : COEdit
{
    NSDictionary *old_;
    NSDictionary *new_;
}

- (id) initWithOldMetadata: (NSDictionary *)oldMeta
               newMetadata: (NSDictionary *)newMeta
                      UUID: (ETUUID*)aUUID
                      date: (NSDate*)aDate
               displayName: (NSString*)aName;
@end
