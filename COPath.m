#import "COPath.h"
#import "Common.h"

@implementation COPath

+ (COPath *) path
{
	return [[[COPath alloc] init] autorelease];
}

- (COPath *) pathByAppendingPathToCurrentVersionOfPersistentRoot: (ETUUID *)aPersistentRoot
{
	NILARG_EXCEPTION_TEST(aPersistentRoot);
	
	COPath *path = [COPath path];
	ASSIGN(path->parent, self);
	ASSIGN(path->persistentRoot, aPersistentRoot);
	return path;
}

- (COPath *) pathByAppendingPathToCurrentVersionOfPersistentRoot: (ETUUID *)aPersistentRoot
													atBranchUUID: (ETUUID *)aBranch
{
	NILARG_EXCEPTION_TEST(aPersistentRoot);
	NILARG_EXCEPTION_TEST(aBranch);
	
	COPath *path = [COPath path];
	ASSIGN(path->parent, self);
	ASSIGN(path->persistentRoot, aPersistentRoot);
	ASSIGN(path->branch, aBranch);
	return path;
}

- (COPath *) pathByAppendingPathToPersistentRoot: (ETUUID *)aPersistentRoot
									   atVersion: (ETUUID *)aVersion
{
	NILARG_EXCEPTION_TEST(aPersistentRoot);
	NILARG_EXCEPTION_TEST(aVersion);
	
	COPath *path = [COPath path];
	ASSIGN(path->parent, self);
	ASSIGN(path->persistentRoot, aPersistentRoot);
	ASSIGN(path->version, aVersion);
	return path;
}

- (id) copyWithZone: (NSZone *)zone
{
	return [self retain];
}

- (NSString *) stringValue
{
	NSMutableString *value;
	
	if (parent != nil)
	{
		value = [NSMutableString stringWithFormat: @"%@", [parent stringValue]];
	}
	else
	{
		assert(persistentRoot == nil && branch == nil && version == nil);
		return @"";
	}
	
	assert(branch == nil || version == nil);

	[value appendFormat: @"/%@", [persistentRoot stringValue]];
	
	if (branch != nil)
	{
		[value appendFormat: @":%@", [branch stringValue]];
	}
	else if (version != nil)
	{
		[value appendFormat: @"@%@", [version stringValue]];
	}
	
	return value;
}

- (NSUInteger) hash
{
	return [[self stringValue] hash];
}

- (BOOL) isEqual: (id)anObject
{
	return [anObject isKindOfClass: [self class]] &&
	[[self stringValue] isEqualToString: [anObject stringValue]];
}


- (NSString*) description
{
	return [self stringValue];
}

- (void)dealloc
{
	[parent release];
	[persistentRoot release];
	[branch release];
	[version release];
	[super dealloc];
}

@end
