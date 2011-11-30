#import "COPersistentRootEditingContext.h"
#import "Common.h"
#import "COStorePrivate.h"

@implementation COPersistentRootEditingContext

/** @taskunit creation */

/**
 * Private init method
 */
- (id)initWithPath: (COPath *)aPath
		   inStore: (COStore *)aStore
{
	NILARG_EXCEPTION_TEST(aPath);
	NILARG_EXCEPTION_TEST(aStore);
	
    SUPERINIT;
	
	insertedOrUpdatedItems = [[NSMutableDictionary alloc] init];
	
	ASSIGN(path, aPath);
	ASSIGN(store, aStore);
	
	
	
	if (baseCommit != nil)
	{
		ASSIGN(existingItems, [store UUIDsAndStoreItemsForCommit: baseCommit]);
		ASSIGN(rootItem, [store rootItemForCommit: baseCommit]);
	}
	
    return self;
}

+ (COPersistentRootEditingContext *) editingContextForEditingPath: (COPath*)aPath
														  inStore: (COStore *)aStore
{
	return [[[self alloc] initWithPath: [COPath path]
							   inStore: aStore] autorelease];}

- (COPersistentRootEditingContext *) editingContextForEditingEmbdeddedPersistentRoot: (ETUUID*)aRoot
{
	return [[self class] editingContextForEditingPath: [[self path] pathByAppendingPathComponent: aRoot]
											  inStore: [self store]];
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
	[store release];
	[path release];
	[baseCommit release];
	[insertedOrUpdatedItems release];
	[rootItem release];
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

- (ETUUID *) commit
{
	/*
FIXME:
	how do we add undo/redo to this?
		for branches/roots that track a specific version, they should also have 
			a key/value called "tip". (terminology stolen from mercurial)
			
			- every commit to that branch root should set both "tracking" and "tip"
			to the same value.
			*/
			
	
	// calculate final uuid set
	assert(rootItem != nil);
	NSSet *finalUUIDSet = [self allEmbeddedObjectUUIDsForUUIDInclusive: rootItem];
	
	// set up the commit dictionary
	NSMutableDictionary *uuidsanditems = [NSMutableDictionary dictionary];
	{
		for (ETUUID *uuid in finalUUIDSet)
		{
			COStoreItem *item = [self storeItemForUUID: uuid];
			
			[uuidsanditems setObject: item
							  forKey: uuid];
		}
	}
	
	// FIXME
	NSDictionary *md = [NSDictionary dictionaryWithObjectsAndKeys: @"today", @"date", nil];
	

	ETUUID *uuid = [store addCommitWithParent: baseCommit
									 metadata: md
						   UUIDsAndStoreItems: uuidsanditems
									 rootItem: rootItem];
	
	assert(uuid != nil);
	
	// FIXME
	
	ASSIGN(baseCommit, uuid);
	[insertedOrUpdatedItems removeAllObjects];
	ASSIGN(existingItems, [NSDictionary dictionaryWithDictionary: [store UUIDsAndStoreItemsForCommit: baseCommit]]);
	
	return uuid;
}

- (void) commitWithMergedVersionUUIDs: (NSArray*)anArray
{
	assert(0); // unimplemented
}

- (ETUUID *)rootEmbeddedObject
{
	return rootItem;
}

- (NSSet *)allItemUUIDs
{
	return [NSSet setWithArray: [[existingItems allKeys] arrayByAddingObjectsFromArray: [insertedOrUpdatedItems allKeys]]];
}
- (NSSet *)allItems
{
	NSMutableSet *result = [NSMutableSet set];
	for (ETUUID *uuid in [self allItemUUIDs])
	{
		[result addObject: [self storeItemForUUID: uuid]];
	}
	return result;
}

- (COStoreItem *)storeItemForUUID: (ETUUID*) aUUID
{
	assert([aUUID isKindOfClass: [ETUUID class]]);
	
	COStoreItem *result = nil;
	
	if (baseCommit != nil)
	{
		result = [[[store storeItemForEmbeddedObject: aUUID inCommit: baseCommit] copy] autorelease];
		assert(result != nil);
	}
		
	COStoreItem *localResult = [[[insertedOrUpdatedItems objectForKey: aUUID] copy] autorelease];
	
	if (localResult != nil)
	{
		NSLog(@"overriding %@ with %@", result, localResult);
		result = localResult;
	}
	
	assert(result != nil); // either the store, or in memory, must have the value
	
	return result;
}

- (NSSet *) allEmbeddedObjectUUIDsForUUID: (ETUUID*) aUUID
{
	NILARG_EXCEPTION_TEST(aUUID);
	
	NSMutableSet *result = [NSMutableSet set];
	
	COStoreItem *item = [self storeItemForUUID: aUUID];
	for (NSString *key in [item attributeNames])
	{
		NSDictionary *type = [item typeForAttribute: key];
		if ([[type objectForKey: kCOPrimitiveType] isEqual: kCOPrimitiveTypeEmbeddedItem])
		{		
			for (ETUUID *embedded in [item allObjectsForAttribute: key])
			{
				[result addObject: embedded];
				[result unionSet: [self allEmbeddedObjectUUIDsForUUID: embedded]];
			}
		}
	}
	return result;
}

- (NSSet *) allEmbeddedObjectUUIDsForUUIDInclusive: (ETUUID*) aUUID
{
	NILARG_EXCEPTION_TEST(aUUID);
	
	return [[self allEmbeddedObjectUUIDsForUUID: aUUID] setByAddingObject: aUUID];
}

- (NSSet *) allEmbeddedItemsForUUIDInclusive: (ETUUID*) aUUID
{
	NSSet *uuids = [self allEmbeddedObjectUUIDsForUUIDInclusive: aUUID];
	NSMutableSet *result = [NSMutableSet setWithCapacity: [uuids count]];
	for (ETUUID *uuid in uuids)
	{
		[result addObject: [self storeItemForUUID: uuid]];
	}
	return result;
}

- (void) insertOrUpdateItems: (NSSet *)items
	   newRootEmbeddedObject: (ETUUID*)aRoot
{
	NILARG_EXCEPTION_TEST(items);
	NILARG_EXCEPTION_TEST(aRoot);
	
	assert([items isKindOfClass: [NSSet class]]);
	
	ASSIGN(rootItem, aRoot);
	
	for (COStoreItem *item in items)
	{
		[insertedOrUpdatedItems setObject: item forKey: [item UUID]];
	}
	
	// FIXME: validation
}

- (void) insertOrUpdateItems: (NSSet *)items
{
	[self insertOrUpdateItems: items
		newRootEmbeddedObject: rootItem];
}



// copied from COStoreController
#if 0


- (id) _trackedPathOrVersionForPlist: (id)embeddedObjectPlist
							  atPath: (COPath *)path
{
	NSString *type = [embeddedObjectPlist objectForKey: @"type"];
	if ([type isEqualToString: @"root"])
	{
		NSString *trackingType = [embeddedObjectPlist objectForKey: @"tracking-type"];
		NSString *tracking = [embeddedObjectPlist objectForKey: @"tracking"];
		if ([trackingType isEqualToString: @"owned-branch"])
		{
			return [path pathByAppendingPersistentRoot: [ETUUID UUIDWithString: tracking]];
		}
		else if ([trackingType isEqualToString: @"remote-root"] ||
				 [trackingType isEqualToString: @"remote-branch"])
		{
			return [COPath pathWithString: tracking];
		}
		else if ([trackingType isEqualToString: @"version"])
		{
			return [ETUUID UUIDWithString: tracking];
		}
		
		[NSException raise: NSInternalInconsistencyException
					format: @"unsupported tracking type %@: %@", trackingType, tracking];
	}
	else if ([type isEqualToString: @"branch"])
	{
		return [ETUUID UUIDWithString:
				[embeddedObjectPlist objectForKey: @"tracking"]];
	}
	
	[NSException raise: NSInternalInconsistencyException
				format: @"unsupported object type %@: %@", type, embeddedObjectPlist];
	
	return nil;
}

/**
 * see comment in header
 */
- (ETUUID*) _currentVersionForPersistentRootAtPath: (COPath*)path
								   absolutePathOut: (COPath **)absPath
{
	// NOTE: If we want special handling for top-level persistent roots (children of /),
	// this method is where we would do it
	if ([path isEmpty])
	{
		*absPath = [COPath path];
		return [store rootVersion];
	}
	else
	{
		COPath *parentAbs;
		COPath *parent = [path pathByDeletingLastPathComponent];
		ETUUID *lastPathComponent = [path lastPathComponent];
		
		// recursive call to ourself to find the version containing the last
		// path component.
		ETUUID *parentCurrentVersion = [self _currentVersionForPersistentRootAtPath: parent
																	absolutePathOut: &parentAbs];
		
		id embeddedObjectPlist = [self storeItemForEmbeddedObject: lastPathComponent
														 inCommit: parentCurrentVersion];
		
		id trackedPathOrVersion = [self _trackedPathOrVersionForPlist: embeddedObjectPlist
															   atPath: parent];
		
		if ([trackedPathOrVersion isKindOfClass: [COPath class]])
		{
			return [self _currentVersionForPersistentRootAtPath: trackedPathOrVersion
												absolutePathOut: absPath];
		}
		else if ([trackedPathOrVersion isKindOfClass: [ETUUID class]])
		{
			*absPath = [parentAbs pathByAppendingPersistentRoot: lastPathComponent];
			return (ETUUID*)trackedPathOrVersion;
		}
		
		[NSException raise: NSInternalInconsistencyException
					format: @"failed to parse %@", embeddedObjectPlist];
		return nil;
	}
}

- (COPath *)absolutePathForPath: (COPath*)aPath
{
	if ([aPath isEmpty])
	{
		return aPath;
	}
	
	COPath *absPath;
	[self _currentVersionForPersistentRootAtPath: aPath
								 absolutePathOut: &absPath];
	return absPath;
}

- (ETUUID*) currentVersionForPersistentRootAtPath: (COPath*)path
{
	COPath *unused;
	return [self _currentVersionForPersistentRootAtPath: path
										absolutePathOut: &unused];
}


// writing

// helper method for modifying a persistent root plist.
//
// we are guaranteed that it will be a "absolute" plist (it has a "tracking" field with a version UUID)
// since  -writeUUIDsAndPlists:forPersistentRootAtPath:metadata:
// created an absolute path
//

- (id) _updatePersistentRootPlist: (id)plist
			  toPointToNewVersion: (ETUUID*)newVersion
{
	NSMutableDictionary *md = [NSMutableDictionary dictionaryWithDictionary: plist];
	[md setObject: [newVersion stringValue]
		   forKey: @"tracking"];
	return md;
}


- (void) _writeUUIDsAndPlists: (NSDictionary*)objects // ETUUID : plist
forPersistentRootAtAbsolutePath: (COPath*)path
					 metadata: (id)metadataPlist
{
	// FIXME: the set of commits made by this method and its
	// recursive calls to itself should be one atomic db transaction
	
	
	
	// step 1: commit all the objects we were passed 
	// ---------------------------------------------
	
	// we are going to make a commit with this as its parent
	
	// maybe nil if the store has never been used
	ETUUID *baseVersion = [self currentVersionForPersistentRootAtPath: path];
	
	ETUUID *newVersion = [store addCommitWithParent: baseVersion
										   metadata: metadataPlist
									 UUIDsAndPlists: objects];
	
	
	// step 2: now that the data is committed, we need
	//         to update the parent of the last path component
	//         to point to the new commit.
	// -------------------------------------------------------
	
	if ([path isEmpty])
	{
		// that's it, we're done.
		[store setRootVersion: newVersion];
	}
	else
	{	
		// complex case: we are going to have to construct a commit in
		// the parent persistent root.
		COPath *parentPath = [path pathByDeletingLastPathComponent];
		
		NSMutableDictionary *parentCommitObjects;
		
		// fill in the objects we need to commit:
		{
			ETUUID *currentParentCommit = [self currentVersionForPersistentRootAtPath: parentPath];
			
			// get the current ones.
			parentCommitObjects = [NSMutableDictionary dictionaryWithDictionary: 
								   [store UUIDsAndPlistsForCommit: currentParentCommit]];
			
			// get the plist that needs to be updated
			id plist = [parentCommitObjects objectForKey: [path lastPathComponent]];
			
			assert(plist != nil);
			
			plist = [self _updatePersistentRootPlist: plist
								 toPointToNewVersion: newVersion];
			
			// save the updated persistent root
			[parentCommitObjects setObject: plist
									forKey:[path lastPathComponent]];
		}
		
		
		// the commit we're making is not a change made directly by the user
		// but a "synthetic" commit, so make up some metadata.
		NSDictionary *md = [NSDictionary dictionaryWithObject: @"commit-in-child"
													   forKey: @"type"];
		
		[self _writeUUIDsAndPlists: parentCommitObjects
   forPersistentRootAtAbsolutePath: parentPath
						  metadata: md];
	}
}

#endif

@end
