#import <Cocoa/Cocoa.h>
#import "COStore.h"

@interface AppDelegate : NSObject
{
	NSMutableDictionary	*windowControllerForPath;
	COStore *store;
}

@property (assign) IBOutlet NSWindow *window;

- (void) browsePersistentRootAtPath: (COPath*)aPath;


@end
