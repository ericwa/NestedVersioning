#if 0

void test()
{
	/**
	 
	 there is a photo and a collage.
	 
	 the photo has multiple branches - black and white, sepia, color.
	 currently the photo is set to color.
	 
	 the photo is dragged into the montage creating a copy.
	 it should not prompt the user with "which branch to copy" or anything.
	 
	 the montage also has multiple branches already (layout A, layout B).
	 currently the montage is set to branch "layout B".
	 
	 
	 Q: How should the photo in the montage "see" the branches of the other photo?
	 How should it react if we want to track a branch in the other photo?
	 Should we have to delete our copy ("Make into Link") to track the other photo?
	 
	 **/
	
	
	
	/**
	 guideline:
	 
	 embedded object: has no history. e.g. a line, a box.
	 persistent root: has history. e.g. a photo, a group of lines (if desired.)
	 
	 
	 **/
	
	// set up the montage

	layer_bg = [embeddedobject new];
	layer_fg = [embeddedobject new];
	
	layers = [embeddedobject new];
	[layers addContained: layer_bg];
	[layers addContained: layer_fg]; //FIXME: set as ordered
	
	montage = [rootobject new];
	[montage addContained: layers];
	
	montage_a = [montage newbranch];
	montage_b = [montage newbranch];	
	
	
	[montage setBranch: montage_a];
	
	// set up the photo library
	
	photo = [rootobject new];
	
	photolibrary = [rootobject new];
	[photolibrary addContained: photo];
	
	photo_color = [photo newbranch];
	photo_bw = [photo newbranch];
	photo_sepia = [photo newbranch];	
	
	[photo setBranch: photo_color];
	
	
	// copy in the photo to montage_a
	
	[montage insertCopyOfPersistentRoot: photo];
	
	[montage setBranch: montage_b];
	
	[montage insertCopyOfPersistentRoot: photo];
}

#endif