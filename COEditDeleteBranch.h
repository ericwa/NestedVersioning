#import "COEdit.h"

@class COBranchState;

/**
 * action which can undo the creation of a branch
 */
@interface COEditDeleteBranch : COEdit
{
    COBranchState *branch_;
}

- (id) initWithBranchPlist: (COBranchState *)aBranch
                      UUID: (COUUID*)aUUID
                      date: (NSDate*)aDate
               displayName: (NSString*)aName
         operationMetadata: (NSDictionary *)opMetadata;

@end
