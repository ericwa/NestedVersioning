#if 0

void test()
{
	/**
	 
	 we test the equivelance of branches and copies.
	 
	 branching is just a thin user interface for 'grouping' copies.
	 
	 note that it would be best for some properties of the object 
	 (e.g., name) to live outside the branches and directly in the persistent root
	 
	 
	 When you copy an object, it needs to be independent from the source.
	 Other than that, you should be able to:
	 
	 - view where the copy came from (optionally hide-able)
	 - merge in changes from where the copy came from.
	 
	 **/

	
	// create a persistent root r with 3 branches: a, b, c; current branch: a
	
	COEditingContext *ctx = SetupTestContext();
	
	COStore *store = [ctx store];
	
	ETUUID *emptyVersion = [store addCommitWithParent: nil
											 metadata: nil
								   UUIDsAndStoreItems: [NSDictionary dictionary]];
	
	ETUUID *r1b1 = [ctx newBranchTrackingVersion: emptyVersion];
	ETUUID *r1b2 = [ctx newBranchTrackingVersion: emptyVersion];
	ETUUID *r1b3 = [ctx newBranchTrackingVersion: emptyVersion];
	
	ETUUID *r1 = [ctx newBranchGroupWithBranches: A(r1b1, r1b2, r1b3)];


	
	// copy r -> r' (a', b', c'), current branch: a'

	ETUUID *r2 = [ctx copyEmbeddedObject: r1];
	
	
	// copy branch c out of the r and edit it a bit -> c"
	
	ETUUID *r2b3 = [[[ctx storeItemForUUID: r2] valueForAttribute: @"contents"] objectAtIndex: 2];

	ETUUID *r2b3copy = [ctx copyEmbeddedObject: r2b3];
	
	
	// FIXME: edit it
	
	// add c" to r' -> (a', b', c', c")
	
	{
		COStoreItem *r1item = [ctx storeItemForUUID: r1];
		[r1item addObject: r2b3copy forAttribute: @"contents"];
		[ctx updateItem: r1item];
	}
	
	// merge branch c" and b' -> branch d, r' -> (a', b', c', c", d)

	// FIXME:
	
}

#endif
