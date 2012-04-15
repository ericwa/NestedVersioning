#import <Cocoa/Cocoa.h>

@class EWZoomView;
@class COSubtree;

@interface EWDrawingWindowController : NSWindowController
{
	IBOutlet NSTextField *widthField;
	IBOutlet NSTextField *heightField;
	
	IBOutlet EWZoomView *scrollView;
	
	COSubtree *model;
}

- (IBAction) changeSize: (id)sender;

- (IBAction) cut: (id)sender;
- (IBAction) copy: (id)sender;
- (IBAction) paste: (id)sender;
- (IBAction) delete: (id)sender;

- (IBAction) sendToFront: (id)sender;
- (IBAction) sendToBack: (id)sender;
- (IBAction) sendForward: (id)sender;
- (IBAction) sendBackward: (id)sender;

@end
