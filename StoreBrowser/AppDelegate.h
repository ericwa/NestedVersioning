#import <Cocoa/Cocoa.h>
#import "COStore.h"

@class EWPersistentRootWindowController;

@interface AppDelegate : NSObject
{
	NSMutableDictionary	*windowControllerForPath;
	COStore *store;
}

@property (assign) IBOutlet NSWindow *window;

- (void) browsePersistentRootAtPath: (COPath*)aPath;

- (EWPersistentRootWindowController *) windowControllerForPath: (COPath*)aPath;

@end
