#import <Cocoa/Cocoa.h>

@interface EWDrawingWindowController : NSWindowController
{
	IBOutlet NSTextField *widthField;
	IBOutlet NSTextField *heightField;
}

- (IBAction) changeSize: (id)sender;

@end
