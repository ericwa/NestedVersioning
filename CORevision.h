#import <Foundation/Foundation.h>
#import "CORevisionID.h"

/**
 *  Info about a commit. Parent revision (maybe nil), metadata, etc.
 *  There's a 1:1 mapping between a CORevisionID and CORevision per store.
 */
@interface CORevision : NSObject <NSCopying>
{
    CORevisionID *revisionID_;
    CORevisionID *parentRevisionID_;
    NSDictionary *metadata_;
}

- (id) initWithRevisionID: (CORevisionID *)revisionId
         parentRevisionID: (CORevisionID *)parentRevisionId
                 metadata: (NSDictionary *)metadata;

- (CORevisionID *)revisionID;
- (CORevisionID *)parentRevisionID;
- (NSDictionary *)metadata;

- (id) plist;
+ (CORevision *) revisionWithPlist: (id)plist;

@end
