#import <Cocoa/Cocoa.h>
#import "COStore.h"

@class EWProjectWindowController;
@class EWDrawingWindowController;

@interface SketchAppDelegate : NSObject
{
	EWProjectWindowController *projectWinController;	
	NSMutableDictionary	*drawingWinControllerForPath;
	COStore *store;
}

- (EWDrawingWindowController *) drawingWinControllerForPath: (COPath*)aPath;

- (void) orderFrontProjectWindow: (id)sender;

@end
