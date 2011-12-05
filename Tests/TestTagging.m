#import "TestCommon.h"

void testTagging()
{	
	// tag library <<persistent root>>
	//  |
	//  \--places
	//      |
	//      |-north america
	//      |   |
	//      |   \-canada 
	//      |
	//      \-south america
	//          |
	//          \-brazil
	//    
	// photo library <<persistent root (branchA, branchB) >>
	//  |
	//  |--local tags
	//  |   |
	//  |   |-subject
	//  |   |   |
	//  |   |   |-landscape 
	//  |   |   |
	//  |   |   |-people
	//  |   |   |
	//  |   |   \-abstract
	//  |   |
	//  |   \-lighting
	//  |       |
	//  |       |-sunlight
	//  |       |
	//  |       \-artificial
	//  | 
	//   \-photo shoots
	//      |
	//      \--shoot1
    //          |
	//          |--photo1 (tags: places/north america/canada, subject/landscape, subject/abstract)
    //          |
	//          |--photo2 (tags: lighting/sunlight, places/south america/brazil, subject/abstract)
    //          |
	//          \--photo3 (tags: lighting/artificial, places/south america/brazil, subject/people)


	COStore *store = setupStore();
	COItemFactory *factory = [COItemFactory factory];
	
	COPersistentRootEditingContext *rootCtx = [store rootContext];
	
	COStoreItemTree *iroot = [COStoreItemTree itemTree];
	ETUUID *uroot = [iroot UUID];
	
	[rootCtx setItemTree: iroot];
	
	
	ETUUID *taglibUUID = [rootCtx createAndInsertNewPersistentRootWithRootItem: [factory newFolder: @"tag library"]
																inItemWithUUID: uroot];
	ETUUID *photolibUUID = [rootCtx createAndInsertNewPersistentRootWithRootItem: [factory newFolder: @"photo library"]
																  inItemWithUUID: uroot];
	
	[rootCtx commitWithMetadata: nil];
	
	// set up some tags
	
		COPersistentRootEditingContext *taglibCtx = [rootCtx editingContextForEditingEmbdeddedPersistentRoot: taglibUUID];
		
		ETUUID *taglibFolder = [taglibCtx rootUUID];
		

		ETUUID *places = [taglibCtx insertTree: [factory newFolder: @"places"]
								   inContainer: taglibFolder];
		ETUUID *northamerica = [taglibCtx insertTree: [factory newFolder: @"north america"]
										 inContainer: places];
		ETUUID *canada = [taglibCtx insertTree: [factory newItem: @"canada"]
								   inContainer: northamerica];
		ETUUID *southamerica = [taglibCtx insertTree: [factory newFolder: @"south america"]
										 inContainer: places];
		ETUUID *brazil = [taglibCtx insertTree: [factory newItem: @"brazil"]
								   inContainer: southamerica];
		
		[taglibCtx commitWithMetadata: nil];
	


	// create a photo library
	
		COPersistentRootEditingContext *photolibCtx = [rootCtx editingContextForEditingEmbdeddedPersistentRoot: photolibUUID];
		
		ETUUID *photolibFolder = [photolibCtx rootUUID];
		
		// set up some local tags
		
			ETUUID *localtagFolder = [photolibCtx insertTree: [factory newFolder: @"local tags"]
												 inContainer: photolibFolder];
			ETUUID *subject = [photolibCtx insertTree: [factory newFolder: @"subject"]
										  inContainer: localtagFolder];
			ETUUID *landscape = [photolibCtx insertTree: [factory newItem: @"landscape"]
											inContainer: subject];
			ETUUID *people = [photolibCtx insertTree: [factory newItem: @"people"]
										 inContainer: subject];
			ETUUID *abstract = [photolibCtx insertTree: [factory newItem: @"abstract"]
										   inContainer: subject];
			ETUUID *lighting = [photolibCtx insertTree: [factory newFolder: @"lighting"]
										   inContainer: localtagFolder];
			ETUUID *sunlight = [photolibCtx insertTree: [factory newItem: @"sunlight"]
										   inContainer: lighting];
			ETUUID *artificial = [photolibCtx insertTree: [factory newItem: @"artificial"]
											 inContainer: lighting];			
		
		
		// set up photo shoots folder
		
			ETUUID *photoshootsFolder = [photolibCtx insertTree: [factory newFolder: @"photo shoots"]
													inContainer: photolibFolder];
			ETUUID *shoot1 = [photolibCtx insertTree: [factory newFolder: @"shoot1"]
										 inContainer: photoshootsFolder];
			
			ETUUID *photo1 = [photolibCtx createAndInsertNewPersistentRootWithRootItem: [factory newFolder: @"photo1"]
																		inItemWithUUID: shoot1];
			ETUUID *photo2 = [photolibCtx createAndInsertNewPersistentRootWithRootItem: [factory newFolder: @"photo2"]
																		inItemWithUUID: shoot1];			
			ETUUID *photo3 = [photolibCtx createAndInsertNewPersistentRootWithRootItem: [factory newFolder: @"photo3"]
																		inItemWithUUID: shoot1];
		
		
		[photolibCtx commitWithMetadata: nil];
		
		// set up tags on photo1

		{
		// open a context to edit the branch

			COPersistentRootEditingContext *photo1Ctx = [photolibCtx editingContextForEditingEmbdeddedPersistentRoot: photo1];
			
			ETUUID *photo1Ctx_root = [photo1Ctx rootUUID];
			
			COPath *tag1 = [[[[[COPath path] 
								pathByAppendingPathToParent]
									pathByAppendingPathToParent]
										pathByAppendingPathComponent: taglibUUID]
											pathByAppendingPathComponent: canada];
			
			COPath *tag2 = [[[COPath path] pathByAppendingPathToParent]
								pathByAppendingPathComponent: landscape];

			COPath *tag3 = [[[COPath path] pathByAppendingPathToParent]
								pathByAppendingPathComponent: abstract];
			
			COStoreItem *photo1Ctx_rootItem = [photo1Ctx _storeItemForUUID:photo1Ctx_root];
			[photo1Ctx_rootItem setValue: S(tag1, tag2, tag3)
							forAttribute: @"tags"
									type: COSetContainerType(kCOPrimitiveTypePath)];
			[photo1Ctx _insertOrUpdateItems: S(photo1Ctx_rootItem)];
			
			[photo1Ctx commitWithMetadata: nil];
		}
	
		// set up tags on photo2
		
		{
			// open a context to edit the branch
			
			COPersistentRootEditingContext *photo2Ctx = [photolibCtx editingContextForEditingEmbdeddedPersistentRoot: photo2];
			
			ETUUID *photo2Ctx_root = [photo2Ctx rootUUID];
			
			COPath *tag1 = [[[[[COPath path] 
							   pathByAppendingPathToParent]
							  pathByAppendingPathToParent]
							 pathByAppendingPathComponent: taglibUUID]
							pathByAppendingPathComponent: brazil];
			
			COPath *tag2 = [[[COPath path] pathByAppendingPathToParent]
							pathByAppendingPathComponent: sunlight];
			
			COPath *tag3 = [[[COPath path] pathByAppendingPathToParent]
							pathByAppendingPathComponent: abstract];
			
			COStoreItem *photo2Ctx_rootItem = [photo2Ctx _storeItemForUUID:photo2Ctx_root];
			[photo2Ctx_rootItem setValue: S(tag1, tag2, tag3)
							forAttribute: @"tags"
									type: COSetContainerType(kCOPrimitiveTypePath)];
			[photo2Ctx _insertOrUpdateItems: S(photo2Ctx_rootItem)];
			
			[photo2Ctx commitWithMetadata: nil];
		}
	
		// set up tags on photo3
		
		{
			// open a context to edit the branch
			
			COPersistentRootEditingContext *photo3Ctx = [photolibCtx editingContextForEditingEmbdeddedPersistentRoot: photo3];
			
			ETUUID *photo3Ctx_root = [photo3Ctx rootUUID];
			
			COPath *tag1 = [[[[[COPath path] 
							   pathByAppendingPathToParent]
							  pathByAppendingPathToParent]
							 pathByAppendingPathComponent: taglibUUID]
							pathByAppendingPathComponent: brazil];
			
			COPath *tag2 = [[[COPath path] pathByAppendingPathToParent]
							pathByAppendingPathComponent: people];
			
			COPath *tag3 = [[[COPath path] pathByAppendingPathToParent]
							pathByAppendingPathComponent: artificial];
			
			COStoreItem *photo3Ctx_rootItem = [photo3Ctx _storeItemForUUID:photo3Ctx_root];
			[photo3Ctx_rootItem setValue: S(tag1, tag2, tag3)
							forAttribute: @"tags"
									type: COSetContainerType(kCOPrimitiveTypePath)];
			[photo3Ctx _insertOrUpdateItems: S(photo3Ctx_rootItem)];
			
			[photo3Ctx commitWithMetadata: nil];
		}
	
	// create branch of photo library
	
	// reopen the context to avoid a merge.
	// FIXME: shouldn't be necessary
	
	rootCtx = [store rootContext];
	
	ETUUID *photolibBranchA = [rootCtx currentBranchOfPersistentRoot: photolibUUID];
	ETUUID *photolibBranchB = [rootCtx createBranchOfPersistentRoot: photolibUUID];
	[rootCtx commitWithMetadata: nil];
	
	
	// do some searches.
}
