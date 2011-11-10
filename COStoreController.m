#import "COStoreController.h"
#import "Common.h"

@implementation COStoreController

- (id)initWithStore:(COStore *)aStore
{
	SUPERINIT;
	ASSIGN(store, aStore);
	return self;
}

/**
 * see comment in header
 */
- (ETUUID*) currentVersionForPersistentRootAtPath: (COPath*)path
{
	// NOTE: If we want special handling for top-level persistent roots (children of /),
	// this method is where we would do it
	if ([path isEmpty])
	{
		return [store rootVersion];
	}
	else
	{
		COPath *parent = [path pathByDeletingLastPathComponent];
		ETUUID *lastPathComponent = [path lastPathComponent];
		
		// recursive call to ourself to find the version containing the last
		// path component.
		ETUUID *parentCurrentVersion = [self currentVersionForPersistentRootAtPath: parent];

		id embeddedObjectPlist = [self plistForEmbeddedObject: lastPathComponent
													 inCommit: parentCurrentVersion];
		
		
		NSString *type = [embeddedObjectPlist objectForKey: @"type"];
		
		if ([type isEqualToString: @"root"])
		{
			NSString *trackingType = [embeddedObjectPlist objectForKey: @"tracking-type"];
			NSString *tracking = [embeddedObjectPlist objectForKey: @"tracking"];
			if ([trackingType isEqualToString: @"owned-branch"])
			{
				// tracking is a single UUID of the branch.
				id branchPlist = [self plistForEmbeddedObject: [ETUUID UUIDWithString: tracking]
													 inCommit: parentCurrentVersion];
				
				ETUUID *uuid = [ETUUID UUIDWithString:
								[branchPlist objectForKey: @"version"]];
				return uuid;
			}
			else if ([trackingType isEqualToString: @"remote-root"] ||
					 [trackingType isEqualToString: @"remote-branch"])
			{
				// tracking is a full path to a branch/root in another persistent root
				
				COPath *trackingPath = [COPath pathWithString: tracking];
				
				// FIXME: could be an infinite loop if a root is tracking itself.
				return [self currentVersionForPersistentRootAtPath: trackingPath];
			}
			else if ([trackingType isEqualToString: @"version"])
			{
				// tracking is a version, so effectively the persistent root is just a branch
				
				ETUUID *uuid = [ETUUID UUIDWithString: tracking];
				return uuid;
			}

			[NSException raise: NSInternalInconsistencyException
						format: @"unsupported tracking type %@: %@", trackingType, tracking];
		}
		else if ([type isEqualToString: @"branch"])
		{
			ETUUID *uuid = [ETUUID UUIDWithString:
								[embeddedObjectPlist objectForKey: @"version"]];
			return uuid;
		}
		
		[NSException raise: NSInternalInconsistencyException
					format: @"failed to parse %@", embeddedObjectPlist];
		return nil;
	}
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

// helper method for modifying a persistent root plist
- (id) _updatePersistentRootPlist: (id)plist
		toPointToNewVersion: (ETUUID*)newVersion
{
	NSString *type = [embeddedObjectPlist objectForKey: @"type"];
	
	if ([type isEqualToString: @"root"])
	{
		NSString *trackingType = [embeddedObjectPlist objectForKey: @"tracking-type"];
		NSString *tracking = [embeddedObjectPlist objectForKey: @"tracking"];
		if ([trackingType isEqualToString: @"owned-branch"])
		{
			// tracking is a single UUID of the branch.
			id branchPlist = [self plistForEmbeddedObject: [ETUUID UUIDWithString: tracking]
												 inCommit: parentCurrentVersion];
			
			ETUUID *uuid = [ETUUID UUIDWithString:
							[branchPlist objectForKey: @"version"]];
			return uuid;
		}
		else if ([trackingType isEqualToString: @"remote-root"] ||
				 [trackingType isEqualToString: @"remote-branch"])
		{
			// tracking is a full path to a branch/root in another persistent root
			
			COPath *trackingPath = [COPath pathWithString: tracking];
			
			// FIXME: could be an infinite loop if a root is tracking itself.
			return [self currentVersionForPersistentRootAtPath: trackingPath];
		}
		else if ([trackingType isEqualToString: @"version"])
		{
			// tracking is a version, so effectively the persistent root is just a branch
			
			ETUUID *uuid = [ETUUID UUIDWithString: tracking];
			return uuid;
		}
		
		[NSException raise: NSInternalInconsistencyException
					format: @"unsupported tracking type %@: %@", trackingType, tracking];
	}
	else if ([type isEqualToString: @"branch"])
	{
		ETUUID *uuid = [ETUUID UUIDWithString:
						[embeddedObjectPlist objectForKey: @"version"]];
		return uuid;
	}
	
	[NSException raise: NSInternalInconsistencyException
				format: @"failed to parse %@", embeddedObjectPlist];
}


- (void) writeUUIDsAndPlists: (NSDictionary*)objects // ETUUID : plist
	 forPersistentRootAtPath: (COPath*)path
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
		
		[self writeUUIDsAndPlists: parentCommitObjects
		  forPersistentRootAtPath: parentPath
					 metadata: md];
	}
}

@end
