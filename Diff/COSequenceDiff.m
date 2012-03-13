#import <Foundation/Foundation.h>
#import "COSequenceDiff.h"
#import "COMacros.h"

@implementation COSequenceEdit

@synthesize range;
@synthesize sourceIdentifier;

- (void) dealloc
{
	[sourceIdentifier release];
	[super dealloc];
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

- (BOOL) isEqualIgnoringSourceIdentifier:(id)object
{
	[NSException raise: NSGenericException
				format: @"-[%@ %@] unimplemented", [self class], NSStringFromSelector(_cmd)];
	return NO;
}

- (BOOL) overlaps: (COSequenceEdit *)other
{
	NSRange r1 = [self range];
	NSRange r2 = [other range];
	
	// FIXME: revisit this calculation
	
	return (r1.location >= r2.location && r1.location < (r2.location + r2.length) && r1.length > 0)
    || (r2.location >= r1.location && r2.location < (r1.location + r1.length) && r2.length > 0);
}

- (id)copyWithZone:(NSZone *)zone
{
	return [self retain];
}

- (NSSet *)allEdits
{
	return [NSSet setWithObject: self];
}

- (BOOL) hasConflicts
{
	return NO;
}

@end


@implementation COSequenceInsertion

@synthesize insertedObject;

+ (COSequenceInsertion*)insertionWithLocation: (NSUInteger)aLocation
							   insertedObject: (id)anObject
							 sourceIdentifier: (id)aSource
{
	COSequenceInsertion *result = [[COSequenceInsertion alloc] init];
	result->range = NSMakeRange(aLocation, 0);
	ASSIGN(result->insertedObject, anObject);
	ASSIGN(result->sourceIdentifier, aSource);
	return [result autorelease];
}

- (void) dealloc
{
	[insertedObject release];
	[super dealloc];
}

- (BOOL) isEqualIgnoringSourceIdentifier:(id)object
{
	return [object isKindOfClass: [self class]] && 
		[insertedObject isEqual: [object insertedObject]] &&
		NSEqualRanges(range, [object range]);
}

- (BOOL) isEqual:(id)object
{
	return [self isEqualIgnoringSourceIdentifier: object]
		&& [sourceIdentifier isEqual: [object sourceIdentifier]];
}

- (NSUInteger) hash
{
	return [NSStringFromClass([self class]) hash] ^ [insertedObject hash] ^ range.location ^ range.length ^ [sourceIdentifier hash];
}

@end



@implementation COSequenceDeletion

+ (COSequenceDeletion*)deletionWithRange: (NSRange)aRange
						sourceIdentifier: (id)aSource
{
	COSequenceDeletion *result = [[COSequenceDeletion alloc] init];
	result->range = aRange;
	ASSIGN(result->sourceIdentifier, aSource);
	return [result autorelease];
}

- (BOOL) isEqualIgnoringSourceIdentifier:(id)object
{
	return [object isKindOfClass: [self class]] && 
		NSEqualRanges(range, [object range]);
}

- (BOOL) isEqual:(id)object
{
	return [self isEqualIgnoringSourceIdentifier: object]
	&& [sourceIdentifier isEqual: [object sourceIdentifier]];
}

- (NSUInteger) hash
{
	return [NSStringFromClass([self class]) hash] ^ range.location ^ range.length ^ [sourceIdentifier hash];
}

@end




@implementation COSequenceModification

@synthesize insertedObject;

+ (COSequenceModification*)modificationWithRange: (NSRange)aRange
								  insertedObject: (id)anObject
								sourceIdentifier: (id)aSource
{
	COSequenceModification *result = [[COSequenceModification alloc] init];
	result->range = aRange;
	ASSIGN(result->insertedObject, anObject);
	ASSIGN(result->sourceIdentifier, aSource);
	return [result autorelease];
}

- (void) dealloc
{
	[insertedObject release];
	[super dealloc];
}

- (BOOL) isEqualIgnoringSourceIdentifier:(id)object
{
	return [object isKindOfClass: [self class]]
		&& [insertedObject isEqual: [object insertedObject]]
		&& NSEqualRanges(range, [object range]);
}

- (BOOL) isEqual:(id)object
{
	return [self isEqualIgnoringSourceIdentifier: object]
		&& [sourceIdentifier isEqual: [object sourceIdentifier]];
}

- (NSUInteger) hash
{
	return [NSStringFromClass([self class]) hash] ^ [insertedObject hash] ^ range.location ^ range.length ^ [sourceIdentifier hash];
}

@end
