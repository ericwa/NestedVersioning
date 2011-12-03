#if 0

void test()
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
	// photo library <<persistent root>>
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

	
	rootctx = [store rootContext];
	taglibUUID = [rootCtx newPersistentRootWithRootItem: [factory newFolder: @"tag library"]];
	photolibUUID = [rootCtx newPersistentRootWithRootItem: [factory newFolder: @"photo library"]];
	

	[rootCtx commit];
	
	// set up some tags
	{
		taglibCtx = [rootCtx editingContextForEditingEmbdeddedPersistentRoot: taglibUUID];
		
		taglibFolder = [taglibCtx rootItemUUID];
		

		places = [taglibCtx insertItem: [factory newFolderNamed: @"places"]
						   inContainer: taglibFolder];
		northamerica = [taglibCtx insertItem: [factory newFolderNamed: @"north america"]
								 inContainer: places];
		canada = [taglibCtx insertItem: [factory newItemNamed: @"canada"]
								 inContainer: northamerica];
		southamerica = [taglibCtx insertItem: [factory newFolderNamed: @"south america"]
								 inContainer: places];
		brazil = [taglibCtx insertItem: [factory newItemNamed: @"brazil"]
								 inContainer: southamerica];
		
		[taglibCtx commit];
	}
	
	// create a photo library
	{
		photolibCtx = [rootCtx editingContextForEditingEmbdeddedPersistentRoot: photolibUUID];
		
		photolibFolder = [photolibCtx rootItemUUID];
		
		// set up some local tags
		{
			localtagFolder = [photolibCtx insertItem: [factory newFolderNamed: @"local tags"]
										 inContainer: photolibFolder];
			subject = [photolibCtx insertItem: [factory newFolderNamed: @"subject"]
							   inContainer: localtagFolder];
			landscape = [photolibCtx insertItem: [factory newFolderNamed: @"landscape"]
									 inContainer: subject];
			people = [photolibCtx insertItem: [factory newItemNamed: @"people"]
							   inContainer: subject];
			abstract = [photolibCtx insertItem: [factory newFolderNamed: @"abstract"]
									 inContainer: subject];
			lighting = [photolibCtx insertItem: [factory newItemNamed: @"lighting"]
							   inContainer: localtagFolder];
			sunlight = [photolibCtx insertItem: [factory newItemNamed: @"sunlight"]
								   inContainer: lighting];
			artificial = [photolibCtx insertItem: [factory newItemNamed: @"artificial"]
								   inContainer: lighting];			
		}
		
		// set up photo shoots folder
		{
			photoshootsFolder = [photolibCtx insertItem: [factory newFolderNamed: @"photo shoots"]
											inContainer: photolibFolder];
			shoot1 = [photolibCtx insertItem: [factory newFolderNamed: @"shoot1"]
								 inContainer: photoshootsFolder];
			
			photo1 = [factory newPersistentRootWithRootItem: [factory newFolder: @"photo1"]
												 insertInto: shoot1
												  inContext: photolibCtx];
			photo2 = [factory newPersistentRootWithRootItem: [factory newFolder: @"photo2"]
												 insertInto: shoot1
												  inContext: photolibCtx];			
			photo3 = [factory newPersistentRootWithRootItem: [factory newFolder: @"photo3"]
												 insertInto: shoot1
												  inContext: photolibCtx];
		}
		
		[photolibCtx commit];
		
		// set up tags on photo1
		
		// open a context to edit the branch
		{
			photo1Ctx = [photolibCtx editingContextForEditingEmbdeddedPersistentRoot: photo1];
			
			photo1Ctx_root = [photo1Ctx rootItemUUID];
			
			COPath *tag1 = [[[[[COPath path] 
								pathByAppendingPathToParent]
									pathByAppendingPathToParent]
										pathByAppendingPathComponent: taglibUUID]
											pathByAppendingPathComponent: canada];
			
			COPath *tag2 = [[[COPath path] pathByAppendingPathToParent]
								pathByAppendingPathComponent: landscape];

			COPath *tag3 = [[[COPath path] pathByAppendingPathToParent]
								pathByAppendingPathComponent: abstract];
			
			COStoreItem *photo1Ctx_rootItem = [photo1Ctx storeItemForUUID:photo1Ctx_root];
			[photo1Ctx_rootItem setValue: S(tag1, tag2, tag3)
							forAttribute: @"tags"
									type: COSetContainerType(kCOPrimitiveTypePath)
			[photo1Ctx updateItem: photo1Ctx_rootItem];
			
			[photo1Ctx commit];
		}
		
	}
	
}

#endif