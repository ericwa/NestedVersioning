#import "TestCommon.h"

COStore *setupStore()
{
	[[NSFileManager defaultManager] removeItemAtPath: STOREPATH error: NULL];
	return [[COStore alloc] initWithURL: [NSURL fileURLWithPath: STOREPATH]];
}

static void testStore()
{
	COStore *store = setupStore();
	
	COItem *i1 = [[[COItem alloc] initWithUUID: [ETUUID UUID]
									  typesForAttributes: D([COType stringType], @"name")
									 valuesForAttributes: D(@"hello", @"name")] autorelease];
	
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
	
	[store release];
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

static void testStoreItemTree()
{
	COItemTreeNode *t1 = [COItemTreeNode itemTree];
	COItemTreeNode *t2 = [COItemTreeNode itemTree];	
	COItemTreeNode *t3 = [COItemTreeNode itemTree];
	
	EWTestTrue(nil == [t2 parent]);
	EWTestTrue(t2 == [t2 root]);
	
	[t1 addTree: t2];
	
	EWTestTrue(t1 == [t2 parent]);	
	EWTestTrue(t1 == [t2 root]);
	EWTestTrue(nil == [t1 parent]);	
	EWTestTrue(t1 == [t1 root]);
	
	[t2 addTree: t3];
	
	EWTestTrue(t2 == [t3 parent]);
	
	EWTestIntsEqual(3, [[t1 allContainedStoreItems] count]);
	
	COItemTreeNode *t1a = [[t1 copy] autorelease];
	EWTestEqual(t1, t1a);
	
	COItemTreeNode *t2a = [[t1a contents] anyObject];
	EWTestEqual(t2, t2a);
	
	COItemTreeNode *t3b = [COItemTreeNode itemTree];
	[t2a addTree: t3b];
	
	EWTestTrue(![t1 isEqual: t1a]);
	EWTestTrue(![t2 isEqual: t2a]);
	
	[t2a removeTree: t3b];
	
	EWTestEqual(t1, t1a);
	EWTestEqual(t2, t2a);	
	
	EWTestTrue(t1a == [t2a parent]);
	
	
	// test moving an item to a new tree removes it from its old parent
	
	[t1 addTree: t2a];
	
	EWTestTrue(t1 == [t2a parent]);
	EWTestIntsEqual(4, [[t1 allContainedStoreItems] count]);
	EWTestIntsEqual(1, [[t1a allContainedStoreItems] count]);	
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
		
	COMutableItem *iroot = [COMutableItem item];
	ETUUID *uroot = [iroot UUID];
	
	[ctx _insertOrUpdateItems: S(iroot)
		newRootEmbeddedObject: uroot];
	
	EWTestEqual(uroot, [ctx rootUUID]);
	
	//	
	// 2.  set up a nested persistent root
	//
	
	COItemTreeNode *nestedDocumentRootItem = [COItemTreeNode itemTree];
	[nestedDocumentRootItem setValue: @"red"
						forAttribute: @"color"
								type: [COType stringType]];
	
	ETUUID *u1 = [ctx createAndInsertNewPersistentRootWithRootItem: nestedDocumentRootItem
													inItemWithUUID: uroot];

	
	EWTestTrue(1 == [[ctx branchesOfPersistentRoot: u1] count]);
	
	//
	// 2b. create another branch
	//
	
	ETUUID *u1BranchA = [ctx currentBranchOfPersistentRoot: u1];
	ETUUID *u1BranchB = [ctx createBranchOfPersistentRoot: u1];
	
	{
		COMutableItem *u1BranchAItem = [ctx _storeItemForUUID: u1BranchA];
		[u1BranchAItem setValue: @"Development Branch" forAttribute: @"name" type: [COType stringType]];
		[ctx _insertOrUpdateItems: S(u1BranchAItem)];
	}
	{
		COMutableItem *u1BranchBItem = [ctx _storeItemForUUID: u1BranchB];
		[u1BranchBItem setValue: @"Stable Branch" forAttribute: @"name" type: [COType stringType]];
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
	

	COMutableItem *nestedDocCtx2 = [ctx2 _storeItemForUUID: [nestedDocumentRootItem UUID]];
	//EWTestEqual(nestedDocumentRootItem, nestedDocCtx2);
	
	[nestedDocCtx2 setValue: @"green"
			   forAttribute: @"color"
					   type: [COType stringType]];
	
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
		
		COMutableItem *item = [testctx2 _storeItemForUUID: [testctx2 rootUUID]];
		EWTestEqual(@"green", [item valueForAttribute: @"color"]);
		EWTestEqual(nestedDocCtx2, item);
	}
	
	{
		COPersistentRootEditingContext *testctx2 = [testctx1 editingContextForEditingEmbdeddedPersistentRoot: u1
																						 onBranch: u1BranchB];
		COMutableItem *item = [testctx2 _storeItemForUUID: [testctx2 rootUUID]];
		EWTestEqual(@"red", [item valueForAttribute: @"color"]);
		//EWTestEqual(nestedDocumentRootItem, item);
	}

	{
		COPersistentRootEditingContext *testctx2 = [testctx1 editingContextForEditingEmbdeddedPersistentRoot: u2];
		COMutableItem *item = [testctx2 _storeItemForUUID: [testctx2 rootUUID]];
		EWTestEqual(@"red", [item valueForAttribute: @"color"]);
		//EWTestEqual(nestedDocumentRootItem, item);
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
	COMutableItem *i1 = [COMutableItem item];
	
	COPath *p1 = [[[COPath path]
						pathByAppendingPathComponent:[ETUUID UUIDWithString: @"cdf68e39-8f4b-4afa-9f81-ba2f7cdf50e6"]]
						pathByAppendingPathComponent:[ETUUID UUIDWithString: @"8a099b84-09eb-4a3e-828d-9a897778e5e3"]];
	
	[i1 setValue: S(p1)
	forAttribute: @"contents"
			type: [COType setWithPrimitiveType: [COType pathType]]];
	
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
		COMutableItem *i1clone = [[[COMutableItem alloc] initWithPlist: plist] autorelease];
		EWTestEqual(i1, i1clone);
	}
}

static void testDiff()
{
	COItem *i1 = [[[COItem alloc] initWithUUID: [ETUUID UUID]
									  typesForAttributes: D([COType stringType], @"type",
															[COType setWithPrimitiveType: [COType stringType]], @"places")
									 valuesForAttributes: D(@"test", @"type",
															S(@"home"), @"places")] autorelease];

																   
	COItem *i2 = [[[COItem alloc] initWithUUID: [ETUUID UUID]
									  typesForAttributes: D([COType stringType], @"name",
															[COType setWithPrimitiveType: [COType stringType]], @"places")
									 valuesForAttributes: D(@"hello", @"name",
															S(@"work", @"home"), @"places")] autorelease];

	COItemDiff *diff = [COItemDiff diffItem: i1 withItem: i2];
	COItem *i2_fromDiff = [diff itemWithDiffAppliedTo: i1];
	
	EWTestEqual(i2, i2_fromDiff);
}

#define WITH_POOL(x) {NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; x; [pool release];}

int main (int argc, const char * argv[])
{
	WITH_POOL(testStore());
	WITH_POOL(testPath());
	WITH_POOL(testStoreItemTree());
	//WITH_POOL(testStoreController());
	WITH_POOL(testEditingContextEmbeddedObjects());
	WITH_POOL(testStoreItem());
	WITH_POOL(testUndo());
	WITH_POOL(testTagging());
	WITH_POOL(testDiff());
	WITH_POOL(testTreeManager());
	
    WITH_POOL(EWTestLog());
    
    return 0;
}

