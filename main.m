#import <Foundation/Foundation.h>
#import "EWTest.h"
#import "COStore.h"

static void testStore()
{
	NSString *path = [@"~/om5teststore" stringByExpandingTildeInPath];
	
	[[NSFileManager defaultManager] removeItemAtPath: path error: NULL];
	COStore *store = [[COStore alloc] initWithURL: [NSURL fileURLWithPath: path]];
	
	NSDictionary *uuidsanddata = [NSDictionary dictionaryWithObjectsAndKeys:
								  @"Hello world", [ETUUID UUID],
								  nil];
	
	NSDictionary *md = [NSDictionary dictionaryWithObjectsAndKeys: @"today", @"date", nil];
	
	ETUUID *uuid = [store addCommitWithParent: nil
									 metadata: md
							   UUIDsAndPlists: uuidsanddata];
	
	EWTestTrue(uuid != nil);
	EWTestEqual([NSArray arrayWithObject: uuid], [store allCommitUUIDs]);
	EWTestEqual(nil, [store parentForCommit: uuid]);
	EWTestEqual(md, [store metadataForCommit: uuid]);
	EWTestEqual(uuidsanddata, [store UUIDsAndPlistsForCommit: uuid]);
	
	[store setRootVersion: uuid];
	EWTestEqual(uuid, [store rootVersion]);
	
}

int main (int argc, const char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	testStore();
	
    EWTestLog();
    
    [pool drain];
    return 0;
}

