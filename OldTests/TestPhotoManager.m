#if 0

void test()
{
	/**
	 we simulate a photo manager with the following object types:
	 
	 library (versioned persistent root)
	 - can contain projects, folders, albums
	 
	 photo (versioned persistent root)
	 - has name, date, etc
	 
	 project
	 -can contain folders, albums, photos (but not projects)
	 -contained items can only be in one project at a time.
	 -projects "own" photos - each photo is in only one project (but may 
	  be referenced by multiple albums, possibly from other projects).
	 
	 folder
	 -can contain projects, folders, albums (but not photos, directly).
	 -contained items can only be in one folder at a time.
	 
	 album
	 -can contain only photos
	 -contained photos can be in multiple albums.
	 */
	
	// library <<persistent root>>
	//  |
	//  |--folder1
	//  |   |
	//  |   |-project1
	//  |   |   |
	//  |   |   \-photo1 <<persistent root>>	
	//  |   |
	//  |   \-album1
	//  |       |
	//  |       \-link to photo1
	//  | 
	//   \-project2
	//      |
	//      |--photo2 <<persistent root>>
    //      |
	//      |--photo3 <<persistent root>>
    //      |
	//       \-album2
	//          |
	//          |-link to photo1
	//          |
	//          \-link to photo2
	
	
}

#endif