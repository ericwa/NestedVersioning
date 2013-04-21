#import <Foundation/Foundation.h>
#import "COUUID.h"
#import "CORevisionID.h"

@interface COBranchState : NSObject <NSCopying>
{
@private
    COUUID *uuid_;
    
    CORevisionID *headRevisionId_;
    CORevisionID *tailRevisionId_;
    CORevisionID *currentState_;
    
    NSDictionary *metadata_;
    
    BOOL deleted_;
}

@property (readonly, nonatomic) COUUID *UUID;
@property (readwrite, copy, nonatomic) CORevisionID *headRevisionID;
@property (readwrite, copy, nonatomic) CORevisionID *tailRevisionID;
@property (readwrite, copy, nonatomic) CORevisionID *currentRevisionID;
@property (readwrite, copy, nonatomic) NSDictionary *metadata;
@property (readwrite, nonatomic, setter = setDeleted:, getter = isDeleted) BOOL deleted;

- (id) initWithUUID: (COUUID *)aUUID
     headRevisionId: (CORevisionID *)head
     tailRevisionId: (CORevisionID *)tail
       currentState: (CORevisionID *)state
           metadata: (NSDictionary *)theMetadata;
- (id) initWithBranchPlist: (COBranchState *)aPlist;

- (id) initWithPlist: (id)aPlist;
- (id) plist;

@end
