#if 0

void test()
{
	/**
	 
	 there is a photo and a collage.
	 
	 the photo has multiple branches - black and white, sepia, color.
	 currently the photo is set to color.
	 
	 the photo is dragged into the montage creating a copy.
	 it should not prompt the user with "which branch to copy" or anything.
	 
	   - default behaviour is to create copies of these branches,
	     so we have: photolibrary-color, montage-color, photolibrary-b&w, montage-b&w,
	     photolibrary-sepia, montage-sepia branches.
	 
	 the montage also has multiple branches already (layout A, layout B).
	 currently the montage is set to branch "layout B".
	 
	 - what if we want a photo in "layout A" that links to whatever "layout B"'s photo
	 is doing? simple.. just a proot that links to /artwork/montage-layout-b/photo-proot
	 
	 - what if we want a photo in "layout A" that links to a specific branch of "layout B"'s photo?
	 just a proot that links to /artwork/montage-layout-b/photo-specific-branch
	 
	 - what if we want a photo in "layout A" that links to (whatever the current branch of the 
	 montage is)'s current photo (yes, that is probably crazy and useless!)

	 just a proot that links to /artwork/montage-proot/photo-proot

	 
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