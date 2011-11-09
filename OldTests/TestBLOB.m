#import <Foundation/Foundation.h>

#define TESTPATH [@"~/om5testdir" stringByExpandingTildeInPath]
#define PHOTOFILE [TESTPATH stringByAppendingPathComponent: @"photo"]
#define VIDEOFILE [TESTPATH stringByAppendingPathComponent: @"video"]

static void setupTest()
{
	[[NSFileManager defaultManager] removeItemAtPath: TESTPATH error: NULL];
	[[NSFileManager defaultManager] createDirectoryAtPath: TESTPATH
							  withIntermediateDirectories: YES
											   attributes: nil
													error: NULL];
	
	[[@"pretend this is a 10mb photo" dataUsingEncoding: NSUTF8StringEncoding]
		writeToFile: PHOTOFILE atomically: NO];
	[[@"pretend this is a 5gb video" dataUsingEncoding: NSUTF8StringEncoding]
		writeToFile: VIDEOFILE atomically: NO];
}

void test()
{



}
