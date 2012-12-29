#import <Cocoa/Cocoa.h>

@interface EWIconTextFieldCell : NSTextFieldCell
{
	NSImage *icon;
}

- (NSImage *)image;
- (void) setImage: (NSImage*)anImage;

@end
