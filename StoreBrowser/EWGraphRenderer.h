#import <Foundation/Foundation.h>
#import "COStore.h"

@interface EWGraphRenderer : NSObject
{
	NSSize size;
}

- (void) layoutGraphOfStore: (COStore*)aStore;

- (NSSize) size;
- (void) drawRect: (NSRect)aRect;

@end
