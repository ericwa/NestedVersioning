#import "COInMemoryObject.h"
#import "Common.h"
#import "ETUUID.h"

@implementation COInMemoryObject

- (id) initWithUUID: (ETUUID*)aUUID
{
	NILARG_EXCEPTION_TEST(aUUID);
	
	SUPERINIT;
	ASSIGN(uuid, aUUID);
	types = [[NSMutableDictionary alloc] init];
	values = [[NSMutableDictionary alloc] init];
	return self;
}

- (id) init
{
	return [self initWithUUID: [ETUUID UUID]];
}

+ (COInMemoryObject *) object
{
	return [[[COInMemoryObject alloc] init] autorelease];
}

- (void) dealloc
{
	[uuid release];
	[types release];
	[values release];
	[super dealloc];
}

- (ETUUID *)UUID
{
	return uuid;
}

- (NSArray *) attributeNames
{
	assert([[[types allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]
			isEqual: [[values allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]]);	
	return [types allKeys];
}

- (NSDictionary *) typeForAttribute: (NSString *)anAttribute
{
	return [types objectForKey: anAttribute];
}

/** @taskunit equality testing */

- (BOOL) isEqual:(id)object
{
	if (![object isKindOfClass: [self class]])
	{
		return NO;
	}
	COInMemoryObject *otherItem = (COInMemoryObject*)object;
	
	if (![[otherItem UUID] isEqual: [self UUID]]) return NO;
	return YES;
}

- (NSUInteger) hash
{
	return [uuid hash] ^ 6130060948920424LL;
}

- (id)copyWithZone:(NSZone *)zone
{

	
}

/* @taskunit schema */

- (void) removeAttribute: (NSString *)anAttribute
{
	[types removeObjectForKey: anAttribute];
	[values removeObjectForKey: anAttribute];
}
- (void) addAttribute: (NSString *)anAttribute type: (NSDictionary *)aType
{
	[types setObject: [NSDictionary dictionaryWithDictionary: aType]
			  forKey: anAttribute];
	
	// set up container
	
	NSString *typeKind = [aType objectForKey: kCOTypeKind];
	if ([typeKind isEqualTo: kCOContainerTypeKind])
	{
		NSNumber *ordered = [aType objectForKey: kCOContainerOrdered];
		NSNumber *allowsDuplicates = [aType objectForKey: kCOContainerAllowsDuplicates];
		
		BOOL orderedVal = [ordered boolValue];
		BOOL allowsDuplicatesVal = [allowsDuplicates boolValue];
		
		id container;
		
		if (!orderedVal && !allowsDuplicatesVal)
		{
			container = [NSMutableSet set];
		}
		else if (!orderedVal && allowsDuplicatesVal)
		{
			container = [NSCountedSet set];
		}
		else
		{
			container = [NSMutableArray array];
		}
		
		[values setObject: container
				   forKey: anAttribute];
	}
}

/* @taskunit values */

- (void) addValue: (id)anObject
	 forAttribute: (NSString *)anAttribute
{
	
}


- (void) addValue: (id)anObject
		  atIndex: (NSUInteger)anIndex
	 forAttribute: (NSString *)anAttribute
{
	
}

- (void) removeValue: (id)anObject
		forAttribute: (NSString *)anAttribute
{
	
}


- (void) removeValue: (id)anObject
			 atIndex: (NSUInteger)anIndex
		forAttribute: (NSString *)anAttribute
{
	
}


- (void) setValue: (id)anObject
	 forAttribute: (NSString *)anAttribute
{
}

- (id) valueForAttribute: (NSString*)anAttribute
{
	return [values objectForKey: anAttribute];
}

@end
