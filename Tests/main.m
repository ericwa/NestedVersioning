#import "TestCommon.h"

COStore *setupStore()
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
	ETUUID *u3 = [ETUUID UUIDWithString: @"5764ce91-3061-4289-b7d8-7e9f4c1cd975"];
	
	NSString *pathStr = [NSString stringWithFormat: @"%@/%@", u1, u2];
	
	COPath *path = [[[COPath path]
							pathByAppendingPathComponent: u1]
								pathByAppendingPathComponent:u2];
	
	EWTestEqual(pathStr, [path stringValue]);
	
	EWTestEqual([COPath path], [COPath path]);
	EWTestEqual(@"", [[COPath path] stringValue]);
	EWTestEqual([COPath path], [COPath pathWithString: @""]);
	
	EWTestEqual([[[COPath path]
				  pathByAppendingPathComponent: u1]
					pathByAppendingPathComponent:u2], path);
	
	EWTestEqual(u2, [path lastPathComponent]);
	EWTestEqual(u1, [[path pathByDeletingLastPathComponent] lastPathComponent]);
	EWTestTrue(nil == [[[path pathByDeletingLastPathComponent] pathByDeletingLastPathComponent] lastPathComponent]);
	EWTestEqual([COPath path], [[path pathByDeletingLastPathComponent] pathByDeletingLastPathComponent]);
	
	EWTestEqual(path, [COPath pathWithString: pathStr]);
	
	// test pathToParent
	
	COPath *path2 = [[COPath path] pathByAppendingPathToParent];
	COPath *path3a = [path2 pathByAppendingPath: path2];
	COPath *path3b = [[[COPath path] pathByAppendingPathToParent] pathByAppendingPathToParent];
	COPath *path4 = [[[[COPath path] pathByAppendingPathToParent] pathByAppendingPathToParent] pathByAppendingPathComponent: u3];
	COPath *path5 = [[[COPath path] pathByAppendingPathToParent] pathByAppendingPathComponent: u3];
	
	EWTestEqual(path3b, path3a);
	
	EWTestTrue([path2 hasLeadingPathsToParent]);
	EWTestTrue(![path2 isEmpty]);
	EWTestTrue(![path2 hasComponents]);
	
	EWTestEqual([[COPath path] pathByAppendingPathComponent: u1], [path pathByAppendingPath: path2]);
	EWTestEqual([COPath path], [path pathByAppendingPath: path3a]);
	EWTestEqual([COPath path], [path pathByAppendingPath: path3b]);
	EWTestEqual([COPath pathWithPathComponent: u3], [path pathByAppendingPath: path4]);
	EWTestEqual([[COPath pathWithPathComponent: u1] pathByAppendingPathComponent: u3], [path pathByAppendingPath: path5]);	
}

static void testEditingContextEmbeddedObjects()
{
	COStore *store = setupStore();
	
	//	
	// 1. set up the root context
	//	
	
	COPersistentRootEditingContext *ctx = [store rootContext];
	
	// at this point the context is empty.
	// in particular, it has no rootEmbeddedObject, which means it contains no embedded objets.
	// this means we can't commit.
	
	EWTestTrue(nil == [ctx rootUUID]);
	EWTestTrue(nil == [store rootVersion]);
		
	COStoreItem *iroot = [COStoreItem item];
	ETUUID *uroot = [iroot UUID];
	
	[ctx _insertOrUpdateItems: S(iroot)
		newRootEmbeddedObject: uroot];
	
	EWTestEqual(uroot, [ctx rootUUID]);
	
	//	
	// 2.  set up a nested persistent root
	//
	
	COStoreItem *nestedDocumentRootItem = [COStoreItem item];
	[nestedDocumentRootItem setValue: @"red"
						forAttribute: @"color"
								type: COPrimitiveType(kCOPrimitiveTypeString)];
	
	ETUUID *u1 = [ctx createAndInsertNewPersistentRootWithRootItem: nestedDocumentRootItem
													inItemWithUUID: uroot];

	
	EWTestTrue(1 == [[ctx branchesOfPersistentRoot: u1] count]);
	
	//
	// 2b. create another branch
	//
	
	ETUUID *u1BranchA = [ctx currentBranchOfPersistentRoot: u1];
	ETUUID *u1BranchB = [ctx createBranchOfPersistentRoot: u1];
	
	{
		COStoreItem *u1BranchAItem = [ctx _storeItemForUUID: u1BranchA];
		[u1BranchAItem setValue: @"Development Branch" forAttribute: @"name" type: COPrimitiveType(kCOPrimitiveTypeString)];
		[ctx _insertOrUpdateItems: S(u1BranchAItem)];
	}
	{
		COStoreItem *u1BranchBItem = [ctx _storeItemForUUID: u1BranchB];
		[u1BranchBItem setValue: @"Stable Branch" forAttribute: @"name" type: COPrimitiveType(kCOPrimitiveTypeString)];
		[ctx _insertOrUpdateItems: S(u1BranchBItem)];
	}
	
	
	EWTestEqual(u1BranchA, [ctx currentBranchOfPersistentRoot: u1]);
	EWTestEqual(S(u1BranchA, u1BranchB), [ctx branchesOfPersistentRoot: u1]);
	
	
	[ctx setCurrentBranch: u1BranchB
		forPersistentRoot: u1];
	
	EWTestEqual(u1BranchB, [ctx currentBranchOfPersistentRoot: u1]);
	
	[ctx setCurrentBranch: u1BranchA
		forPersistentRoot: u1];

	EWTestEqual(u1BranchA, [ctx currentBranchOfPersistentRoot: u1]);

	//
	// 2c. create another persistent root containing a copy of u1BranchB
	//
	
	ETUUID *u2 = [ctx createAndInsertNewPersistentRootByCopyingBranch: u1BranchB
													   inItemWithUUID: uroot];
	
	//
	// 2d. commit changes
	//
	
	ETUUID *firstVersion = [ctx commitWithMetadata: nil];
	EWTestTrue(firstVersion != nil);
	EWTestEqual(firstVersion, [store rootVersion]);

	
	//
	// 3. Now open an embedded context on the document
	//

	COPersistentRootEditingContext *ctx2 = [ctx editingContextForEditingEmbdeddedPersistentRoot: u1];
	EWTestTrue(nil != ctx2);
	EWTestEqual([nestedDocumentRootItem UUID], [ctx2 rootUUID]);
	
	//
	// 4. Try making a commit in the document
	//
	

	COStoreItem *nestedDocCtx2 = [ctx2 _storeItemForUUID: [nestedDocumentRootItem UUID]];
	EWTestEqual(nestedDocumentRootItem, nestedDocCtx2);
	
	[nestedDocCtx2 setValue: @"green"
			   forAttribute: @"color"
					   type: COPrimitiveType(kCOPrimitiveTypeString)];
	
	[ctx2 _insertOrUpdateItems: S(nestedDocCtx2)];
	
	ETUUID *commitInNestedDocCtx2 = [ctx2 commitWithMetadata: nil];
	
	EWTestTrue(nil != commitInNestedDocCtx2);

	
	//
	// 5. Reopen store and check that we read back the same data
	//
	
	[store release];
	
	
	COStore *store2 = [[COStore alloc] initWithURL: [NSURL fileURLWithPath: STOREPATH]];
	
	COPersistentRootEditingContext *testctx1 = [store2 rootContext];
	
	{
		COPersistentRootEditingContext *testctx2 = [testctx1 editingContextForEditingEmbdeddedPersistentRoot: u1];
		
		COStoreItem *item = [testctx2 _storeItemForUUID: [testctx2 rootUUID]];
		EWTestEqual(@"green", [item valueForAttribute: @"color"]);
		EWTestEqual(nestedDocCtx2, item);
	}
	
	{
		COPersistentRootEditingContext *testctx2 = [testctx1 editingContextForEditingEmbdeddedPersistentRoot: u1
																						 onBranch: u1BranchB];
		COStoreItem *item = [testctx2 _storeItemForUUID: [testctx2 rootUUID]];
		EWTestEqual(@"red", [item valueForAttribute: @"color"]);
		EWTestEqual(nestedDocumentRootItem, item);
	}

	{
		COPersistentRootEditingContext *testctx2 = [testctx1 editingContextForEditingEmbdeddedPersistentRoot: u2];
		COStoreItem *item = [testctx2 _storeItemForUUID: [testctx2 rootUUID]];
		EWTestEqual(@"red", [item valueForAttribute: @"color"]);
		EWTestEqual(nestedDocumentRootItem, item);
	}

		
	//
	// 6. GC the store
	// 
	
	NSUInteger commitsBefore = [[store2 allCommitUUIDs] count];
	[store2 gc];
	NSUInteger commitsAfter = [[store2 allCommitUUIDs] count];
	EWTestTrue(commitsAfter < commitsBefore);
	
	
	[store2 release];	
}

static void testStoreItem()
{
	COStoreItem *i1 = [COStoreItem item];
	
	COPath *p1 = [[[COPath path]
						pathByAppendingPathComponent:[ETUUID UUIDWithString: @"cdf68e39-8f4b-4afa-9f81-ba2f7cdf50e6"]]
						pathByAppendingPathComponent:[ETUUID UUIDWithString: @"8a099b84-09eb-4a3e-828d-9a897778e5e3"]];
	
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
	testUndo();
	
    EWTestLog();
    
    [pool drain];
    return 0;
}

