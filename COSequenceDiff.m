#import <EtoileFoundation/EtoileFoundation.h>
#import "COSequenceDiff.h"


@implementation COSequenceDiff

- (id) initWithOperations: (NSArray*)opers
{
	SUPERINIT;
	
	ASSIGN(ops, [opers sortedArrayUsingSelector: @selector(compare:)]);
	
	return self;
}

- (void) dealloc
{
	[ops release];
	[super dealloc];
}

- (NSArray *)operations
{
	// ops was sorted in -init
	return ops;
}

- (NSString*)description
{
	NSMutableString *output = [NSMutableString stringWithFormat: @"<%@ %p: ", NSStringFromClass([self class]), self];
	for (id op in [self operations])
	{
		[output appendFormat:@"\n\t%@,", op];
	}
	[output appendFormat:@"\n>"];  
	return output;
}

/**
 * Inspired by the description of diff3 in "A Formal Investigation of diff3"
 */
- (COSequenceDiff *)sequenceDiffByMergingWithDiff: (COSequenceDiff *)other
{
	// Output arrays
	NSMutableArray *result = [NSMutableArray array];
    
	if ([[self operations] count] == 0)
	{
		[result addObjectsFromArray: [other operations]];
	}
	else if ([[other operations] count] == 0)
	{
		[result addObjectsFromArray: [self operations]];
	}
	else
	{
		NSArray *sortedOps = [[[self operations] arrayByAddingObjectsFromArray: [other operations]] 
								sortedArrayUsingSelector: @selector(compare:)];
		const NSUInteger sortedOpsCount = [sortedOps count];
				
		for (NSUInteger i = 0; i < sortedOpsCount; i++)
		{
			COSequenceEdit *op_i = [sortedOps objectAtIndex: i];

			// Does the operation after op1 overlap op1?
			NSMutableSet *overlappingEdits = nil;
			
			while (i + 1 < sortedOpsCount)
			{
				COSequenceEdit *op_i_plus_1 = [sortedOps objectAtIndex: i+i];
				if ([op_i overlaps: op_i_plus_1])
				{
					if (overlappingEdits == nil)
					{
						overlappingEdits = [[NSMutableSet alloc] initWithObjects: &op_i count: 1];
					}
					[overlappingEdits addObject: op_i_plus_1];		
					i++;
				}
				else
				{
					break;
				}
			}
			
			if (overlappingEdits != nil)
			{
				[result addObject: [COOverlappingSequenceEditGroup overlappingEditGroupWithEdits: overlappingEdits]];
			}
			else
			{
				[result addObject: op_i];
			}
			
			[overlappingEdits release];
		}
	}
	
	COSequenceDiff *resultDiff = [[[COSequenceDiff alloc] initWithOperations: result] autorelease];
	return resultDiff;
}

@end






@implementation COSequenceEdit
{
	NSRange range;
}
@synthesize range;

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

@end


@implementation COPrimitiveSequenceEdit

@synthesize sourceIdentifier;

- (void) dealloc
{
	[sourceIdentifier release];
	[super dealloc];
}

- (BOOL) isEqualIgnoringSourceIdentifier:(id)object
{
	[NSException raise: NSGenericException
				format: @"-[%@ %@] unimplemented", [self class], NSStringFromSelector(_cmd)];
	return NO;
}

@end


@implementation COOverlappingSequenceEditGroup

@synthesize overlappingEdits;
@synthesize conflicting;

+ (COOverlappingSequenceEditGroup *)overlappingEditGroupWithEdits: (NSSet *)edits
{
	if ([edits count] < 2)
	{
		[NSException raise: NSInvalidArgumentException
					format: @"+overlappingEditGroupWithEdits: expects at least 2 edits"];
	}
	
	COPrimitiveSequenceEdit *firstEdit = [edits anyObject];
	NSRange totalRange = [firstEdit range];
	BOOL allSame = YES;
	for (COPrimitiveSequenceEdit *edit in edits)
	{
		totalRange = NSUnionRange(totalRange, [edit range]);
		allSame = allSame && [firstEdit isEqual: edit];
	}
	
	COOverlappingSequenceEditGroup *result = [[COOverlappingSequenceEditGroup alloc] init];
	result->range = totalRange;
	result->overlappingEdits = [[NSMutableSet alloc] initWithSet: edits];
	result->conflicting = !allSame;
	return [result autorelease];
}

- (void) dealloc
{
	[overlappingEdits release];
	[super dealloc];
}

- (BOOL) isEqual:(id)object
{
	return [object isKindOfClass: [self class]] && 
		[overlappingEdits isEqual: [object overlappingEdits]];
}

- (NSUInteger) hash
{
	return [NSStringFromClass([self class]) hash] ^ [overlappingEdits hash] ^ range.location ^ range.length;
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
