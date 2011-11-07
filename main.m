#import <Foundation/Foundation.h>
#import "EWTest.h"
#import "COStore.h"

static void testStore()
{
	NSString *path = [@"~/om5teststore" stringByExpandingTildeInPath];
	
	[[NSFileManager defaultManager] removeItemAtPath: path error: NULL];
	COStore *store = [[COStore alloc] initWithURL: [NSURL fileURLWithPath: path]];
	
	NSDictionary *uuidsanddata = [NSDictionary dictionaryWithObjectsAndKeys:
								  [NSData dataWithBytes:"abc" length:3], [ETUUID UUID],
								  nil];
	
	ETUUID *uuid = [store addCommitWithParent: nil
					  metadata: [NSData dataWithBytes:"hi" length:2]
				  UUIDsAndData: uuidsanddata];
	
	EWTestTrue(uuid != nil);
	EWTestEqual([NSArray arrayWithObject: uuid], [store allCommitUUIDs]);
	EWTestEqual(nil, [store parentForCommit: uuid]);
	EWTestEqual([NSData dataWithBytes:"hi" length:2], [store metadataForCommit: uuid]);
	EWTestEqual(uuidsanddata, [store UUIDsAndDataForCommit: uuid]);
	
}

int main (int argc, const char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	testStore();
	
    EWTestLog();
    
    [pool drain];
    return 0;
}

