#import <Foundation/Foundation.h>
#import "EWTest.h"
#import "COStore.h"
#import "COPath.h"
#import "COStoreItem.h"
#import "COStorePrivate.h"
#import "COEditingContext.h"
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
	
	COStoreItem *i1 = [COStoreItem item];
	[i1 setValue: @"hello" forAttribute: @"name" type: COPrimitiveType(kCOPrimitiveTypeString)];
	
	NSDictionary *uuidsanditems = [NSDictionary dictionaryWithObjectsAndKeys:
								  i1, [i1 UUID],
								  nil];
	
	NSDictionary *md = [NSDictionary dictionaryWithObjectsAndKeys: @"today", @"date", nil];
	
	ETUUID *uuid = [store addCommitWithParent: nil
									 metadata: md
						   UUIDsAndStoreItems: uuidsanditems
									 rootItem: [i1 UUID]];
	
	EWTestTrue(uuid != nil);
	EWTestEqual([NSArray arrayWithObject: uuid], [store allCommitUUIDs]);
	EWTestEqual(nil, [store parentForCommit: uuid]);
	EWTestEqual(md, [store metadataForCommit: uuid]);
	EWTestEqual(uuidsanditems, [store UUIDsAndStoreItemsForCommit: uuid]);
	EWTestEqual([i1 UUID], [store rootItemForCommit: uuid]);
	
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

static void testEditingContextEmbeddedObjects()
{
	COStore *store = setupStore();
	id<COEditingContext> ctx = [store rootContext];
	
	// at this point the context is empty.
	// in particular, it has no rootEmbeddedObject, which means it contains no embedded objets.
	// this means we can't commit.
	
	EWTestTrue(nil == [ctx rootEmbeddedObject]);
	EWTestTrue(nil == [store rootVersion]);
	
	COStoreItem *i1 = [COStoreItem item];
	COStoreItem *i2 = [COStoreItem item];
	
	[i1 setValue: @"hello"
	forAttribute: @"name"
			type: COPrimitiveType(kCOPrimitiveTypeString)];
	
	[i1 setValue: S([i2 UUID])
	forAttribute: @"contents"
			type: COSetContainerType(kCOPrimitiveTypeEmbeddedItem)];
	
	[i2 setValue: @"world"
	forAttribute: @"name"
			type: COPrimitiveType(kCOPrimitiveTypeString)];
	
	[ctx insertOrUpdateItems: S(i1, i2)
	   newRootEmbeddedObject: [i1 UUID]];
	
	EWTestEqual([i1 UUID], [ctx rootEmbeddedObject]);
	EWTestEqual(S([i1 UUID], [i2 UUID]),
				[ctx allEmbeddedObjectUUIDsForUUIDInclusive: [i1 UUID]]);	
	
	ETUUID *firstVersion = [ctx commit];
	EWTestTrue(firstVersion != nil);
	
	// test reading back the items
	
	EWTestEqual(i1, [ctx storeItemForUUID: [i1 UUID]]);
	EWTestEqual(i2, [ctx storeItemForUUID: [i2 UUID]]);
}

static void testStoreItem()
{
	COStoreItem *i1 = [COStoreItem item];
	ETUUID *u1 = [i1 UUID];
	
	COPath *p1 = [[[COPath path]
						pathByAppendingPersistentRoot:[ETUUID UUIDWithString: @"cdf68e39-8f4b-4afa-9f81-ba2f7cdf50e6"]]
						pathByAppendingPersistentRoot:[ETUUID UUIDWithString: @"8a099b84-09eb-4a3e-828d-9a897778e5e3"]];
	
	[i1 setValue: S(p1)
	forAttribute: @"contents"
			type: COSetContainerType(kCOPrimitiveTypePath)];
	
	NSLog(@"%@", [i1 plist]);
	
	// test round trip to plist
	{
		id plist = [NSPropertyListSerialization propertyListFromData:
			[NSPropertyListSerialization dataFromPropertyList: [i1 plist]
														format:NSPropertyListXMLFormat_v1_0
															   errorDescription:NULL]
				 mutabilityOption: NSPropertyListMutableContainersAndLeaves
			format: NULL
			errorDescription:NULL];
		COStoreItem *i1clone = [[[COStoreItem alloc] initWithPlist: plist] autorelease];
		EWTestEqual(i1, i1clone);
	}
}

int main (int argc, const char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	testStore();
	testPath();
	//testStoreController();
	testEditingContextEmbeddedObjects();
	testStoreItem();
	
    EWTestLog();
    
    [pool drain];
    return 0;
}

