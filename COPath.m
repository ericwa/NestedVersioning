#import "COPath.h"
#import "Common.h"

@implementation COPath

+ (COPath *) path
{
	return [[[COPath alloc] init] autorelease];
}

- (COPath *) pathByAppendingPersistentRoot: (ETUUID *)aPersistentRoot
{
	NILARG_EXCEPTION_TEST(aPersistentRoot);
	
	COPath *path = [COPath path];
	ASSIGN(path->parent, self);
	ASSIGN(path->persistentRoot, aPersistentRoot);
	return path;
}

+ (COPath *) pathWithString: (NSString*) pathString
{
	if (nil == pathString ||
		![pathString hasPrefix: @"/"] || 
		[pathString hasSuffix: @"/"])
	{
		[NSException raise: NSInvalidArgumentException
					format: @"malformed path '%@'", pathString]; 
	}
	
	COPath *result = [COPath path];
	NSArray *components = [[pathString substringFromIndex: 1] // strip off first slash
								componentsSeparatedByString: @"/"];
	for (NSString *uuidString in components)
	{
		// FIXME: too leniant
		ETUUID *uuid = [ETUUID UUIDWithString: uuidString];
		result = [result pathByAppendingPersistentRoot: uuid];
	}
	return result;
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
		assert(persistentRoot == nil);
		return @"";
	}

	[value appendFormat: @"/%@", [persistentRoot stringValue]];

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

- (BOOL) isEmpty
{
	return (parent == nil);
}

- (ETUUID *) lastPathComponent
{
	return persistentRoot;
}
- (COPath *) pathByDeletingLastPathComponent
{
	return parent;
}

- (NSString*) description
{
	return [self stringValue];
}

- (void)dealloc
{
	[parent release];
	[persistentRoot release];
	[super dealloc];
}

@end
