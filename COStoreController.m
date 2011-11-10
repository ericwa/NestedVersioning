#import "COStoreController.h"
#import "Common.h"

@implementation COStoreController

- (id)initWithStore:(COStore *)aStore
{
	SUPERINIT;
	ASSIGN(store, aStore);
	return self;
}

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

		id embeddedObjectPlist = [self plistForEmbeddedObject: lastPathComponent
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
					 inCommit: (ETUUID*)aCommitUUID
{
	NILARG_EXCEPTION_TEST(embeddedObject);
	NILARG_EXCEPTION_TEST(aCommitUUID);
	
	NSDictionary *dict = [store UUIDsAndPlistsForCommit: aCommitUUID];
	id plist = [dict objectForKey: embeddedObject];
	
	if (plist == nil)
	{
		[NSException raise: NSInvalidArgumentException
					format: @"%@ not found in commit %@", embeddedObject, aCommitUUID];
	}
	
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

@end
