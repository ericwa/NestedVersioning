#import "EWIconTextFieldCell.h"
#import <EtoileFoundation/Macros.h>

@implementation EWIconTextFieldCell

static const CGFloat EWIconMargin = 3.0;

- (id) init
{
	SUPERINIT;
	
	[self setLineBreakMode: NSLineBreakByTruncatingTail];
	
	return self;
}

- (NSImage *)image
{
	return icon;
}

- (void) setImage: (NSImage*)anImage
{
	ASSIGN(icon, anImage);
}

- (void) dealloc
{
    [icon release];
    [super dealloc];
}

- (id) copyWithZone: (NSZone *)aZone
{
    EWIconTextFieldCell *result = (EWIconTextFieldCell *)[super copyWithZone: aZone];
    result->icon = [icon copyWithZone: aZone];
    return result;
}

- (CGFloat) imageWidth
{
	if (nil != icon)
	{
		return [icon size].width + (2 * EWIconMargin);
	}
	return EWIconMargin;
}

- (NSRect) imageRectForBounds: (NSRect)cellFrame
{
    if (nil != icon)
	{
		const NSSize imgSize = [icon size];
		cellFrame.origin.y += (cellFrame.size.height - imgSize.height) / 2.0;
		cellFrame.origin.x += EWIconMargin;
		cellFrame.size = imgSize;
		return cellFrame;
    }
	return NSZeroRect;
}

- (NSRect) titleRectForBounds: (NSRect)cellFrame
{
	NSRect titleRect = [super titleRectForBounds: cellFrame];
    if (nil != icon)
	{
		titleRect.size.width -= [self imageWidth];
		titleRect.origin.x += [self imageWidth];
    }
    return titleRect;
}

- (NSSize) cellSize
{
	NSSize cellSize = [super cellSize];
    if (nil != icon)
	{
		cellSize.width += [self imageWidth];
    }
    return cellSize;
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

- (void) drawInteriorWithFrame: (NSRect)cellFrame
						inView: (NSView *)controlView
{
	if (nil != icon)
	{
		[icon drawInRect: [controlView centerScanRect: [self imageRectForBounds: cellFrame]]
				fromRect: NSZeroRect
			   operation: NSCompositeSourceOver
				fraction: 1.0
		  respectFlipped: YES
				   hints: nil];
    }
    [super drawInteriorWithFrame: [self titleRectForBounds: cellFrame]
						  inView: controlView];
}

@end
