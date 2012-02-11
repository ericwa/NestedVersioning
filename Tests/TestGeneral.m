#import "TestCommon.h"

@interface TestGeneral : NSObject <UKTest> {
	
}

@end

@implementation  TestGeneral

- (void) testStore
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
	
	UKTrue(uuid != nil);
	UKObjectsEqual([NSArray arrayWithObject: uuid], [store allCommitUUIDs]);
	UKNil([store parentForCommit: uuid]);
	UKObjectsEqual(md, [store metadataForCommit: uuid]);
	UKObjectsEqual(uuidsanditems, [store UUIDsAndStoreItemsForCommit: uuid]);
	UKObjectsEqual([i1 UUID], [store rootItemForCommit: uuid]);
	
	[store setRootVersion: uuid];
	UKObjectsEqual(uuid, [store rootVersion]);
	
	[store release];
}

- (void) testPath
{
	ETUUID *u1 = [ETUUID UUIDWithString: @"cdf68e39-8f4b-4afa-9f81-ba2f7cdf50e6"];
	ETUUID *u2 = [ETUUID UUIDWithString: @"8a099b84-09eb-4a3e-828d-9a897778e5e3"];
	ETUUID *u3 = [ETUUID UUIDWithString: @"5764ce91-3061-4289-b7d8-7e9f4c1cd975"];
	
	NSString *pathStr = [NSString stringWithFormat: @"%@/%@", u1, u2];
	
	COPath *path = [[[COPath path]
					 pathByAppendingPathComponent: u1]
					pathByAppendingPathComponent:u2];
	
	UKStringsEqual(pathStr, [path stringValue]);
	
	UKObjectsEqual([COPath path], [COPath path]);
	UKStringsEqual(@"", [[COPath path] stringValue]);
	UKObjectsEqual([COPath path], [COPath pathWithString: @""]);
	
	UKObjectsEqual([[[COPath path]
				  pathByAppendingPathComponent: u1]
				 pathByAppendingPathComponent:u2], path);
	
	UKObjectsEqual(u2, [path lastPathComponent]);
	UKObjectsEqual(u1, [[path pathByDeletingLastPathComponent] lastPathComponent]);
	UKNil([[[path pathByDeletingLastPathComponent] pathByDeletingLastPathComponent] lastPathComponent]);
	UKObjectsEqual([COPath path], [[path pathByDeletingLastPathComponent] pathByDeletingLastPathComponent]);
	
	UKObjectsEqual(path, [COPath pathWithString: pathStr]);
	
	// test pathToParent
	
	COPath *path2 = [[COPath path] pathByAppendingPathToParent];
	COPath *path3a = [path2 pathByAppendingPath: path2];
	COPath *path3b = [[[COPath path] pathByAppendingPathToParent] pathByAppendingPathToParent];
	COPath *path4 = [[[[COPath path] pathByAppendingPathToParent] pathByAppendingPathToParent] pathByAppendingPathComponent: u3];
	COPath *path5 = [[[COPath path] pathByAppendingPathToParent] pathByAppendingPathComponent: u3];
	
	UKObjectsEqual(path3b, path3a);
	
	UKTrue([path2 hasLeadingPathsToParent]);
	UKFalse([path2 isEmpty]);
	UKFalse([path2 hasComponents]);
	
	UKObjectsEqual([[COPath path] pathByAppendingPathComponent: u1], [path pathByAppendingPath: path2]);
	UKObjectsEqual([COPath path], [path pathByAppendingPath: path3a]);
	UKObjectsEqual([COPath path], [path pathByAppendingPath: path3b]);
	UKObjectsEqual([COPath pathWithPathComponent: u3], [path pathByAppendingPath: path4]);
	UKObjectsEqual([[COPath pathWithPathComponent: u1] pathByAppendingPathComponent: u3], [path pathByAppendingPath: path5]);	
}

- (void) testEditingContextEmbeddedObjects
{
	COStore *store = setupStore();
	
	//	
	// 1. set up the root context
	//	
	
	COPersistentRootEditingContext *ctx = [store rootContext];
	
	// at this point the context is empty.
	// in particular, it has no persistentRootTree, which means it contains no embedded objets.
	// this means we can't commit.
	
	UKNil([ctx persistentRootTree]);
	
	COSubtree *iroot = [COSubtree subtree];
	
	[ctx setPersistentRootTree: iroot];
	
	//	
	// 2.  set up a nested persistent root
	//
	
	COSubtree *nestedDocumentRootItem = [COSubtree subtree];
	[nestedDocumentRootItem setPrimitiveValue: @"red"
								 forAttribute: @"color"
										 type: [COType stringType]];
	
	COSubtree *u1Tree = [[COSubtreeFactory factory] createPersistentRootWithRootItem: nestedDocumentRootItem
																		 displayName: @"My Document"
																			   store: store];
	[iroot addTree: u1Tree];
	
	
	UKIntsEqual(1, [[[COSubtreeFactory factory] branchesOfPersistentRoot: u1Tree] count]);
	
	//
	// 2b. create another branch
	//
	
	COSubtree *u1BranchA = [[COSubtreeFactory factory] currentBranchOfPersistentRoot: u1Tree];
	COSubtree *u1BranchB = [[COSubtreeFactory factory] createBranchOfPersistentRoot: u1Tree];
	
	[u1BranchA setPrimitiveValue: @"Development Branch" forAttribute: @"name" type: [COType stringType]];
	[u1BranchB setPrimitiveValue: @"Stable Branch" forAttribute: @"name" type: [COType stringType]];	
	
	UKObjectsEqual(u1BranchA, [[COSubtreeFactory factory] currentBranchOfPersistentRoot: u1Tree]);
	UKObjectsEqual(S(u1BranchA, u1BranchB), [[COSubtreeFactory factory] branchesOfPersistentRoot: u1Tree]);
	
	
	[[COSubtreeFactory factory] setCurrentBranch: u1BranchB
							   forPersistentRoot: u1Tree];
	
	UKObjectsEqual(u1BranchB, [[COSubtreeFactory factory] currentBranchOfPersistentRoot: u1Tree]);
	
	[[COSubtreeFactory factory] setCurrentBranch: u1BranchA
							   forPersistentRoot: u1Tree];
	
	UKObjectsEqual(u1BranchA, [[COSubtreeFactory factory] currentBranchOfPersistentRoot: u1Tree]);
	
	//
	// 2c. create another persistent root containing a copy of u1BranchB
	//
	
	COSubtree *u2 = [[COSubtreeFactory factory] persistentRootByCopyingBranch:  u1BranchB];
	[iroot addTree: u2];
	
	//
	// 2d. commit changes
	//
	
	ETUUID *firstVersion = [ctx commitWithMetadata: nil];
	UKNotNil(firstVersion);
	UKObjectsEqual(firstVersion, [store rootVersion]);
	
	
	//
	// 3. Now open an embedded context on the document
	//
	
	COPersistentRootEditingContext *ctx2 = [ctx editingContextForEditingEmbdeddedPersistentRoot: u1Tree];
	UKNotNil(ctx2);
	UKObjectsEqual([nestedDocumentRootItem UUID], [[ctx2 persistentRootTree] UUID]);
	
	//
	// 4. Try making a commit in the document
	//
	
	COSubtree *nestedDocCtx2 = [ctx2 persistentRootTree];
	//UKObjectsEqual(nestedDocumentRootItem, nestedDocCtx2);
	
	[nestedDocCtx2 setPrimitiveValue: @"green"
						forAttribute: @"color"
								type: [COType stringType]];
	
	ETUUID *commitInNestedDocCtx2 = [ctx2 commitWithMetadata: nil];
	
	UKNotNil(commitInNestedDocCtx2);
	
	
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
		UKStringsEqual(@"green", [item valueForAttribute: @"color"]);
		UKObjectsEqual(nestedDocCtx2, item);
	}
	
	{
		COPersistentRootEditingContext *testctx2 = [testctx1 editingContextForEditingBranchOfPersistentRoot: u1BranchB];
		COSubtree *item = [testctx2 persistentRootTree];
		UKStringsEqual(@"red", [item valueForAttribute: @"color"]);
		//UKObjectsEqual(nestedDocumentRootItem, item);
	}
	
	{
		COPersistentRootEditingContext *testctx2 = [testctx1 editingContextForEditingEmbdeddedPersistentRoot: u2];
		COSubtree *item = [testctx2 persistentRootTree];
		UKStringsEqual(@"red", [item valueForAttribute: @"color"]);
		//UKObjectsEqual(nestedDocumentRootItem, item);
	}
	
	
	//
	// 6. GC the store
	// 
	
	NSUInteger commitsBefore = [[store2 allCommitUUIDs] count];
	[store2 gc];
	NSUInteger commitsAfter = [[store2 allCommitUUIDs] count];
	UKTrue(commitsAfter < commitsBefore);
	
	
	[store2 release];	
}

- (void) testStoreItem
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
		UKObjectsEqual(i1, i1clone);
	}
}

- (void) testDiff
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
	
	UKObjectsEqual(i2, i2_fromDiff);
}

@end