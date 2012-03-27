#import <Cocoa/Cocoa.h>

@class EWZoomView;

@interface EWDrawingWindowController : NSWindowController
{
	IBOutlet NSTextField *widthField;
	IBOutlet NSTextField *heightField;
	
	IBOutlet EWZoomView *scrollView;
}

- (IBAction) changeSize: (id)sender;

@end
