#import <UnitKit/UKRunner.h>
#import <UnitKit/UKTestHandler.h>

int main (int argc, const char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[[UKTestHandler handler] setQuiet: YES];
	
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
