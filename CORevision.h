#import <Foundation/Foundation.h>
#import "CORevisionID.h"

/**
 *  Info about a commit. Parent revision (maybe nil), metadata, etc.
 *  There's a 1:1 mapping between a CORevisionID and CORevision per store.
 */
@interface CORevision : NSObject <NSCopying>
{
    CORevisionID *revisionId_;
    CORevisionID *parentRevisionId_;
    NSDictionary *metadata_;
}

- (id) initWithRevisionId: (CORevisionID *)revisionId
         parentRevisionId: (CORevisionID *)parentRevisionId
                 metadata: (NSDictionary *)metadata;

- (CORevisionID *)revisionId;
- (CORevisionID *)parentRevisionId;
- (NSDictionary *)metadata;

- (id) plist;
+ (CORevision *) revisionWithPlist: (id)plist;

@end
