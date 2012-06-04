#import "COPath.h"
#import "COMacros.h"

@implementation COPath

- (COPath *) initWithPersistentRoot: (COUUID *)aRoot
							 branch: (COUUID*)aBranch
					embdeddedObject: (COUUID *)anObject
{	
	SUPERINIT;
	NILARG_EXCEPTION_TEST(aRoot);
	ASSIGN(persistentRoot, aRoot);
	ASSIGN(branch, aBranch);
	ASSIGN(embeddedObject, anObject);
	return self;
}

- (void)dealloc
{
	[persistentRoot release];
	[branch release];
	[embeddedObject release];
	[super dealloc];
}

+ (COPath *) pathWithPersistentRoot: (COUUID *)aRoot
{
	return [self pathWithPersistentRoot:aRoot branch: nil];
}

+ (COPath *) pathWithPersistentRoot: (COUUID *)aRoot
							 branch: (COUUID*)aBranch
{
	return [self pathWithPersistentRoot:aRoot branch:aBranch embdeddedObject:nil];
}

+ (COPath *) pathWithPersistentRoot: (COUUID *)aRoot
							 branch: (COUUID*)aBranch
					embdeddedObject: (COUUID *)anObject
{
	return [[[self alloc] initWithPersistentRoot: aRoot branch: aBranch embdeddedObject: anObject] autorelease];
}

+ (COPath *) pathWithString: (NSString*) pathString
{
	NILARG_EXCEPTION_TEST(pathString);
	
	COUUID *embeddedObject = nil;
	COUUID *branch = nil;
	COUUID *persistentRoot = nil;
	
	if ([pathString length] > 0)
	{
		NSArray *components = [pathString componentsSeparatedByCharactersInSet:
							   [NSCharacterSet characterSetWithCharactersInString: @":."]];
		switch ([components count])
		{
			case 3:
				embeddedObject = [COUUID UUIDWithString: [components objectAtIndex: 2]];
			case 2:
				branch = [COUUID UUIDWithString: [components objectAtIndex: 1]];
			case 1:
				persistentRoot = [COUUID UUIDWithString: [components objectAtIndex: 0]];
				break;
			default:
				[NSException raise: NSInvalidArgumentException format: @"unsupported COPath string '%@'", pathString];
		}
	}
	return [COPath pathWithPersistentRoot: persistentRoot branch: branch embdeddedObject: embeddedObject];
}

- (id) copyWithZone: (NSZone *)zone
{
	return [self retain];
}

- (NSString *) stringValue
{
	NSMutableString *value = [NSMutableString stringWithString: [persistentRoot stringValue]];
	
	if (branch != nil)
	{
		[value appendFormat: @":%@", branch];
	}
	if (embeddedObject != nil)
	{
		[value appendFormat: @".%@", embeddedObject];
	}
	
	return [NSString stringWithString: value];
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

@end
