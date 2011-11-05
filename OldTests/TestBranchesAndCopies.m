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
	
	
	// copy r -> r' (a', b', c'), current branch: a'
	
	
	// copy branch c out of the r and edit it a bit -> c"
	
	
	// add c" to r' -> (a', b', c', c")
	
	
	// merge branch c" and b' -> branch d, r' -> (a', b', c', c", d)
	
}

#endif
