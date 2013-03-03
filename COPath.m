#import "COPath.h"
#import "COMacros.h"

@implementation COPath

@synthesize persistentRoot = persistentRoot_;
@synthesize branch = branch_;
@synthesize embeddedObject = embeddedObject_;

- (COPath *) initWithPersistentRoot: (COUUID *)aRoot
							 branch: (COUUID*)aBranch
					embdeddedObject: (COUUID *)anObject
{	
	SUPERINIT;
	NILARG_EXCEPTION_TEST(aRoot);
	ASSIGN(persistentRoot_, aRoot);
	ASSIGN(branch_, aBranch);
	ASSIGN(embeddedObject_, anObject);
	return self;
}

- (void)dealloc
{
	[persistentRoot_ release];
	[branch_ release];
	[embeddedObject_ release];
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

- (COPath *) pathWithNameMapping: (NSDictionary *)aMapping
{
	COUUID *embeddedObject = embeddedObject_;
	COUUID *branch = branch_;
	COUUID *persistentRoot = persistentRoot_;
    
    if (embeddedObject != nil
        && [aMapping objectForKey: embeddedObject])
    {
        embeddedObject = [aMapping objectForKey: embeddedObject];
    }
    
    if (branch != nil
        && [aMapping objectForKey: branch])
    {
        branch = [aMapping objectForKey: branch];
    }
    
    if (persistentRoot != nil
        && [aMapping objectForKey: persistentRoot])
    {
        persistentRoot = [aMapping objectForKey: persistentRoot];
    }
    
    return [COPath pathWithPersistentRoot: persistentRoot
                                   branch: branch
                          embdeddedObject: embeddedObject];
}

- (id) copyWithZone: (NSZone *)zone
{
	return [self retain];
}

- (NSString *) stringValue
{
	NSMutableString *value = [NSMutableString stringWithString: [persistentRoot_ stringValue]];
	
	if (branch_ != nil)
	{
		[value appendFormat: @":%@", branch_];
	}
	if (embeddedObject_ != nil)
	{
		[value appendFormat: @".%@", embeddedObject_];
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
