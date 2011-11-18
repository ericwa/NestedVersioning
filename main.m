#import <Foundation/Foundation.h>
#import "EWTest.h"
#import "COStore.h"
#import "COPath.h"
#import "COStoreController.h"
#import "COStoreItem.h"
#import "Common.h"

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

	NSString *pathStr = [NSString stringWithFormat: @"/%@/%@", u1, u2];
	
	COPath *path = [[[COPath path]
							pathByAppendingPersistentRoot: u1]
								pathByAppendingPersistentRoot:u2];
	
	EWTestEqual(pathStr, [path stringValue]);
	
	EWTestEqual([COPath path], [COPath path]);
	EWTestEqual(@"", [[COPath path] stringValue]);
	EWTestEqual([COPath path], [COPath pathWithString: @""]);
	
	EWTestEqual([[[COPath path]
				  pathByAppendingPersistentRoot: u1]
				 pathByAppendingPersistentRoot:u2], path);
	
	EWTestEqual(u2, [path lastPathComponent]);
	EWTestEqual(u1, [[path pathByDeletingLastPathComponent] lastPathComponent]);
	EWTestTrue(nil == [[[path pathByDeletingLastPathComponent] pathByDeletingLastPathComponent] lastPathComponent]);
	EWTestEqual([COPath path], [[path pathByDeletingLastPathComponent] pathByDeletingLastPathComponent]);
	
	EWTestEqual(path, [COPath pathWithString: pathStr]);
}

static void testStoreController()
{
	COStore *store = setupStore();
	COStoreController *sc = [[COStoreController alloc] initWithStore: store];
	
	// create some persistent roots
	
	ETUUID *obj1UUID = [ETUUID UUID];
	id obj1Plist = D(@"My First Object", @"name");
	NSDictionary *objects = D(obj1Plist, obj1UUID);
	NSDictionary *md = D(@"My first commit", @"message");
	
	[sc writeUUIDsAndPlists: objects
forPersistentRootAtPath: [COPath path]
				   metadata: md];
	
	EWTestEqual(obj1Plist, [sc plistForEmbeddedObject: obj1UUID atPath: [COPath path]]);
	
	/*
	COPath *aRoot1 = [sc createEmptyPersistentRootInsidePath: [COPath path]];
	COPath *aRoot2 = [sc createEmptyPersistentRootInsidePath: [COPath path]];
	
	COPath *aRoot1rootA = [sc createEmptyPersistentRootInsidePath: aRoot1];
	COPath *aRoot1rootB = [sc createPersistentRootCopyInsidePath: aRoot2
										  ofPersistentRootAtPath: aRoot1rootA];

	*/
}

static void testStoreItem()
{
	COStoreItem *i1 = [[COStoreItem alloc] initWithUUID: [ETUUID UUID]];
	ETUUID *u1 = [i1 uuid];
	
	COPath *p1 = [[[COPath path]
						pathByAppendingPersistentRoot:[ETUUID UUIDWithString: @"cdf68e39-8f4b-4afa-9f81-ba2f7cdf50e6"]]
						pathByAppendingPersistentRoot:[ETUUID UUIDWithString: @"8a099b84-09eb-4a3e-828d-9a897778e5e3"]];
	
	[i1 setValue: S(p1)
	forAttribute: @"contents"
			type: COConvenienceTypeUnorderedHoldingPaths()];
	
	NSLog(@"%@", [i1 plist]);
}

int main (int argc, const char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	testStore();
	testPath();
	testStoreController();
	testStoreItem();
	
    EWTestLog();
    
    [pool drain];
    return 0;
}

