#import "COPersistentRootEditingContext.h"
#import "Common.h"

@implementation COPersistentRootEditingContext

- (id)initWithStore: (COStore *)aStore
		 commitUUID: (ETUUID*)aCommit
{
	NILARG_EXCEPTION_TEST(aStore);
	
    SUPERINIT;
	
	insertedOrUpdatedItems = [[NSMutableDictionary alloc] init];
	
	ASSIGN(baseCommit, aCommit); // may be nil
	ASSIGN(store, aStore);
	
	if (baseCommit != nil)
	{
		ASSIGN(existingItems, [store UUIDsAndStoreItemsForCommit: baseCommit]);
		ASSIGN(rootItem, [store rootItemForCommit: baseCommit]);
	}
	
    return self;
}

- (id)initWithStore: (COStore *)aStore
{
	return [self initWithStore: aStore commitUUID: nil];
}

- (void)dealloc
{
	[insertedOrUpdatedItems release];
	[baseCommit release];
	[store release];
	[existingItems release];
	[rootItem release];
	[super dealloc];
}


- (ETUUID *) commit
{
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

- (void) copyEmbeddedObject: (ETUUID*) aUUID
				fromContext: (COPersistentRootEditingContext*) aCtxt
					toIndex: (NSUInteger)i
			   ofCollection: (NSString*)attribute
				   inObject: (ETUUID*)anObject
{
	// FIXME: see comments in header.. implementation not complete/correct
	
	NILARG_EXCEPTION_TEST(aUUID);
	NILARG_EXCEPTION_TEST(aCtxt);
	
	COStoreItem *dest = [self storeItemForUUID: anObject];
	
	assert([[dest attributeNames] containsObject: attribute]);
	assert([[[dest typeForAttribute: attribute] objectForKey: kCOTypeKind] isEqual: kCOContainerTypeKind]);
	assert([[[dest typeForAttribute: attribute] objectForKey: kCOPrimitiveType] isEqual: kCOPrimitiveTypeEmbeddedItem]);
	
	// FIXME: THis should be a UUID->COStoreItem dictionary
	// so we guarantee that the set doesnt' contain multiple items with the same UUID.
	NSMutableSet *updatesAndInserts = [NSMutableSet set];
	[updatesAndInserts unionSet: [aCtxt allEmbeddedItemsForUUIDInclusive: aUUID]];
	
	// Not strictly necessary
	{		
		NSMutableSet *objectsToBeOverwrittenUUIDS = [NSMutableSet setWithSet: [self allItemUUIDs]];
		[objectsToBeOverwrittenUUIDS intersectSet: [aCtxt allEmbeddedObjectUUIDsForUUIDInclusive: aUUID]];
		NSLog(@"Overwriting %@ in copy", objectsToBeOverwrittenUUIDS);
	}
	
	// Insert the new UUID into the destination item.
	NSMutableArray *array = [NSMutableArray arrayWithArray: [dest valueForAttribute: attribute]];
	[array insertObject: aUUID atIndex: i];
	[dest setValue:array forAttribute: attribute];
	
	[updatesAndInserts addObject: dest];
	
	[self insertOrUpdateItems: updatesAndInserts];
}

- (void) copyEmbeddedObject: (ETUUID*) aUUID
				fromContext: (COPersistentRootEditingContext*) aCtxt
	  toUnorderedCollection: (NSString*)attribute
				   inObject: (ETUUID*)anObject
{
	assert(0);
}


- (ETUUID *) copyEmbeddedObject: (ETUUID*) aUUID
						toIndex: (NSUInteger)i
				   ofCollection: (NSString*)attribute
					   inObject: (ETUUID*)anObject
{
	assert(0);
	return nil;
}

- (ETUUID *) copyEmbeddedObject: (ETUUID*) aUUID
		  toUnorderedCollection: (NSString*)attribute
					   inObject: (ETUUID*)anObject
{
	assert(0);
	return nil;
}


/*

- (void) copyEmbeddedObject: (ETUUID*) aUUID
				fromContext: (COPersistentRootEditingContext*) aCtxt
{
	NILARG_EXCEPTION_TEST(aUUID);
	NILARG_EXCEPTION_TEST(aCtxt);
	
	NSSet *uuids = [self allEmbeddedObjectUUIDsForUUIDInclusive: aUUID];
	for (ETUUID *uuid in uuids)
	{
		COStoreItem *item = [aCtxt storeItemForUUID: uuid];
		
		// FIXME: This assumes that -insertItem doens't check that
		// kCOPrimitiveTypeEmbeddedItem constraints are enforced.
		// Assuming the source context was consistent, our context will
		// be consistent after this loop exits. Need to clarify the
		// guarantees that we can give about kCOPrimitiveTypeEmbeddedItem
		[self insertItem: item];
	}
}

- (ETUUID *) copyEmbeddedObject: (ETUUID *)aUUID
{
	NILARG_EXCEPTION_TEST(aUUID);
	
	NSSet *sourceUUIDs = [self allEmbeddedObjectUUIDsForUUIDInclusive: aUUID];
	NSMutableDictionary *mapping = [NSMutableDictionary dictionaryWithCapacity: [sourceUUIDs count]];
	
	for (ETUUID *sourceUUID in sourceUUIDs)
	{
		[mapping setObject: [ETUUID UUID]
					forKey: sourceUUID];
	}
	
	for (ETUUID *sourceUUID in sourceUUIDs)
	{
		COStoreItem *itemCopy = [[self storeItemForUUID: sourceUUID] mutableCopy];
		for (NSString *key in [itemCopy attributeNames])
		{
			// FIXME:
			// look up the value(s) for 'key' in 'mapping'; if found,
			// replace with the mapped value.
		}
		[self insertItem: itemCopy];
		[itemCopy release];
	}
}
*/

/* @taskunit persistent roots (TODO: move to class?) */

- (ETUUID *) newPersistentRootAtItemPath: (COItemPath*)aPath
{
	COStoreItem *branch = [COStoreItem item];
	COStoreItem *root = [COStoreItem item];
	
	[root setValue: S([branch UUID])
	  forAttribute: @"branches"
			  type: COSetContainerType(kCOPrimitiveTypeEmbeddedItem)];
	
	[root setValue: [COPath pathWithPathComponent:[branch UUID]]
	  forAttribute: @"currentBranch"
			  type: COPrimitiveType(kCOPrimitiveTypePath)];
	
	// FIXME: insert
	
	return [root UUID];
}

- (NSSet *) branchesOfPersistentRoot: (ETUUID *)aRoot
{
	COStoreItem *root = [self storeItemForUUID: aRoot];
	NSSet *set = [root valueForAttribute: @"branches"];
	
	assert([set isKindOfClass: [NSSet class]]);
	assert(![set isKindOfClass: [NSCountedSet class]]);
	
	return set;
}
- (ETUUID *) currentBranchOfPersistentRoot: (ETUUID *)aRoot
{
	COStoreItem *root = [self storeItemForUUID: aRoot];
	COPath *path = [root valueForAttribute: @"currentBranch"];
	
	assert([path isKindOfClass: [COPath class]]);
	// FIXME: check it is a single-element path
	
	return [path lastPathComponent];	
}
- (void) setCurrentBranch: (ETUUID*)aBranch
		forPersistentRoot: (ETUUID*)aRoot
{
	COStoreItem *root = [self storeItemForUUID: aRoot];
	[root setValue: [COPath pathWithPathComponent: aBranch]
	  forAttribute: @"currentBranch"
			  type: COPrimitiveType(kCOPrimitiveTypePath)];
	
	// FIXME: insert
}


- (void) setTrackRemoteBranchOrRoot: (COPath*)aPath
						  forBranch: (ETUUID*)aBranch
{
	COStoreItem *branch = [self storeItemForUUID: aBranch];
	
	[branch setValue: [COPath pathWithPathComponent: aBranch]
	  forAttribute: @"tracking"
			  type: COPrimitiveType(kCOPrimitiveTypePath)];
	
	// FIXME: insert
	
}

- (void) setTrackVersion: (ETUUID*)aVersion
			   forBranch: (ETUUID*)aBranch
{
	COStoreItem *branch = [self storeItemForUUID: aBranch];
	
	[branch setValue: aVersion
	  forAttribute: @"tracking"
			  type: COPrimitiveType(kCOPrimitiveTypeCommitUUID)];
	
	// FIXME: insert
	
}

- (void) undoPersistentRoot: (ETUUID*)aRoot
{
	
}
- (void) redoPersistentRoot: (ETUUID*)aRoot
{
	
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


- (id) plistForEmbeddedObject: (ETUUID*)embeddedObject
					   atPath: (COPath*)aPath
{
	ETUUID *version = [self currentVersionForPersistentRootAtPath: aPath];
	id plist = [self storeItemForEmbeddedObject: embeddedObject inCommit: version];
	
	return plist;
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

- (void) writeUUIDsAndPlists: (NSDictionary*)objects // ETUUID : plist
	 forPersistentRootAtPath: (COPath*)path
					metadata: (id)metadataPlist
{
	// make an absolute path
	COPath *absPath = [self absolutePathForPath: path];
	
	[self _writeUUIDsAndPlists: objects
forPersistentRootAtAbsolutePath: absPath
					  metadata: metadataPlist];
}
#endif

@end
