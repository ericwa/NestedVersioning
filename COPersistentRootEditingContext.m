#import "COPersistentRootEditingContext.h"
#import "COMacros.h"
#import "COStorePrivate.h"
#import "COItemFactory.h"
#import "COItemFactory+PersistentRoots.h"
#import "COSubtree.h"

@implementation COPersistentRootEditingContext

/** @taskunit creation */

/**
 * @returns the commit UUID which the path leads to. 
 *
 * Throws an exception if there is an error while navigating the path (similar to
 * opening a filesystem path that does not exist), or if the path has
 * -[COPath hasLeadingPathsToParent] == TRUE or is nil.
 */
+ (ETUUID *) _baseCommitForPath: (COPath*)aPath store: (COStore *)aStore
{
	NILARG_EXCEPTION_TEST(aPath);
	NILARG_EXCEPTION_TEST(aStore);
	if ([aPath hasLeadingPathsToParent])
	{
		[NSException raise: NSInvalidArgumentException
					format: @"%@ called with a path with leading '..'", NSStringFromSelector(_cmd)];
	}
	
	if ([aPath isEmpty])
	{
		// may be nil
		return [aStore rootVersion];
	}

	COPath *parentPath = [aPath pathByDeletingLastPathComponent];
	ETUUID *lastPathComponent = [aPath lastPathComponent];
	ETUUID *parentCommit = [self _baseCommitForPath: parentPath store: aStore]; // recursive call
	
	COItem *item = [aStore storeItemForEmbeddedObject: lastPathComponent
											 inCommit: parentCommit];
	
	// item may be a persistent root or a branch.
	
	// FIXME: update to use COSubtree
	
	if ([[item valueForAttribute: @"type"] isEqual: @"persistentRoot"])
	{
		COPath *currentBranchPath = [item valueForAttribute: @"currentBranch"];
		if (![currentBranchPath isKindOfClass: [COPath class]]
			|| ![currentBranchPath hasComponents]
			|| [currentBranchPath hasLeadingPathsToParent]
			|| ![[currentBranchPath pathByDeletingLastPathComponent] isEmpty])
		{
			[NSException raise: NSInvalidArgumentException
						format: @"persistent root at %@ has invalid or no current branch (%@)",
								aPath, currentBranchPath];
		}
				  
		ETUUID *currentBranch = [currentBranchPath lastPathComponent];

		item = [aStore storeItemForEmbeddedObject: currentBranch
										 inCommit: parentCommit];
	}

	ETUUID *trackedVersion = [item valueForAttribute: @"currentVersion"];	
	
	if (![[item valueForAttribute: @"type"] isEqual: @"branch"]
		|| ![[item typeForAttribute: @"currentVersion"] isEqual: [COType commitUUIDType]]
		|| (nil == trackedVersion))
	{
		[NSException raise: NSInvalidArgumentException
					format: @"branch specified by %@ is invalid/has no current version set", aPath];
	}
	
	return trackedVersion;
}

/**
 * Private init method
 */
- (id)initWithPath: (COPath *)aPath
		   inStore: (COStore *)aStore
{
	NILARG_EXCEPTION_TEST(aPath);
	NILARG_EXCEPTION_TEST(aStore);
	
	if ([aPath hasLeadingPathsToParent])
	{
		[NSException raise: NSInvalidArgumentException
					format: @"cannot create context with a path with leading ../"];
	}
	
    SUPERINIT;
	
	ASSIGN(path, aPath);
	ASSIGN(store, aStore);
	
	@try
	{
		// this will be somewhat expensive, but needs to be done - we need to 
		// know what version our context is based on.
		ASSIGN(baseCommit, [[self class] _baseCommitForPath: aPath store: aStore]);
	}
	@catch (NSException *exception)
	{
		NSLog(@"WARNING: Exception occurred while calling +[COPersistentRootEditingContext _baseCommitForPath: %@ store: %@]: %@", aPath, aStore, exception);
		[self release];
		
		// FIXME: remove
		assert(0);
		
		return nil;
	}
	
	
	if (baseCommit != nil)
	{
		ASSIGN(tree, [store treeForCommit: baseCommit]);
	}

	// if there has never been a commit, tree is nil.	
	
    return self;
}

+ (COPersistentRootEditingContext *) editingContextForEditingPath: (COPath*)aPath
														  inStore: (COStore *)aStore
{
	return [[[self alloc] initWithPath: aPath
							   inStore: aStore] autorelease];
}


/**
 * private method; public users should use -[COStore rootContext].
 */
+ (COPersistentRootEditingContext *) editingContextForEditingTopLevelOfStore: (COStore *)aStore
{
	return [[self class] editingContextForEditingPath: [COPath path]
											  inStore: aStore];
}

- (void)dealloc
{
	DESTROY(store);
	DESTROY(path);
	DESTROY(baseCommit);
	DESTROY(tree);
	[super dealloc];
}


- (COPath *) path
{
	return path;
}
- (COStore *) store
{
	return store;
}

- (COPersistentRootEditingContext *) editingContextForEditingEmbdeddedPersistentRoot: (COSubtree *)aRoot
{
	if ([aRoot root] != [self persistentRootTree])
	{
		[NSException raise: NSInvalidArgumentException
					format: @"argument should be inside [self persistentRootTree]"];
	}
	
	return [[self class] editingContextForEditingPath: [[self path] pathByAppendingPathComponent: [aRoot UUID]]
											  inStore: [self store]];
}

- (COPersistentRootEditingContext *) editingContextForEditingBranchOfPersistentRoot: (COSubtree *)aBranch
{
	if ([aBranch root] != [self persistentRootTree])
	{
		[NSException raise: NSInvalidArgumentException
					format: @"argument should be inside [self persistentRootTree]"];
	}
	
	return [[self class] editingContextForEditingPath: [[self path] pathByAppendingPathComponent: [aBranch UUID]]
											  inStore: [self store]];
}

- (ETUUID *) commitWithMetadata: (COSubtree *)theMetadata
{

	//
	// <<<<<<<<<<<<<<<<<<<<< LOCK DB, BEGIN TRANSACTION <<<<<<<<<<<<<<<<<<<<<
	//
	
	// we need to check if we need to merge, first.
	
	
	ETUUID *newBase;
	
	@try
	{
		newBase = [[self class] _baseCommitForPath: [self path] store: [self store]];
	}
	@catch (NSException *exception)
	{
		NSLog(@"WARNING: Exception occurred while calling +[COPersistentRootEditingContext _baseCommitForPath: %@ store: %@]: %@", [self path], [self store], exception);
		
		// This means one of the persistent roots we will need to update to make the commit has been
		// corrupted/deleted since the context was created.
		// There isn't much we can do... it won't be possible to commit our changes.
		
		// FIXME: remove
		assert(0);
		
		return nil;
	}
	
	if (baseCommit != nil && 
		![newBase isEqual: baseCommit])
	{
		[NSException raise: NSInternalInconsistencyException
					format: @"Merging not yet supported"];
	}
	
	// FIXME
	NSDictionary *md = [NSDictionary dictionaryWithObjectsAndKeys: @"today", @"date", nil];
	
	// This is kind of a hack. If we are committing to the top-level of the store,
	// which is conceptually unversioned, don't set a parent pointer on the commit.
	// This will ensure old versions get GC'ed.
	ETUUID *commitParent = baseCommit;
	if ([path isEmpty])
	{
		commitParent = nil;
	}
	
	ETUUID *newCommitUUID = [store addCommitWithParent: commitParent
											  metadata: md
												  tree: tree];
	
	
	assert(newCommitUUID != nil);

	if ([path isEmpty])
	{
		[store setRootVersion: newCommitUUID];
	}
	 
	
	//
	// >>>>>>>>>>>>>>>>>>>>> UNLOCK DB, COMMIT TRANSACTION >>>>>>>>>>>>>>>>>>>>>
	//
	
	// if anything in the transaction failed, we can bail out here.


	// now update our path's parent
	
	if (![path isEmpty])
	{
		COPath *parentPath = [path pathByDeletingLastPathComponent];
		ETUUID *ourUUID = [path lastPathComponent];
		
		COPersistentRootEditingContext *parentCtx = [[[self class] alloc] initWithPath: parentPath
																			   inStore: store];
		
		COSubtree *item = [[parentCtx persistentRootTree] subtreeWithUUID: ourUUID];
		assert(item != nil);

		// item may be a persistent root or a branch.
		
		if ([[COItemFactory factory] isPersistentRoot: item])
		{
			item = [[COItemFactory factory] currentBranchOfPersistentRoot: item];
		}
		
		assert([[COItemFactory factory] isBranch: item]);
		
		ETUUID *trackedVersion = [[COItemFactory factory] currentVersionForBranch: item];
		assert([trackedVersion isEqual: baseCommit]); // we already checked this earlier
		[item setPrimitiveValue: newCommitUUID 
				   forAttribute: @"currentVersion"
						   type: [COType commitUUIDType]];
		[item setPrimitiveValue: newCommitUUID 
				   forAttribute: @"head" 
						   type: [COType commitUUIDType]];
		
		ETUUID *resultUUID = [parentCtx commitWithMetadata: nil];
		assert (resultUUID != nil);
		
		[parentCtx release];
	}
	
	// update our internal state
	 
	ASSIGN(baseCommit, newCommitUUID);
		 
	return newCommitUUID;
}

- (COSubtree *)persistentRootTree
{
	return tree;
}

- (void) setPersistentRootTree: (COSubtree *)aSubtree
{
	ASSIGN(tree, aSubtree);
}

@end
