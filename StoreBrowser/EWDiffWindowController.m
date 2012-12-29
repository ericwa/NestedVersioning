#import "EWDiffWindowController.h"
#import "COPersistentRootDiff.h"

@implementation EWDiffWindowController

- (id) initWithPersistentRootDiff: (COPersistentRootDiff*)aDiff
{
	self = [super initWithWindowNibName: @"DiffWindow"];
	
	NSLog(@"proot diff: %@", aDiff);
	

	
	return self;
}


@end
