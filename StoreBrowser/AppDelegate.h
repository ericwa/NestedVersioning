#import <Cocoa/Cocoa.h>
#import "COStore.h"

@class EWPersistentRootWindowController;

@interface AppDelegate : NSObject
{
	NSMutableDictionary	*windowControllerForPath;
	COStore *store;
	NSWindow *_window;
}

@property (assign) IBOutlet NSWindow *window;

- (void) browsePersistentRootAtPath: (COPath*)aPath;

- (EWPersistentRootWindowController *) windowControllerForPath: (COPath*)aPath;

/**
 * Temporary hack...
 */
- (void) reloadAllBrowsers;

- (IBAction) garbageCollect: (id)sender;

@end
