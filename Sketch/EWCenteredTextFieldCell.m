#import "EWCenteredTextFieldCell.h"

@implementation EWCenteredTextFieldCell

- (NSRect) titleRectForBounds: (NSRect)cellFrame
{
	NSRect titleRect = [super titleRectForBounds: cellFrame];
	NSSize titleSize = [[self attributedStringValue] size];
	titleRect.origin.y = (titleRect.origin.y + ((titleRect.size.height - titleSize.height) / 2.0));	
	titleRect.size.height = titleSize.height;
	return titleRect;
}


- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSRect titleRect = [self titleRectForBounds:cellFrame];
    [[self attributedStringValue] drawInRect:titleRect];
}

- (void) editWithFrame: (NSRect)aRect
				inView: (NSView *)controlView
				editor: (NSText*)textObj
			  delegate: (id)anObject
				 event: (NSEvent*)theEvent
{
    [super editWithFrame: [self titleRectForBounds:aRect]
				  inView: controlView
				  editor: textObj
				delegate: anObject
				   event: theEvent];
}

- (void) selectWithFrame: (NSRect)aRect
				  inView: (NSView *)controlView
				  editor: (NSText *)textObj
				delegate: (id)anObject
				   start: (NSInteger)selStart
				  length: (NSInteger)selLength
{
    [super selectWithFrame: [self titleRectForBounds:aRect]
					inView: controlView
					editor: textObj
				  delegate: anObject
					 start: selStart
					length: selLength];
}

@end
