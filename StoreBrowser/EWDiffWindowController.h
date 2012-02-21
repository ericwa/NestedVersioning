#import <Cocoa/Cocoa.h>

@class COPersistentRootDiff;

@interface EWDiffWindowController : NSWindowController
{

}

- (id) initWithPersistentRootDiff: (COPersistentRootDiff*)aDiff;

@end
