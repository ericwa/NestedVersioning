#import "ETUUID.h"
#import "COMacros.h"
#import "COSubtreeEdits.h"


@implementation COSubtreeEdit

@synthesize UUID;
@synthesize attribute;
@synthesize sourceIdentifier;

- (id) copyWithZone: (NSZone *)aZone
{
	COSubtreeEdit *result = [[[self class] alloc] init];
	result.UUID = UUID;
	result.attribute = attribute;
	result.sourceIdentifier = sourceIdentifier;
	return result;
}

- (void) dealloc
{
	[UUID release];
	[attribute release];
	[sourceIdentifier release];
	[super dealloc];
}

- (BOOL) isEqualIgnoringSourceIdentifier: (id)other
{
	return [other isKindOfClass: [self class]]
		&&	[UUID isEqual: ((COSubtreeEdit*)other).UUID]
		&&	[attribute isEqual: ((COSubtreeEdit*)other).attribute];
}

- (NSUInteger) hash
{
	return [UUID hash] ^ [attribute hash] ^ [sourceIdentifier hash];
}

- (BOOL) isEqual: (id)other
{
	return [self isEqualIgnoringSourceIdentifier: other]
		&& [sourceIdentifier isEqual: ((COSubtreeEdit*)other).sourceIdentifier];
}

@end


@implementation COSetAttribute

@synthesize type;
@synthesize value;

- (id) copyWithZone: (NSZone *)aZone
{
	COSetAttribute *result = [super copyWithZone: aZone];
	result.type = type;
	result.value = value;
	return result;
}

- (void)dealloc
{
	[value release];
	[type release];
	[super dealloc];
}

- (BOOL) isEqualIgnoringSourceIdentifier: (id)other
{
	return [super isEqualIgnoringSourceIdentifier: other]
	&&	[type isEqual: ((COSetAttribute*)other).type]
	&&	[value isEqual: ((COSetAttribute*)other).value];
}

- (NSUInteger) hash
{
	return [super hash] ^ [type hash] ^ [value hash];
}

@end


@implementation CODeleteAttribute
@end


@implementation COSetInsertion
@synthesize object;

- (id) copyWithZone: (NSZone *)aZone
{
	COSetInsertion *result = [super copyWithZone: aZone];
	result.object = object;
	return result;
}

- (void)dealloc
{
	[object release];
	[super dealloc];
}

- (BOOL) isEqualIgnoringSourceIdentifier: (id)other
{
	return [super isEqualIgnoringSourceIdentifier: other]
	&&	[object isEqual: ((COSetInsertion*)other).object];
}

- (NSUInteger) hash
{
	return [super hash] ^ [object hash];
}
@end


@implementation COSetDeletion
@end




@implementation COSequenceEdit

@synthesize range;

- (id) copyWithZone: (NSZone *)aZone
{
	COSequenceEdit *result = [super copyWithZone: aZone];
	result.range = range;
	return result;
}


- (NSComparisonResult) compare: (COSequenceEdit*)other
{
	if ([other range].location > [self range].location)
	{
		return NSOrderedAscending;
	}
	if ([other range].location == [self range].location)
	{
		return NSOrderedSame;
	}
	else
	{
		return NSOrderedDescending;
	}
}

- (BOOL) isEqualIgnoringSourceIdentifier:(id)other
{
	return [super isEqualIgnoringSourceIdentifier: other]
		&& NSEqualRanges(range, ((COSequenceEdit*)other).range);
}

- (NSUInteger) hash
{
	return [super hash] ^ range.location ^ range.length;
}

@end


@implementation COSequenceInsertion

@synthesize insertedObjects;

- (id) copyWithZone: (NSZone *)aZone
{
	COSequenceInsertion *result = [super copyWithZone: aZone];
	result.insertedObjects = insertedObjects;
	return result;
}
					  
- (void)dealloc
{
	[insertedObjects release];
	[super dealloc];
}
					  
- (BOOL) isEqualIgnoringSourceIdentifier: (id)other
{
	return [super isEqualIgnoringSourceIdentifier: other]
	&&	[insertedObjects isEqual: ((COSequenceInsertion*)other).insertedObjects];
}
					  
- (NSUInteger) hash
{
	return [super hash] ^ [insertedObjects hash];
}

@end


@implementation COSequenceDeletion
@end


@implementation COSequenceModification
@end
