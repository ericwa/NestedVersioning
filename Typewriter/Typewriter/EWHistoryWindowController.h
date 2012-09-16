#import <Cocoa/Cocoa.h>

@interface EWHistoryWindowController : NSWindowController
{
}

+ (EWHistoryWindowController *) sharedController;

- (void) show;

@end
