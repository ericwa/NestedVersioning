#import "COStore.h"
#import "FMDatabase.h"
#import "Common.h"

@interface COStore (Private)

@end


@implementation COStore

- (id)initWithURL: (NSURL*)aURL
{
	self = [super init];
	url = [aURL retain];
	
	return self;
}

- (void)dealloc
{
	[url release];
	[super dealloc];
}

- (NSURL*)URL
{
	return url;
}

@end
