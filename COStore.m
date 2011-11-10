#import "COStore.h"
#import "Common.h"

@interface COStore (Private)

@end


@implementation COStore

- (NSString *) rootVersionFile
{
	return [[url path] stringByAppendingPathComponent: @"rootVersion"];
}

- (NSString *) commitsDirectory
{
	return [[url path] stringByAppendingPathComponent: @"commits"];
}

- (id)initWithURL: (NSURL*)aURL
{
	self = [super init];
	url = [aURL retain];
	
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
	[url release];
	[super dealloc];
}

- (NSURL*)URL
{
	return url;
}

- (ETUUID*) addCommitWithParent: (ETUUID*)parent
                       metadata: (id)metadataPlist
				 UUIDsAndPlists: (NSDictionary*)objects
{
	NILARG_EXCEPTION_TEST(objects);
	
	ETUUID *commitUUID = [ETUUID UUID];
	
	NSMutableDictionary *objectsWithStringUUID = [NSMutableDictionary dictionary];
	{
		for (ETUUID *uuid in objects)
		{
			[objectsWithStringUUID setObject: [objects objectForKey: uuid]
									  forKey: [uuid stringValue]];
		}
	}
	
	NSMutableDictionary *plist = [NSMutableDictionary dictionaryWithObjectsAndKeys:
							   [commitUUID stringValue], @"uuid",
							   objectsWithStringUUID, @"objects",
							   nil];
	
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
	
	return commitUUID;			
}

- (NSArray*) allCommitUUIDs
{
	NSArray *paths = [[NSFileManager defaultManager]
					  subpathsAtPath: [self commitsDirectory]];
	NSMutableArray *uuids = [NSMutableArray array];
	
	for (NSString *path in paths)
	{
		ETUUID *uuid = [ETUUID UUIDWithString: path];
		
		[uuids addObject: uuid];
	}
	return uuids;
}

- (NSDictionary *) plistForCommit: (ETUUID*)commit
{
	NSString *commitFile = [[self commitsDirectory] stringByAppendingPathComponent:
							[commit stringValue]];
	
	NSMutableDictionary *plist = [NSMutableDictionary dictionaryWithContentsOfFile: commitFile];
	
	NSMutableDictionary *objectsWithUUID = [NSMutableDictionary dictionary];
	{
		for (NSString *uuidString in [plist objectForKey: @"objects"])
		{
			[objectsWithUUID setObject: [[plist objectForKey: @"objects"] objectForKey: uuidString]
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
	return plist;
}
- (ETUUID *) parentForCommit: (ETUUID*)commit
{
	return [[self plistForCommit: commit] objectForKey: @"parent"];
}
- (id) metadataForCommit: (ETUUID*)commit
{
	return [[self plistForCommit: commit] objectForKey: @"metadata"];	
}
- (NSDictionary *) UUIDsAndPlistsForCommit: (ETUUID*)commit
{
	return [[self plistForCommit: commit] objectForKey: @"objects"];	
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


@end
