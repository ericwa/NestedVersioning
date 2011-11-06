#import "COStore.h"
#import "Common.h"

@interface COStore (Private)

@end


@implementation COStore

- (NSString *) persistentRootsDirectory
{
	return [[url path] stringByAppendingPathComponent: @"persistentRoots"];
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
															error: NULL] ||
			![[NSFileManager defaultManager] createDirectoryAtPath: [self persistentRootsDirectory]
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
                       metadata: (NSData*)metadata
				   UUIDsAndData: (NSDictionary*)objects // ETUUID : NSData
{
	NILARG_EXCEPTION_TEST(metadata);
	NILARG_EXCEPTION_TEST(objects);
	
	ETUUID *commitUUID = [ETUUID UUID];
	
	NSMutableDictionary *objectsWithStringUUID = [NSMutableDictionary dictionary];
	{
		for (ETUUID *uuid in objects)
		{
			NSData *data = [objects objectForKey: uuid];
			if (![data isKindOfClass: [NSData class]])
			{
				[NSException raise: NSInvalidArgumentException
							format: @"UUIDsAndData: parameter must contain NSData values"];
			}
			[objectsWithStringUUID setObject: data
									  forKey: [uuid stringValue]];
		}
	}
	
	NSMutableDictionary *plist = [NSMutableDictionary dictionaryWithObjectsAndKeys:
							   [commitUUID stringValue], @"uuid",
							   metadata, @"metadata",
							   objectsWithStringUUID, @"obects",
							   nil];
	
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
					format: @"Failed to save commit. Perhaps the store is not writable/valid?"];
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

	[plist setObject: [ETUUID UUIDWithString: [plist objectForKey: @"parent"]]
			  forKey: @"parent"];
	
	return plist;
}
- (ETUUID *) parentForCommit: (ETUUID*)commit
{
	return [[self plistForCommit: commit] objectForKey: @"parent"];
}
- (NSData *) metadataForCommit: (ETUUID*)commit
{
	return [[self plistForCommit: commit] objectForKey: @"metadata"];	
}
- (NSDictionary *) UUIDsAndDataForCommit: (ETUUID*)commit
{
	return [[self plistForCommit: commit] objectForKey: @"objects"];	
}

@end
