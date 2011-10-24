#import "COStore.h"
#import "FMDatabase.h"
#import "Common.h"

@implementation COStore

- (id)initWithURL: (NSURL*)aURL
{
	self = [super init];
	url = [aURL retain];
	db = [[FMDatabase alloc] initWithPath: [url path]];
	commitObjectForID = [[NSMutableDictionary alloc] init];

	if (![self setupDB])
	{
		NSLog(@"DB Create Failed");
		[self release];
		return nil;
	}
	return self;
}

- (void)dealloc
{
	[commitObjectForID release];
	[url release];
	[db release];
	[super dealloc];
}

- (NSURL*)URL
{
	return url;
}

/* DB Setup */

void CHECK(id db)
{
	if ([db hadError]) { 
		NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]); 
	}
}

- (BOOL)setupDB
{
	// FIXME: Not sure whether to use or not.
	//[db setShouldCacheStatements: YES];
	
	if (![db open])
	{
		NSLog(@"couldn't open db at %@", url);
		return NO;
	}
	
	BOOL success = YES;

	// Should improve performance
#if 0	
	FMResultSet *setToWAL = [db executeQuery: @"PRAGMA journal_mode=WAL"];
	[setToWAL next];
	if (![@"wal" isEqualToString: [setToWAL stringForColumnIndex: 0]])
	{
		NSLog(@"Enabling WAL mode failed.");
	}
	[setToWAL close];
#endif	
	
	FMResultSet *storeVersionRS = [db executeQuery: @"SELECT version FROM storeMetadata"];
	if ([storeVersionRS next])
	{
		int ver = [storeVersionRS intForColumnIndex: 0];
		[storeVersionRS close];
		
		if (ver != 1)
		{
			NSLog(@"Error: unsupported store version %d", ver);
			return NO;
		}
		// DB is already set up.
		return YES;
	}
	else
	{
		[storeVersionRS close];
	}
	
	
	// Otherwise, set up the DB
	
	success = success && [db executeUpdate: @"CREATE TABLE storeMetadata(version INTEGER)"]; CHECK(db);
	success = success && [db executeUpdate: @"INSERT INTO storeMetadata(version) VALUES(1)"]; CHECK(db);
	
	// Instead of storing UUIDs and property names thoughout the database,
	// we store them in two tables, and use integer ID's to refer to those
	// UUIDs/property names.
	
	success = success && [db executeUpdate: @"CREATE TABLE uuids(uuidIndex INTEGER PRIMARY KEY, uuid STRING, rootIndex INTEGER)"]; CHECK(db);
	success = success && [db executeUpdate: @"CREATE INDEX uuidsIndex ON uuids(uuid)"]; CHECK(db);

	success = success && [db executeUpdate: @"CREATE TABLE properties(propertyIndex INTEGER PRIMARY KEY, property STRING)"]; CHECK(db);
	success = success && [db executeUpdate: @"CREATE INDEX propertiesIndex ON properties(property)"]; CHECK(db);
	
	// One table for storing the actual commit data (values/keys modified in each commit)
	//
	// Explanation of full-text search:
	// The FTS3 table actually has two columns: rowid, which is an integer primary key,
	// and content, which is the string content which will be indexed.
	//
	// Each row inserted in to the commits table will specifies a {property : value} tuple
	// for a given object modified in a given commit, and the rows are identified by the
	// commitrow column. So when we insert a row in to commits that we want to be searchable,
	// we also insert into the commitsTextSearch table (commitrow, <text to be indexed>).
	// 
	// To get full-text search results, we search for text in the commitsTextSearch table, which
	// gives us a table of commitrow integers, which we can look up in the commits table for the
	// actual search results. 
	
	
	success = success && [db executeUpdate: @"CREATE TABLE commits(commitrow INTEGER PRIMARY KEY, revisionnumber INTEGER, objectuuid INTEGER, property INTEGER, value BLOB)"]; CHECK(db);
	success = success && [db executeUpdate: @"CREATE INDEX commitsIndex ON commits(revisionnumber)"]; CHECK(db);	
	success = success && [db executeUpdate: @"CREATE VIRTUAL TABLE commitsTextSearch USING fts3()"];	 CHECK(db);
	
	// One table for storing commit metadata
	
	success = success && [db executeUpdate: @"CREATE TABLE commitMetadata(revisionnumber INTEGER PRIMARY KEY, baserevisionnumber INTEGER, plist BLOB)"];CHECK(db);
		
	// Commit Track node table
	success = success && [db executeUpdate: @"CREATE TABLE commitTrackNode(committracknodeid INTEGER PRIMARY KEY, objectuuid INTEGER, revisionnumber INTEGER, nextnode INTEGER, prevnode INTEGER)"]; CHECK(db);
	// Commit Track table 
	success = success && [db executeUpdate: @"CREATE TABLE commitTrack(objectuuid INTEGER PRIMARY KEY, currentnode INTEGER)"]; CHECK(db);
	return success;
}

- (NSNumber*)keyForUUID: (ETUUID*)uuid
{
	if (uuid == nil)
	{
		return nil;
	}
	
	int64_t key;
	NSString *string = [uuid stringValue];
	assert([string isKindOfClass: [NSString class]]);
    FMResultSet *rs = [db executeQuery:@"SELECT uuidIndex FROM uuids WHERE uuid = ?", string];
	if ([rs next])
	{
		key = [rs longLongIntForColumnIndex: 0];
		[rs close];
	}
	else
	{
		[rs close];
		if (rootInProgress != nil)
		{
			[db executeUpdate: @"INSERT INTO uuids VALUES(NULL, ?, ?)", 
			                   [uuid stringValue], rootInProgress];
		}
		else
		{
			// TODO: Not really pretty... Try to merge -insertRootUUID: with 
			// -keyForUUID: to eliminate this branch
			[db executeUpdate: @"INSERT INTO uuids VALUES(NULL, ?, NULL)", [uuid stringValue]];
		}
		key = [db lastInsertRowId];
	}
	return [NSNumber numberWithLongLong: key];
}

- (NSNumber*)keyForProperty: (NSString*)property
{
	if (property == nil)
	{
		return nil;
	}
	
	int64_t key;
    FMResultSet *rs = [db executeQuery:@"SELECT propertyIndex FROM properties WHERE property = ?", property];
	if ([rs next])
	{
		key = [rs longLongIntForColumnIndex: 0];
		[rs close];
	}
	else
	{
		[rs close];
		[db executeUpdate: @"INSERT INTO properties VALUES(NULL, ?)", property];
		key = [db lastInsertRowId];
	}  
	return [NSNumber numberWithLongLong: key];
}

- (ETUUID*)UUIDForKey: (int64_t)key
{
	ETUUID *result = nil;
    FMResultSet *rs = [db executeQuery:@"SELECT uuid FROM uuids WHERE uuidIndex = ?",
					   [NSNumber numberWithLongLong: key]];
	if ([rs next])
	{
		result = [ETUUID UUIDWithString: [rs stringForColumnIndex: 0]];
	}
	[rs close];
	return result;
}

- (NSString*)propertyForKey: (int64_t)key
{
	NSString *result = nil;
    FMResultSet *rs = [db executeQuery:@"SELECT property FROM properties WHERE propertyIndex = ?",
					   [NSNumber numberWithLongLong: key]];
	if ([rs next])
	{
		result = [rs stringForColumnIndex: 0];
	}
	[rs close];
	return result;
}

/* Content  */

- (BOOL)isRootObjectUUID: (ETUUID *)uuid
{
	NILARG_EXCEPTION_TEST(uuid);
    FMResultSet *rs = [db executeQuery: @"SELECT uuid FROM uuids WHERE uuidIndex = ? AND rootIndex = uuidIndex",
	                                    [self keyForUUID: uuid]];
	BOOL result = [rs next];
	[rs close];
	return result;
}

- (NSSet *)rootObjectUUIDs
{
    FMResultSet *rs = [db executeQuery: @"SELECT uuid FROM uuids WHERE rootIndex = uuidIndex"];
	NSMutableSet *result = [NSMutableSet set];

	while ([rs next])
	{
		[result addObject: [ETUUID UUIDWithString: [rs stringForColumn: @"uuid"]]];
	}

	[rs close];
	return result;
}

- (NSSet *)UUIDsForRootObjectUUID: (ETUUID *)aUUID
{
	NILARG_EXCEPTION_TEST(aUUID);
    FMResultSet *rs = [db executeQuery: @"SELECT uuid FROM uuids WHERE rootIndex = ?", [self keyForUUID: aUUID]];
	NSMutableSet *result = [NSMutableSet set];

	while ([rs next])
	{
		[result addObject: [ETUUID UUIDWithString: [rs stringForColumn: @"uuid"]]];
	}
	assert([result containsObject: aUUID]);

	[rs close];
	return result;
}

- (NSSet*)UUIDsForRootObjectUUID: (ETUUID*)aUUID atRevision: (CORevision*)revision
{
	// FIXME: This may need to be optimised by storing a list of object UUIDs
	// at some revisions.
	NSMutableSet *uuids = [NSMutableSet set];
	while (revision != nil)
	{
    		FMResultSet *rs = [db executeQuery: @"SELECT uuid FROM uuids JOIN commits ON uuids.uuidindex = commits.objectuuid "
			"WHERE rootindex = ? AND revisionnumber = ?", 
			[self keyForUUID: aUUID], [NSNumber numberWithLongLong: [revision revisionNumber]]]; CHECK(db);
		while ([rs next])
		{
			[uuids addObject: [ETUUID UUIDWithString: [rs stringForColumn: @"uuid"]]];
		}
		revision = [revision baseRevision];
	}
	return uuids;
}

- (ETUUID *)rootObjectUUIDForUUID: (ETUUID *)aUUID
{
	NILARG_EXCEPTION_TEST(aUUID);
    FMResultSet *rs = [db executeQuery: @"SELECT uuid FROM uuids WHERE uuidIndex = "
		"(SELECT rootIndex FROM uuids WHERE uuid = ?)", aUUID];
	ETUUID *result = nil;
	
	if ([rs next])
	{
		result = [ETUUID UUIDWithString: [rs stringForColumn: @"uuid"]];
		/* We expect a single result */
		assert([rs next] == NO);
	}

	[rs close];
	return result;
}

- (void)insertRootObjectUUID: (ETUUID *)uuid
{
	NILARG_EXCEPTION_TEST(uuid);
	
	NSString *uuidString = [uuid stringValue];
	assert([uuidString isKindOfClass: [NSString class]]);
    FMResultSet *rs = [db executeQuery: @"SELECT uuidIndex FROM uuids WHERE uuid = ?", uuidString];
	BOOL wasInsertedPreviously = [rs next];

	[rs close];

	if (wasInsertedPreviously)
	{
		[NSException raise: NSInvalidArgumentException 
		            format: @"The persistent root UUID %@ was inserted previously.", uuid];
		return;
	}
	
	// TODO: Merge UPDATE into INSERT if possible
	[db executeUpdate: @"INSERT INTO uuids VALUES(NULL, ?, NULL)", [uuid stringValue]];
	int64_t key = [db lastInsertRowId];
	[db executeUpdate: @"UPDATE uuids SET rootIndex = ? WHERE uuidIndex = ?", 
		[NSNumber numberWithLongLong: key], [NSNumber numberWithLongLong: key]];
}

// TODO: Rewrite to be handled in two transactions (SELECT and INSERT)
- (void) insertRootObjectUUIDs: (NSSet *)UUIDs
{
	for (ETUUID *uuid in UUIDs)
	{
		[self insertRootObjectUUID: uuid];
	}
}

/* Committing Changes */

- (void)beginCommitWithMetadata: (NSDictionary *)metadata
                 rootObjectUUID: (ETUUID *)rootUUID
		   baseRevision: (CORevision*)baseRevision
				 
{
	NSNumber *baseRevisionNumber = nil;
	if (nil != baseRevision)
	{
		baseRevisionNumber = [NSNumber numberWithLongLong: [baseRevision revisionNumber]];
	}
	if (nil == metadata)
	{
		// Needed because GNUstep persists nil so that it loads again as @"nil"
		metadata = [NSDictionary dictionary];
	}
	if (commitInProgress != nil)
	{
		[NSException raise: NSGenericException format: @"Attempt to call -beginCommitWithMetadata: while a commit is already in progress."];
	}
	if ([self isRootObjectUUID: rootUUID] == NO)
	{
		[NSException raise: NSGenericException format: @"The object UUID %@ is not listed among the root objects.", rootUUID];	
	}

	NSMutableDictionary *commitMetadata = [NSMutableDictionary dictionaryWithDictionary: metadata];

	[commitMetadata addEntriesFromDictionary: 
		[NSDictionary dictionaryWithObjectsAndKeys:
            [[ETUUID UUID] stringValue], @"UUID",
            [NSDate date], @"date",
            [rootUUID stringValue], @"objectUUID"]];

	NSData *data = [NSPropertyListSerialization dataFromPropertyList: commitMetadata
															  format: NSPropertyListXMLFormat_v1_0
													errorDescription: NULL];
	
	[db beginTransaction];

	[db executeUpdate: @"INSERT INTO commitMetadata(plist, baserevisionnumber) VALUES(?, ?)",
		data, baseRevisionNumber];

	commitInProgress = [[NSNumber numberWithUnsignedLongLong: [db lastInsertRowId]] retain];
	ASSIGN(rootInProgress, [self keyForUUID: rootUUID]);
}

- (void)beginChangesForObjectUUID: (ETUUID*)object
{
	if (commitInProgress == nil)
	{
		[NSException raise: NSGenericException format: @"Start a commit first"];
	}
	if (objectInProgress != nil)
	{
		[NSException raise: NSGenericException format: @"Finish the current object first"];
	}
	objectInProgress = [object retain];
}

- (void)setValue: (id)value
	 forProperty: (NSString*)property
		ofObject: (ETUUID*)object
	 shouldIndex: (BOOL)shouldIndex
{
	if (commitInProgress == nil)
	{
		[NSException raise: NSGenericException format: @"Start a commit first"];
	}
	if (![objectInProgress isEqual: object])
	{
		[NSException raise: NSGenericException format: @"Object in progress doesn't match"];
	}

	NSData *data = [NSPropertyListSerialization 
		dataFromPropertyList: value
		              format: NSPropertyListXMLFormat_v1_0
		    errorDescription: NULL];	
	if (data == nil && value != nil)
	{
		[NSException raise: NSInvalidArgumentException format: @"Error serializing object %@", value];
	}
	//NSLog(@"STORE WRITE (%@) object %@, property %@, value %@", commitInProgress, object, property, value);

	[db executeUpdate: @"INSERT INTO commits(commitrow, revisionnumber, objectuuid, property, value) VALUES(NULL, ?, ?, ?, ?)",
		commitInProgress,
		[self keyForUUID: objectInProgress],
		[self keyForProperty: property],
		data];
	CHECK(db);
	
	if (shouldIndex)
	{
		if ([value isKindOfClass: [NSString class]])
		{
			int64_t commitrow = [db lastInsertRowId];
			
			[db executeUpdate: @"INSERT INTO commitsTextSearch(docid, content) VALUES(?, ?)",
			 [NSNumber numberWithLongLong: commitrow],
			 value];
			CHECK(db);
		}
		else
		{
			NSLog(@"Error, only strings can be indexed.");
		}
	}

	hasPushedChanges = YES;
}

- (void)finishChangesForObjectUUID: (ETUUID*)object
{
	if (commitInProgress == nil)
	{
		[NSException raise: NSGenericException format: @"Start a commit first"];
	}
	if (![objectInProgress isEqual: object])
	{
		[NSException raise: NSGenericException format: @"Object in progress doesn't match"];
	}
	if (!hasPushedChanges)
	{
		// TODO: Turn on this exception
		//[NSException raise: NSGenericException format: @"Push changes before finishing the commit"];
	}
	[objectInProgress release];
	objectInProgress = nil;
	hasPushedChanges = NO;
}

- (CORevision*)finishCommit
{
	if (objectInProgress != nil)
	{
		[NSException raise: NSGenericException format: @"Object still in progress"];
	}
	if (commitInProgress == nil)
	{
		[NSException raise: NSGenericException format: @"Start a commit first"];
	}
	[self updateCommitTrackForRootObjectUUID: rootInProgress newRevision: commitInProgress];
	[db commit];
	
	CORevision *result = [self revisionWithRevisionNumber: [commitInProgress unsignedLongLongValue]];
	
	[commitInProgress release];
    commitInProgress = nil;
	[rootInProgress release];
    rootInProgress = nil;
	return result;
}

/* Accessing History Graph and Committed Changes */

- (CORevision*)revisionWithRevisionNumber: (uint64_t)anID
{
	NSNumber *idNumber = [NSNumber numberWithUnsignedLongLong: anID];
	CORevision *result = [commitObjectForID objectForKey: idNumber];
	if (result == nil)
	{
		FMResultSet *rs = [db executeQuery:@"SELECT revisionnumber, baserevisionnumber FROM commitMetadata WHERE revisionnumber = ?",
						   idNumber];
		if ([rs next])
		{
			int64_t baseRevisionNumber = [rs longLongIntForColumnIndex: 1];
			CORevision *commitObject = [[[CORevision alloc] initWithStore: self revisionNumber: anID baseRevisionNumber: baseRevisionNumber] autorelease];
			[commitObjectForID setObject: commitObject
								  forKey: idNumber];
			result = commitObject;
		}
		[rs close];
	}
	return result;
}

- (NSArray *)revisionsForObjectUUIDs: (NSSet *)uuids
{
	NSMutableArray *revs = [NSMutableArray array];
	NSMutableArray *idNumbers = [NSMutableArray array];

	// TODO: Slow and ugly... Can probably be eliminated with a Join-like operation.
	for (ETUUID *uuid in uuids)
	{
		[idNumbers addObject: [self keyForUUID: uuid]];
	}

	NSString *formattedIdNumbers = [[[idNumbers stringValue] 
		componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]] 
		componentsJoinedByString: @""];
	// NOTE: We use a distinct query string because -executeQuery returns nil with 'WHERE xyz IN ?'
	NSString *query = [NSString stringWithFormat: @"SELECT DISTINCT revisionnumber, baseRevisionNumber FROM commits WHERE objectUUID IN %@ ORDER BY revisionnumber", formattedIdNumbers];
	FMResultSet *rs = [db executeQuery: query];

	while ([rs next])
	{
		uint64_t result = [rs longLongIntForColumnIndex: 0];
		uint64_t baseRevision = [rs longLongIntForColumnIndex: 1];
		CORevision *rev = [[[CORevision alloc] 
			     initWithStore: self 
			    revisionNumber: result 
			baseRevisionNumber: baseRevision] 
				autorelease];

		[revs addObject: rev];
	}
	[rs close];

	return revs;
}

/* Full-text Search */

- (NSArray*)resultDictionariesForQuery: (NSString*)query
{
	NSMutableArray *results = [NSMutableArray array];
	FMResultSet *rs = [db executeQuery:@"SELECT rowid FROM commitsTextSearch WHERE content MATCH ?", query];
	CHECK(db);
	while ([rs next])
	{
		int64_t rowIndex = [rs longLongIntForColumnIndex: 0];
		FMResultSet *commitRs = [db executeQuery:@"SELECT revisionnumber, objectuuid, property FROM commits WHERE commitrow = ?", 
			[NSNumber numberWithLongLong: rowIndex]];
		if ([commitRs next])
		{
			int64_t commitKey = [commitRs longLongIntForColumnIndex: 0];
			int64_t objectKey = [commitRs longLongIntForColumnIndex: 1];
			int64_t propertyKey = [commitRs longLongIntForColumnIndex: 2];
			
			NSNumber *revisionNumber = [NSNumber numberWithLongLong: commitKey];
			ETUUID *objectUUID = [self UUIDForKey: objectKey];
			NSString *property = [self propertyForKey: propertyKey];
			NSString *value = [[[self revisionWithRevisionNumber: commitKey] valuesAndPropertiesForObjectUUID: objectUUID] objectForKey: property];
			
			assert(revisionNumber != nil);
			assert(objectUUID != nil);
			assert(property != nil);
			assert(value != nil && [value isKindOfClass: [NSString class]]);
					
			[results addObject: 
				[NSDictionary dictionaryWithObjectsAndKeys:
					revisionNumber, @"revisionNumber",
					objectUUID, @"objectUUID",
					property, @"property",
				    value, @"value",
					nil]];
		}
		else
		{
			[NSException raise: NSInternalInconsistencyException format: @"FTS table refers to a non-existent commit"];
		}
		[commitRs close];
	}
	[rs close];
	
	return results;
}

/* Revision history */

- (uint64_t) latestRevisionNumber
{
	FMResultSet *rs = [db executeQuery:@"SELECT MAX(revisionnumber) FROM commitMetadata"];
	uint64_t num = 0;
	if ([rs next])
	{
		num = [rs longLongIntForColumnIndex: 0];
	}
	[rs close];
	return num;
}

- (CORevision*)createCommitTrackForRootObjectUUID: (NSNumber*)uuidIndex
                                    currentNodeId: (int64_t*)pCurrentNodeId
{
	int64_t currentNodeId;
	// TODO: (Chris) Determine if we should use the latest revision number of the store
	// or the last revision number the object occurs in. Really, if we create
	// a commit track for every object, this issue shouldn't arise.
	CORevision *revision = [self revisionWithRevisionNumber: [self latestRevisionNumber]];
#ifdef GNUSTEP
	NSDebugLLog(@"COStore", @"Creating commit track for object %@", [self UUIDForKey: [uuidIndex longLongValue]]);
#endif
	[db executeUpdate: @"INSERT INTO commitTrackNode(committracknodeid, objectuuid, revisionnumber, nextnode, prevnode) VALUES (NULL, ?, ?, NULL, NULL)",
		uuidIndex, [NSNumber numberWithLongLong: [revision revisionNumber]]]; CHECK(db);
	currentNodeId = [db lastInsertRowId];
	[db executeUpdate: @"INSERT INTO commitTrack(objectuuid, currentnode) VALUES (?, ?)", 
		uuidIndex, [NSNumber numberWithLongLong: currentNodeId]]; CHECK(db);
	if (pCurrentNodeId)
		*pCurrentNodeId = currentNodeId;
	return revision;
}

- (CORevision*)commitTrackForRootObject: (NSNumber*)objectUUIDIndex
                            currentNode: (int64_t*)pCurrentNode
                           previousNode: (int64_t*)pPreviousNode
                               nextNode: (int64_t*)pNextNode
{
	FMResultSet *rs = [db executeQuery: @"SELECT commitTrack.objectuuid, currentnode, revisionnumber, nextnode, prevnode FROM commitTrack JOIN commitTrackNode ON committracknodeid = currentnode WHERE commitTrack.objectuuid = ?", objectUUIDIndex]; CHECK(db);
	if ([rs next])
	{
		if (pCurrentNode)
			*pCurrentNode = [rs longLongIntForColumnIndex: 1];

		if (pPreviousNode) 
			*pPreviousNode = [rs longLongIntForColumnIndex: 4];
		if (pNextNode)
			*pNextNode =[rs longLongIntForColumnIndex: 3];
		int64_t revisionnumber = [rs longLongIntForColumnIndex: 2];
		return [self revisionWithRevisionNumber: revisionnumber];
	}
	return nil;
}

/**
  * Load the revision numbers for a root object along its commit track.
  * The resulting array of revisions will be (forward + backward + 1) elements
  * long, with the revisions ordered from oldest to last.
  * revision may optionally be nil to find a commit track for an object
  * (or create one if it doesn't exist).
  * 
  * The current implementation is quite inefficient in that it hits the
  * database (forward + backward + 1) time, once for each
  * revision on the commit track.
 */
- (NSArray*)loadCommitTrackForObject: (ETUUID*)objectUUID
                        fromRevision: (CORevision*)revision
                        nodesForward: (NSUInteger)forward
                       nodesBackward: (NSUInteger)backward
{
	NILARG_EXCEPTION_TEST(objectUUID);
	if (![self isRootObjectUUID: objectUUID])
		[NSException raise: NSInvalidArgumentException format: @"The object with UUID %@ does not exist!", objectUUID];

	NSMutableArray *nodes = [[NSMutableArray alloc] initWithCapacity: (1 + forward + backward)];
	NSNumber *objectUUIDIndex = [self keyForUUID: objectUUID];
	int64_t nextNode, prevNode;
	int64_t currentNode;	
	if (nil == revision)
	{
		revision = [self commitTrackForRootObject: objectUUIDIndex currentNode: &currentNode previousNode: &prevNode nextNode: &nextNode];
		if (nil == revision)
		{
			revision = [self createCommitTrackForRootObjectUUID: objectUUIDIndex currentNodeId: &currentNode];
			prevNode = nextNode = 0;
		}
	}

	// Insert the middle mode (revision)
	[nodes addObject: revision];
	
	// Retrieve the backward revisions along the track (starting at the middle node)
	for (int i = 0; i < backward; i++)
	{
		FMResultSet *rs = [db executeQuery: @"SELECT revisionnumber, prevnode FROM commitTrackNode WHERE objectuuid = ? AND committracknodeid = ?", objectUUIDIndex, [NSNumber numberWithLongLong: prevNode]]; CHECK(db);
		if ([rs next])
		{
			prevNode = [rs longLongIntForColumnIndex: 1];
			revision = [self revisionWithRevisionNumber: [rs longLongIntForColumnIndex: 0]];
			[nodes insertObject: revision atIndex: 0];
		}
		else
		{
			for (int j = i; j < backward; j++)
			{
				[nodes insertObject: [NSNull null] atIndex: 0];
			}
			break;
		}
	}
	
	// Retrieve the forward revisions on the track
	for (int i = 0; i < forward; i++)
	{
		FMResultSet *rs = [db executeQuery: @"SELECT revisionnumber, nextnode FROM commitTrackNode WHERE objectuuid = ? AND committracknodeid = ?", objectUUIDIndex, [NSNumber numberWithLongLong: nextNode]]; CHECK(db);
		if ([rs next])
		{
			nextNode = [rs longLongIntForColumnIndex: 1];
			revision = [self revisionWithRevisionNumber: [rs longLongIntForColumnIndex: 0]];
			[nodes addObject: revision];
		}
		else
		{
			for (int j = i; j < forward; j++)
			{
				[nodes addObject: [NSNull null]];
			}
			break;
		}
	}
	return [nodes autorelease];
}

- (void)updateCommitTrackForRootObjectUUID: (NSNumber*)rootObjectIndex
                               newRevision: (NSNumber*)newRevision
{
	int64_t oldNodeInt;
	CORevision *oldRev = 
		[self commitTrackForRootObject: rootObjectIndex
		                   currentNode: &oldNodeInt
				  previousNode: NULL
		                      nextNode: NULL];
	if (oldRev)
	{
		NSNumber* oldNode = [NSNumber numberWithLongLong: oldNodeInt];
		NSNumber* newNode;
		
		[db executeUpdate: @"INSERT INTO commitTrackNode(committracknodeid, objectuuid, revisionnumber, prevnode, nextnode) VALUES (NULL, ?, ?, ?, NULL)",
			rootObjectIndex, 
			newRevision, 
			oldNode]; CHECK(db);
		newNode = [NSNumber numberWithLongLong: [db lastInsertRowId]];
		[db executeUpdate: @"UPDATE commitTrackNode SET nextnode = ? WHERE committracknodeid = ? AND objectuuid = ?",
			newNode, oldNode, rootObjectIndex]; CHECK(db);
		[db executeUpdate: @"UPDATE commitTrack SET currentnode = ? WHERE objectuuid = ?",
			newNode, rootObjectIndex]; CHECK(db);
#ifdef GNUSTEP
		NSDebugLLog(@"COStore", @"Updated commit track for %@ - created new commit track node %@ pointed to by %@ for revision %@",
			[self UUIDForKey: [rootObjectIndex longLongValue]], newNode, oldNode, newRevision); 
#endif
	}
	else
	{
		[self createCommitTrackForRootObjectUUID: rootObjectIndex currentNodeId: NULL];
	}
}
- (CORevision*)undoOnCommitTrack: (ETUUID*)rootObjectUUID
{
	NSNumber *rootObjectIndex = [self keyForUUID: rootObjectUUID];
	FMResultSet *rs = [db executeQuery: @"SELECT prevnode FROM commitTrack ct JOIN commitTrackNode ctn ON ct.currentNode = ctn.committracknodeid "
		"WHERE ct.objectuuid = ?", rootObjectIndex]; CHECK(db);
	if ([rs next])
	{
		NSNumber *prevNode = [NSNumber numberWithLongLong: [rs longLongIntForColumnIndex: 0]];
		if ([prevNode longLongValue]== 0)
			[NSException raise: NSInvalidArgumentException
			            format: @"Root Object UUID %@ is already at the beginning of its commit track and cannot be undone.", rootObjectUUID];
		[db executeUpdate: @"UPDATE commitTrack SET currentnode = ? WHERE objectuuid = ?",
				prevNode, rootObjectIndex]; CHECK(db);
		rs = [db executeQuery: @"SELECT revisionnumber FROM committracknode WHERE committracknodeid = ?", 
		   prevNode]; CHECK(db);
		if ([rs next])
		{
			int64_t revisionNumber = [rs longLongIntForColumnIndex: 0];
			return [self revisionWithRevisionNumber: revisionNumber];
		}
		else
		{
			[NSException raise: NSInternalInconsistencyException
			            format: @"Unable to find node %q in Commit Track %@ to retrieve revision number", 
				prevNode, rootObjectUUID]; 
		}
	}
	else
	{
		[NSException raise: NSInvalidArgumentException
		            format: @"Commit Track not found for object %@!", rootObjectUUID];
	}
	return nil;
}
- (CORevision*)redoOnCommitTrack: (ETUUID*)rootObjectUUID
{
	NSNumber *rootObjectIndex = [self keyForUUID: rootObjectUUID];
	FMResultSet *rs = [db executeQuery: @"SELECT nextNode FROM commitTrack ct JOIN commitTrackNode ctn ON ct.currentNode = ctn.committracknodeid "
		"WHERE ct.objectuuid = ?", rootObjectIndex]; CHECK(db);
	if ([rs next])
	{
		NSNumber* nextNode = [NSNumber numberWithLongLong: [rs longLongIntForColumnIndex: 0]];
		if ([nextNode longLongValue] == 0)
			[NSException raise: NSInvalidArgumentException
			            format: @"Root Object UUID %@ is already at the end of its commit track and cannot be redone.", rootObjectUUID];
		[db executeUpdate: @"UPDATE commitTrack SET currentnode = ? WHERE objectuuid = ?",
				nextNode, rootObjectIndex]; CHECK(db);
		rs = [db executeQuery: @"SELECT revisionnumber FROM committracknode WHERE committracknodeid = ?", 
			nextNode]; CHECK(db);
		if ([rs next])
		{
			int64_t revisionNumber = [rs longLongIntForColumnIndex: 0];
			return [self revisionWithRevisionNumber: revisionNumber];
		}
		else
		{
			[NSException raise: NSInternalInconsistencyException
			            format: @"Unable to find node %q in Commit Track %@ to retrieve revision number", 
				nextNode, rootObjectUUID]; 
		}
	}
	else
	{
		[NSException raise: NSInvalidArgumentException
		            format: @"Commit Track not found for object %@!", rootObjectUUID];
	}
	return nil;
}
- (CORevision*)maxRevision: (int64_t)maxRevNumber forRootObjectUUID: (ETUUID*)uuid
{
	if (maxRevNumber <= 0)
		maxRevNumber = [self latestRevisionNumber];
	FMResultSet *rs = [db executeQuery: @"SELECT MAX(revisionnumber) FROM uuids "
		"JOIN commits ON uuids.uuidIndex = commits.objectuuid "
		"WHERE revisionnumber <= ? AND commits.rootIndex = ?",
		[self keyForUUID: uuid], [NSNumber numberWithLongLong: maxRevNumber]]; CHECK(db);
	if ([rs next])
	{
		return [self revisionWithRevisionNumber: [rs longLongIntForColumnIndex: 0]];
	}
	else
	{
		return nil;
	}
}
@end

@implementation CORecord

- (id)initWithDictionary: (NSDictionary *)aDict
{
	SUPERINIT;
	ASSIGN(dictionary, aDict);
	return self;
}

- (void)dealloc
{
	[dictionary release];
	[super dealloc];
}

- (NSArray *)propertyNames
{
	return [[super propertyNames] arrayByAddingObjectsFromArray: 
		[dictionary allKeys]];
}

- (id) valueForProperty: (NSString *)aKey
{
	id value = [dictionary objectForKey: aKey];

	if (value == nil)
	{
		value = [super valueForProperty: aKey];
	}
	return value;
}

- (BOOL) setValue: (id)value forProperty: (NSString *)aKey
{
	if ([[dictionary allKeys] containsObject: aKey])
	{
		if ([dictionary isMutable])
		{
			[(NSMutableDictionary *)dictionary setObject: value forKey: aKey];
			return YES;
		}
		else
		{
			return NO;
		}
	}
	return [super setValue: value forProperty: aKey];
}

@end
