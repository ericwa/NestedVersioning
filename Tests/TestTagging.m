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
	//          |--photo1 <<persistent root>> 
	//          |   |
	//          |   \--(tags: places/north america/canada, subject/landscape, subject/abstract)
    //          |
	//          |--photo2 <<persistent root>> 
	//          |   |
	//          |   \--(tags: lighting/sunlight, places/south america/brazil, subject/abstract)
    //          |
	//          \--photo3 <<persistent root>> 
	//              |
	//              \--(tags: lighting/artificial, places/south america/brazil, subject/people)


	COStore *store = setupStore();
	COItemFactory *factory = [COItemFactory factory];
	
	COPersistentRootEditingContext *rootCtx = [store rootContext];
	
	COSubtree *iroot = [COSubtree subtree];
	ETUUID *uroot = [iroot UUID];
	
	[rootCtx setItemTree: iroot];
	
	
	ETUUID *taglibUUID = [rootCtx createAndInsertNewPersistentRootWithRootItem: [factory folder: @"tag library"]
																inItemWithUUID: uroot];
	ETUUID *photolibUUID = [rootCtx createAndInsertNewPersistentRootWithRootItem: [factory folder: @"photo library"]
																  inItemWithUUID: uroot];
	
	[rootCtx commitWithMetadata: nil];
	
	// set up some tags
	
		COPersistentRootEditingContext *taglibCtx = [rootCtx editingContextForEditingEmbdeddedPersistentRoot: taglibUUID];
		
		ETUUID *taglibFolder = [taglibCtx rootUUID];
		

		ETUUID *places = [taglibCtx insertTree: [factory folder: @"places"]
								   inContainer: taglibFolder];
		ETUUID *northamerica = [taglibCtx insertTree: [factory folder: @"north america"]
										 inContainer: places];
		ETUUID *canada = [taglibCtx insertTree: [factory item: @"canada"]
								   inContainer: northamerica];
		ETUUID *southamerica = [taglibCtx insertTree: [factory folder: @"south america"]
										 inContainer: places];
		ETUUID *brazil = [taglibCtx insertTree: [factory item: @"brazil"]
								   inContainer: southamerica];
		
		[taglibCtx commitWithMetadata: nil];
	


	// create a photo library
	
		COPersistentRootEditingContext *photolibCtx = [rootCtx editingContextForEditingEmbdeddedPersistentRoot: photolibUUID];
		
		ETUUID *photolibFolder = [photolibCtx rootUUID];
		
		// set up some local tags
		
			ETUUID *localtagFolder = [photolibCtx insertTree: [factory folder: @"local tags"]
												 inContainer: photolibFolder];
			ETUUID *subject = [photolibCtx insertTree: [factory folder: @"subject"]
										  inContainer: localtagFolder];
			ETUUID *landscape = [photolibCtx insertTree: [factory item: @"landscape"]
											inContainer: subject];
			ETUUID *people = [photolibCtx insertTree: [factory item: @"people"]
										 inContainer: subject];
			ETUUID *abstract = [photolibCtx insertTree: [factory item: @"abstract"]
										   inContainer: subject];
			ETUUID *lighting = [photolibCtx insertTree: [factory folder: @"lighting"]
										   inContainer: localtagFolder];
			ETUUID *sunlight = [photolibCtx insertTree: [factory item: @"sunlight"]
										   inContainer: lighting];
			ETUUID *artificial = [photolibCtx insertTree: [factory item: @"artificial"]
											 inContainer: lighting];			
		
		
		// set up photo shoots folder
		
			ETUUID *photoshootsFolder = [photolibCtx insertTree: [factory folder: @"photo shoots"]
													inContainer: photolibFolder];
			ETUUID *shoot1 = [photolibCtx insertTree: [factory folder: @"shoot1"]
										 inContainer: photoshootsFolder];
			
			ETUUID *photo1 = [photolibCtx createAndInsertNewPersistentRootWithRootItem: [factory folder: @"photo1"]
																		inItemWithUUID: shoot1];
			ETUUID *photo2 = [photolibCtx createAndInsertNewPersistentRootWithRootItem: [factory folder: @"photo2"]
																		inItemWithUUID: shoot1];			
			ETUUID *photo3 = [photolibCtx createAndInsertNewPersistentRootWithRootItem: [factory folder: @"photo3"]
																		inItemWithUUID: shoot1];
		
		
		// set up some albums
	
			ETUUID *albums = [photolibCtx insertTree: [factory folder: @"albums"]
										 inContainer: photolibFolder];
			ETUUID *album1 = [photolibCtx insertTree: [factory folder: @"album1"]
										 inContainer: albums];	
			ETUUID *album2 = [photolibCtx insertTree: [factory folder: @"album2"]
										 inContainer: albums];
	
		// put photos in the albums as COPaths. Photo 2 and 1 are in both albums
		// photo 2 appears twice in album1
		
			{
				COMutableItem *item = [photolibCtx _storeItemForUUID: album1];
				[item setValue: A([COPath pathWithPathComponent: photo1], 
								  [COPath pathWithPathComponent: photo2],
								  [COPath pathWithPathComponent: photo2]) 
				  forAttribute: @"contents"
						  type: [COType arrayWithPrimitiveType: [COType pathType]]];
				[photolibCtx _insertOrUpdateItems: S(item)];
			}
			{
				COMutableItem *item = [photolibCtx _storeItemForUUID: album2];
				[item setValue: A([COPath pathWithPathComponent: photo2], 
								  [COPath pathWithPathComponent: photo1],
								  [COPath pathWithPathComponent: photo3]) 
				  forAttribute: @"contents"
						  type: [COType arrayWithPrimitiveType: [COType pathType]]];
				[photolibCtx _insertOrUpdateItems: S(item)];
			}
	
	
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
			
			COMutableItem *photo1Ctx_rootItem = [photo1Ctx _storeItemForUUID:photo1Ctx_root];
			[photo1Ctx_rootItem setValue: S(tag1, tag2, tag3)
							forAttribute: @"tags"
									type: [COType setWithPrimitiveType: [COType pathType]]];
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
			
			COMutableItem *photo2Ctx_rootItem = [photo2Ctx _storeItemForUUID:photo2Ctx_root];
			[photo2Ctx_rootItem setValue: S(tag1, tag2, tag3)
							forAttribute: @"tags"
									type: [COType setWithPrimitiveType: [COType pathType]]];
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
			
			COMutableItem *photo3Ctx_rootItem = [photo3Ctx _storeItemForUUID:photo3Ctx_root];
			[photo3Ctx_rootItem setValue: S(tag1, tag2, tag3)
							forAttribute: @"tags"
									type: [COType setWithPrimitiveType: [COType pathType]]];
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
	
	
	// do some searches
	
	// 1. search for "subject/abstract" tag. note there are two instances of the tag; one in photolibBranchA
	//    and one in photolibBranchB. Searching for complete paths (e.g. "../../abstract") makes no sense.
	//    so we just search for the uuid of "abstract".
	
	[store release];
}
