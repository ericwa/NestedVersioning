#import <UnitKit/UKRunner.h>
#import <UnitKit/UKTestHandler.h>

#import "TestCommon.h"

@implementation COSQLiteStoreTestCase

- (id) init
{
    self = [super init];
    
    [[NSFileManager defaultManager] removeItemAtPath: STOREPATH error: NULL];
    store = [[COSQLiteStore alloc] initWithURL: STOREURL];
    
    return self;
}

- (void) dealloc
{
    [store release];
    [super dealloc];
}

@end

@implementation COStoreTestCase

- (id) init
{
    self = [super init];
    
    [[NSFileManager defaultManager] removeItemAtPath: STOREPATH error: NULL];
    store = [[COStore alloc] initWithURL: STOREURL];
    
    return self;
}

- (void) dealloc
{
    [store release];
    [super dealloc];
}

@end

int main (int argc, const char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[[UKTestHandler handler] setQuiet: NO];
	
	UKRunner *runner = [UKRunner new];
	
	[runner runTestsInBundle: [NSBundle mainBundle]];
	
	// FIXME: Handle that properly in UnitKit 
    int testsPassed = [[UKTestHandler handler] testsPassed];
    int testsFailed = [[UKTestHandler handler] testsFailed];
	int exceptionsReported = [[UKTestHandler handler] exceptionsReported];
    
	printf("\nResult: %i tests, %i failed, %i exceptions\n", 
		   (testsPassed + testsFailed), testsFailed, exceptionsReported);
	
	[runner release];
    [pool drain];
    return 0;
}
