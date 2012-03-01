#import "COStore.h"
#import "COMacros.h"
#import "COStorePrivate.h"
#import "COPersistentRootEditingContext.h"
#import "COSubtree.h"

@implementation COStore

- (NSString *) rootVersionFile
{
	return [[url path] stringByAppendingPathComponent: @"rootVersion"];
}

- (NSString *) commitLogFile
{
	return [[url path] stringByAppendingPathComponent: @"commitLog"];
}

- (NSString *) commitsDirectory
{
	return [[url path] stringByAppendingPathComponent: @"commits"];
}

- (id)initWithURL: (NSURL*)aURL
{
	self = [super init];
	url = [aURL retain];
	plistForCommitCache = [[NSMutableDictionary alloc] init];
	
	BOOL isDirectory;
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath: [url path]
													   isDirectory: &isDirectory];
	
	if (!exists)
	{
		if (![[NSFileManager defaultManager] createDirectoryAtPath: [self commitsDirectory]
									  withIntermediateDirectories: YES
													   attributes: nil
															error: NULL])
		{
			[self release];
			[NSException raise: NSGenericException
						format: @"Error creating store at %@", [url path]];
			return nil;
		}
	}
	// assume it is a valid store if it exists... (may not be of course)
	
	return self;
}

- (void)dealloc
{
	[plistForCommitCache release];
	[url release];
	[super dealloc];
}

- (NSURL*)URL
{
	return url;
}

/** @taskunit commits */


- (NSArray*) allCommitUUIDs
{
	NSMutableArray *uuids = [NSMutableArray array];
	
	NSArray *arr = [NSArray arrayWithContentsOfFile: [self commitLogFile]];
	
	for (NSString *uuidString in arr)
	{
		ETUUID *uuid = [ETUUID UUIDWithString: uuidString];			
		[uuids addObject: uuid];
	}
	return uuids;
}

- (void) setAllCommitUUIDs: (NSArray*)uuids
{
	NSMutableArray *uuidStrings = [NSMutableArray array];
	for (ETUUID *uuid in uuids)
	{
		[uuidStrings addObject: [uuid stringValue]];
	}
	[uuidStrings writeToFile: [self commitLogFile]
				  atomically: YES];
}

- (ETUUID*) addCommitWithParent: (ETUUID*)parent
                       metadata: (id)metadataPlist
			 UUIDsAndStoreItems: (NSDictionary*)objects
					   rootItem: (ETUUID*)root
{
	NILARG_EXCEPTION_TEST(objects);
	NILARG_EXCEPTION_TEST(root);
	assert([objects objectForKey: root] != nil);
	
	ETUUID *commitUUID = [ETUUID UUID];
	
	NSMutableDictionary *objectsWithStringUUID = [NSMutableDictionary dictionary];
	{
		for (ETUUID *uuid in objects)
		{
			assert([[objects objectForKey: uuid] isKindOfClass: [COItem class]]);
			assert([[[objects objectForKey: uuid] UUID] isEqual: uuid]);
			
			id plist = [[objects objectForKey: uuid] plist];
			[objectsWithStringUUID setObject: plist
									  forKey: [uuid stringValue]];
		}
	}
	
	//NSLog(@"Commit with parent %@", parent);
	
	NSMutableDictionary *plist = [NSMutableDictionary dictionaryWithDictionary: D(
								   [commitUUID stringValue], @"uuid",
								   [root stringValue], @"root",
								   objectsWithStringUUID, @"objects",
								   [NSDate date], @"date")];
	
	if (metadataPlist != nil)
	{
		[plist setObject:metadataPlist forKey: @"metadata"];
	}
	
	if (parent != nil)
	{
		[plist setObject: [parent stringValue] forKey: @"parent"];
	}
	
	NSString *commitFile = [[self commitsDirectory] stringByAppendingPathComponent:
								[commitUUID stringValue]];
	
	if (![plist writeToFile: commitFile
				 atomically: YES])
	{
		[NSException raise: NSInternalInconsistencyException
					format: @"Failed to save commit %@.", plist];
	}
	
	[self setAllCommitUUIDs:
	 [[self allCommitUUIDs] arrayByAddingObject: commitUUID]];
	
	return commitUUID;			
}


- (ETUUID*) addCommitWithParent: (ETUUID*)parent
                       metadata: (id)metadataPlist
						   tree: (COSubtree*)aTree
{
	NSMutableDictionary *uuidsanditems = [NSMutableDictionary dictionary];
	{
		for (COItem *item in [aTree allContainedStoreItems])
		{
			[uuidsanditems setObject: item
							  forKey: [item UUID]];
		}
	}
	
	return [self addCommitWithParent: parent
							metadata: metadataPlist
				  UUIDsAndStoreItems: uuidsanditems
							rootItem: [[aTree root] UUID]];
}

- (NSDictionary *) _plistForCommit: (ETUUID*)commit
{
	{
		id cached = [plistForCommitCache objectForKey: commit];
		if (cached != nil)
		{
			return cached;
		}
	}
	
	
	NSString *commitFile = [[self commitsDirectory] stringByAppendingPathComponent:
							[commit stringValue]];
	
	NSMutableDictionary *plist = [NSMutableDictionary dictionaryWithContentsOfFile: commitFile];
	
	NSMutableDictionary *objectsWithUUID = [NSMutableDictionary dictionary];
	{
		for (NSString *uuidString in [plist objectForKey: @"objects"])
		{
			id objectPlist = [[plist objectForKey: @"objects"] objectForKey: uuidString];
			COItem *item = [[[COItem alloc] initWithPlist: objectPlist] autorelease];
			[objectsWithUUID setObject: item
								forKey: [ETUUID UUIDWithString: uuidString]];
		}
	}
	[plist setObject: objectsWithUUID
			  forKey: @"objects"];
	 
	assert([[plist objectForKey: @"uuid"] isEqualToString: [commit stringValue]]);

	if ([plist objectForKey: @"parent"] != nil)
	{
		[plist setObject: [ETUUID UUIDWithString: [plist objectForKey: @"parent"]]
				  forKey: @"parent"];
	}
	
	[plist setObject: [ETUUID UUIDWithString: [plist objectForKey: @"root"]]
			  forKey: @"root"];
	
	// Cache the result in memory to avoid reading from disk in the future
	// (commits are immutable, so it is safe)
	
	[plistForCommitCache setObject: plist forKey: commit];
	
	return plist;
}
- (ETUUID *) parentForCommit: (ETUUID*)commit
{
	NILARG_EXCEPTION_TEST(commit);
	return [[self _plistForCommit: commit] objectForKey: @"parent"];
}
- (id) metadataForCommit: (ETUUID*)commit
{
	NILARG_EXCEPTION_TEST(commit);
	return [[self _plistForCommit: commit] objectForKey: @"metadata"];	
}
- (NSDate*) dateForCommit: (ETUUID*)commit
{
	NILARG_EXCEPTION_TEST(commit);
	NSDate *aDate = [[self _plistForCommit: commit] objectForKey: @"date"];
	assert([aDate isKindOfClass: [NSDate class]]);
	return aDate;
}
- (NSDictionary *) UUIDsAndStoreItemsForCommit: (ETUUID*)commit
{
	NILARG_EXCEPTION_TEST(commit);
	return [[self _plistForCommit: commit] objectForKey: @"objects"];	
}
- (COSubtree *) treeForCommit: (ETUUID *)aCommit
{
	NILARG_EXCEPTION_TEST(aCommit);
	ETUUID *rootItemUUID = [self rootItemForCommit: aCommit];
	if (rootItemUUID == nil)
	{
		return nil;
	}
	
	NSSet *itemSet = [NSSet setWithArray: [[self UUIDsAndStoreItemsForCommit: aCommit] allValues]];
	
	return [COSubtree subtreeWithItemSet: itemSet
								rootUUID: rootItemUUID];
}
- (COSubtree *) subtreeForUUID: (ETUUID *)aUUID inCommit: (ETUUID *)aCommit
{
	NILARG_EXCEPTION_TEST(aUUID);
	NILARG_EXCEPTION_TEST(aCommit);
	
	// FIXME: naive implementation
	COSubtree *entireTree = [self treeForCommit: aCommit];
	COSubtree *subtree = [entireTree subtreeWithUUID: aUUID];
	
	if (subtree == nil)
	{
		[NSException raise: NSInvalidArgumentException
					format: @"requested UUID not found"];
	}
	return subtree;
}
- (ETUUID *) rootItemForCommit: (ETUUID*)commit
{
	NILARG_EXCEPTION_TEST(commit);
	return [[self _plistForCommit: commit] objectForKey: @"root"];	
}
- (COItem *) storeItemForEmbeddedObject: (ETUUID*)embeddedObject
									inCommit: (ETUUID*)aCommitUUID
{
	NILARG_EXCEPTION_TEST(embeddedObject);
	NILARG_EXCEPTION_TEST(aCommitUUID);
	
	NSDictionary *dict = [self UUIDsAndStoreItemsForCommit: aCommitUUID];
	COItem *item = [dict objectForKey: embeddedObject];

	// may be nil if it isn't in the commit
	return item;
}

/** @taskunit history cleaning */

- (void) deleteCommitsWithUUIDs: (NSSet*)uuids
{
	for (ETUUID *commit in uuids)
	{
		NSString *commitFile = [[self commitsDirectory] stringByAppendingPathComponent:
								[commit stringValue]];
		BOOL removed = [[NSFileManager defaultManager]
							removeItemAtPath: commitFile error: NULL];
		assert(removed);
	}
	
	// FIXME: Inefficient
	
	NSMutableArray *allCommits = [NSMutableArray arrayWithArray: [self allCommitUUIDs]];
	[allCommits removeObjectsInArray: [uuids allObjects]];
	[self setAllCommitUUIDs: allCommits];
}

- (void) deleteParentsOfCommit: (ETUUID*)aCommit
				 olderThanDate: (NSDate*)aDate
{
	assert(0); // unimplemented
}

- (void) _gcMarkVersion: (ETUUID *)aVersion recordInSet: (NSMutableSet *)markedVersions
{
	if ([markedVersions containsObject: aVersion])
	{
		return;
	}
	else
	{
		[markedVersions addObject: aVersion];
	}

	ETUUID *parent = [self parentForCommit: aVersion];
	if (parent != nil)
	{
		[self _gcMarkVersion: parent recordInSet: markedVersions];
	}
	
	NSDictionary *embeddedObjects = [self UUIDsAndStoreItemsForCommit: aVersion];
	for (COItem *item in [embeddedObjects allValues])
	{
		for (NSString *attribute in [item attributeNames])
		{
			if ([[item typeForAttribute: attribute] isPrimitiveTypeEqual: [COType commitUUIDType]])
			{
				for (ETUUID *aValue in [item allObjectsForAttribute: attribute])
				{
					[self _gcMarkVersion: aValue recordInSet: markedVersions];
				}
			}
		}
	}
}

- (void) gc
{
	NSMutableSet *markedVersions = [NSMutableSet set];
	[self _gcMarkVersion: [self rootVersion] recordInSet: markedVersions];
	
	NSMutableSet *unreachableVersions = [NSMutableSet setWithArray: [self allCommitUUIDs]];
	[unreachableVersions minusSet: markedVersions];
	
	//NSLog(@"GC found the following unreachable commits: %@", unreachableVersions);
	
	[self deleteCommitsWithUUIDs: unreachableVersions];
}

- (ETUUID *) rootVersion
{
	NSString *str = [NSString stringWithContentsOfFile: [self rootVersionFile] 
											  encoding: NSUTF8StringEncoding
												 error: NULL];
	if (str != nil)
	{
		return [ETUUID UUIDWithString: str];
	}
	else
	{
		return nil;
	}
}
- (void) setRootVersion: (ETUUID*)version
{
	NILARG_EXCEPTION_TEST(version);
	[[version stringValue] writeToFile: [self rootVersionFile] 
							atomically: YES
							  encoding: NSUTF8StringEncoding
								 error: NULL];
}

/** @taskunit accessing the root context */

- (COPersistentRootEditingContext *) rootContext
{
	return [COPersistentRootEditingContext editingContextForEditingTopLevelOfStore: self];
}

- (NSSet*) commitsMatchingQuery: (NSString*)aQuery
{
	// FIXME:
	return nil;
}

- (BOOL) isCommit: (ETUUID *)testParent parentOfCommit: (ETUUID *)testChild
{	
	ETUUID *temp = testChild;
	
	do
	{
		if ([temp isEqual: testParent])
		{
			return YES;
		}
		temp = [self parentForCommit: temp];
	}
	while (temp != nil);
	
	return NO;
}

@end
