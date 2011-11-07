#import <Foundation/Foundation.h>
#import "EWTest.h"
#import "COStore.h"
#import "COPath.h"
#import "COStoreController.h"


#define STOREPATH [@"~/om5teststore" stringByExpandingTildeInPath]

static COStore *setupStore()
{
	[[NSFileManager defaultManager] removeItemAtPath: STOREPATH error: NULL];
	return [[COStore alloc] initWithURL: [NSURL fileURLWithPath: STOREPATH]];
}

static void testStore()
{
	COStore *store = setupStore();
	
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

static void testPath()
{
	ETUUID *u1 = [ETUUID UUIDWithString: @"cdf68e39-8f4b-4afa-9f81-ba2f7cdf50e6"];
	ETUUID *u2 = [ETUUID UUIDWithString: @"8a099b84-09eb-4a3e-828d-9a897778e5e3"];
	ETUUID *u3 = [ETUUID UUIDWithString: @"4385cb13-4dcb-429c-b197-0f067efa232e"];
	ETUUID *u4 = [ETUUID UUIDWithString: @"c010d730-6a50-4f50-b11a-2e6187d212b2"];
	ETUUID *u5 = [ETUUID UUIDWithString: @"a35de0a8-ce7b-48cd-8355-666647592abf"];
	
	NSString *pathStr = [NSString stringWithFormat: @"/%@/%@:%@/%@@%@", u1, u2, u3, u4, u5];
	
	COPath *path = [[[[COPath path]
						pathByAppendingPathToCurrentVersionOfPersistentRoot: u1]
							pathByAppendingPathToCurrentVersionOfPersistentRoot:u2 atBranchUUID: u3]
								pathByAppendingPathToPersistentRoot:u4 atVersion:u5];
	
	EWTestEqual(pathStr, [path stringValue]);
}

static void testStoreController()
{
	COStore *store = setupStore();
	COStoreController *sc = [[COStoreController alloc] initWithStore: store];
}

int main (int argc, const char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	testStore();
	testPath();
	testStoreController();
	
    EWTestLog();
    
    [pool drain];
    return 0;
}

