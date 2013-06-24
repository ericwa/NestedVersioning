#import <Foundation/Foundation.h>

@class CORevisionID, COUUID;

@interface COSearchResult : NSObject
{
    CORevisionID *revision_;
    COUUID *embeddedObjectUUID_;
}

@property (nonatomic, readwrite, retain) CORevisionID *revision;
@property (nonatomic, readwrite, retain) COUUID *embeddedObjectUUID;

@end
