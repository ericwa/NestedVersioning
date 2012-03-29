#import "COPath.h"
#import "COMacros.h"

@implementation COPath

- (COPath *) initWithElements: (NSArray *)anArray
		 leadingPathsToParent: (NSInteger) parents
{	
	SUPERINIT;
	ASSIGN(elements, anArray);
	leadingPathsToParent = parents;
	return self;
}

- (void)dealloc
{
	[elements release];
	[super dealloc];
}

+ (COPath *) path
{
	static COPath *root;
	if (nil == root)
	{
		root = [[COPath alloc] initWithElements: [NSArray array]
						   leadingPathsToParent: 0];
	}
	return root;
}

+ (COPath *) pathWithString: (NSString*) pathString
{
	NILARG_EXCEPTION_TEST(pathString);
	
	COPath *result = [COPath path];
	
	if ([pathString length] > 0)
	{
		NSArray *components = [pathString componentsSeparatedByString: @"/"];
		for (NSString *component in components)
		{
			if ([component isEqualToString: @".."])
			{
				result = [result pathByAppendingPathToParent];
			}
			else
			{
				COUUID *uuid = [COUUID UUIDWithString: component];
				result = [result pathByAppendingPathComponent: uuid];
			}
		}
	}
	return result;
}

+ (COPath *) pathWithPathComponent: (COUUID*) aUUID
{
	return [[COPath path] pathByAppendingPathComponent: aUUID];
}

+ (COPath *) pathToParent
{
	return [[COPath path] pathByAppendingPathToParent];
}

- (COPath *) pathByAppendingPathToParent
{
	return [[[COPath alloc] initWithElements: elements
						leadingPathsToParent: leadingPathsToParent + 1] autorelease];
}

- (COPath *) pathByAppendingPath: (COPath *)aPath
{
	NILARG_EXCEPTION_TEST(aPath);
	
	if (aPath->leadingPathsToParent >= [elements count])
	{
		return [[[COPath alloc] initWithElements: aPath->elements
							leadingPathsToParent: leadingPathsToParent + aPath->leadingPathsToParent - [elements count]] autorelease];
	}
	else
	{
		NSArray *newElems = [[elements subarrayWithRange: NSMakeRange(0, [elements count] - aPath->leadingPathsToParent)] 
							 arrayByAddingObjectsFromArray: aPath->elements];
		return [[[COPath alloc] initWithElements: newElems												
							leadingPathsToParent: leadingPathsToParent] autorelease];
	}
}

- (COPath *) pathByAppendingPathComponent: (COUUID *)aUUID
{
	NILARG_EXCEPTION_TEST(aUUID);
	
	return [[[COPath alloc] initWithElements: [elements arrayByAddingObject: aUUID]
						leadingPathsToParent: leadingPathsToParent] autorelease];
}

- (id) copyWithZone: (NSZone *)zone
{
	return [self retain];
}

- (NSString *) stringValue
{
	NSMutableString *value = [NSMutableString string];
	
	for (NSUInteger i=0; i<leadingPathsToParent; i++)
	{
		[value appendFormat: @"../"];
	}
	
	for (NSUInteger i=0; i<[elements count]; i++)
	{
		[value appendFormat: @"%@", [[elements objectAtIndex: i] stringValue]];
		if ((i + 1) < [elements count])
		{
			[value appendFormat: @"/"];
		}
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

- (BOOL) isEmpty
{
	return ![self hasLeadingPathsToParent]
		&& ![self hasComponents];
}

- (BOOL) hasLeadingPathsToParent
{
	return leadingPathsToParent != 0;
}

- (BOOL) hasComponents
{
	return [elements count] != 0;
}

- (COUUID *) lastPathComponent
{
	return [elements lastObject];
}
- (COPath *) pathByDeletingLastPathComponent
{
	if ([elements count] == 0)
	{
		[NSException raise: NSGenericException
					format: @"pathByDeletingLastPathComponent called on path with no components"];
	}
	return [[[COPath alloc] initWithElements: [elements subarrayWithRange: NSMakeRange(0, [elements count] - 1)]
						leadingPathsToParent: leadingPathsToParent] autorelease];
}

- (NSString*) description
{
	return [self stringValue];
}

- (COPath *) pathByRenamingComponents: (NSDictionary *)aMapping
{
	NSMutableArray *newElements = [NSMutableArray array];
	for (COUUID *element in elements)
	{
		COUUID *newElement = element;
		if ([aMapping objectForKey: element] != nil)
		{
			newElement = [aMapping objectForKey: element];
		}
		[newElements addObject: newElement];
	}
	
	return [[[COPath alloc] initWithElements: newElements
						leadingPathsToParent: leadingPathsToParent] autorelease];
}

@end
