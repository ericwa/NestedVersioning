#import "TestCommon.h"

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

static void testEditingContextEmbeddedObjects()
{
	COStore *store = setupStore();
	
	//	
	// 1. set up the root context
	//	
	
	COPersistentRootEditingContext *ctx = [store rootContext];
	
	// at this point the context is empty.
	// in particular, it has no persistentRootTree, which means it contains no embedded objets.
	// this means we can't commit.
	
	EWTestTrue(nil == [ctx persistentRootTree]);
		
	COSubtree *iroot = [COSubtree subtree];
	
	[ctx setPersistentRootTree: iroot];
	
	//	
	// 2.  set up a nested persistent root
	//
	
	COSubtree *nestedDocumentRootItem = [COSubtree subtree];
	[nestedDocumentRootItem setPrimitiveValue: @"red"
						forAttribute: @"color"
								type: [COType stringType]];
	
	COSubtree *u1Tree = [ctx createPersistentRootWithRootItem: nestedDocumentRootItem
												  displayName: @"My Document"];
	[iroot addTree: u1Tree];

	
	EWTestTrue(1 == [[[COItemFactory factory] branchesOfPersistentRoot: u1Tree] count]);
	
	//
	// 2b. create another branch
	//
	
	COSubtree *u1BranchA = [[COItemFactory factory] currentBranchOfPersistentRoot: u1Tree];
	COSubtree *u1BranchB = [[COItemFactory factory] createBranchOfPersistentRoot: u1Tree];
	
	[u1BranchA setPrimitiveValue: @"Development Branch" forAttribute: @"name" type: [COType stringType]];
	[u1BranchB setPrimitiveValue: @"Stable Branch" forAttribute: @"name" type: [COType stringType]];	
	
	EWTestEqual(u1BranchA, [[COItemFactory factory] currentBranchOfPersistentRoot: u1Tree]);
	EWTestEqual(S(u1BranchA, u1BranchB), [[COItemFactory factory] branchesOfPersistentRoot: u1Tree]);
	

	[[COItemFactory factory] setCurrentBranch: u1BranchB
							forPersistentRoot: u1Tree];
	
	EWTestEqual(u1BranchB, [[COItemFactory factory] currentBranchOfPersistentRoot: u1Tree]);
	
	[[COItemFactory factory] setCurrentBranch: u1BranchA
							forPersistentRoot: u1Tree];

	EWTestEqual(u1BranchA, [[COItemFactory factory] currentBranchOfPersistentRoot: u1Tree]);

	//
	// 2c. create another persistent root containing a copy of u1BranchB
	//
	
	COSubtree *u2 = [[COItemFactory factory] persistentRootByCopyingBranch:  u1BranchB];
	[iroot addTree: u2];
	
	//
	// 2d. commit changes
	//
	
	ETUUID *firstVersion = [ctx commitWithMetadata: nil];
	EWTestTrue(firstVersion != nil);
	EWTestEqual(firstVersion, [store rootVersion]);

	
	//
	// 3. Now open an embedded context on the document
	//

	COPersistentRootEditingContext *ctx2 = [ctx editingContextForEditingEmbdeddedPersistentRoot: u1Tree];
	EWTestTrue(nil != ctx2);
	EWTestEqual([nestedDocumentRootItem UUID], [[ctx2 persistentRootTree] UUID]);
	
	//
	// 4. Try making a commit in the document
	//
	
	COSubtree *nestedDocCtx2 = [ctx2 persistentRootTree];
	//EWTestEqual(nestedDocumentRootItem, nestedDocCtx2);
	
	[nestedDocCtx2 setPrimitiveValue: @"green"
						forAttribute: @"color"
								type: [COType stringType]];
	
	ETUUID *commitInNestedDocCtx2 = [ctx2 commitWithMetadata: nil];
	
	EWTestTrue(nil != commitInNestedDocCtx2);

	
	//
	// 5. Reopen store and check that we read back the same data
	//
	
	[store release];
	
	
	COStore *store2 = [[COStore alloc] initWithURL: [NSURL fileURLWithPath: STOREPATH]];
	
	COPersistentRootEditingContext *testctx1 = [store2 rootContext];
	
	u1Tree = [[testctx1 persistentRootTree] subtreeWithUUID: [u1Tree UUID]];
	u1BranchB = [[testctx1 persistentRootTree] subtreeWithUUID: [u1BranchB  UUID]];
	u2 = [[testctx1 persistentRootTree] subtreeWithUUID: [u2 UUID]];
	
	{
		COPersistentRootEditingContext *testctx2 = [testctx1 editingContextForEditingEmbdeddedPersistentRoot: u1Tree];
		
		COSubtree *item = [testctx2 persistentRootTree];
		EWTestEqual(@"green", [item valueForAttribute: @"color"]);
		EWTestEqual(nestedDocCtx2, item);
	}
	
	{
		COPersistentRootEditingContext *testctx2 = [testctx1 editingContextForEditingBranchOfPersistentRoot: u1BranchB];
		COSubtree *item = [testctx2 persistentRootTree];
		EWTestEqual(@"red", [item valueForAttribute: @"color"]);
		//EWTestEqual(nestedDocumentRootItem, item);
	}

	{
		COPersistentRootEditingContext *testctx2 = [testctx1 editingContextForEditingEmbdeddedPersistentRoot: u2];
		COSubtree *item = [testctx2 persistentRootTree];
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
	WITH_POOL(testSubtree());
	WITH_POOL(testEditingContextEmbeddedObjects());
	WITH_POOL(testStoreItem());
	WITH_POOL(testUndo());
	WITH_POOL(testTagging());
	WITH_POOL(testDiff());
	
    WITH_POOL(EWTestLog());
    
    return 0;
}

