#import <Foundation/Foundation.h>
#import "COSequenceDiff.h"
#import "COMacros.h"

/**
 * Linear-time version of:
 *
 * [[arrayA arrayByAddingObjectsFromArray: arrayB] sortedArrayUsingSelector: cmpSel]]
 *
 * for when the arrays are already sorted.
 */
static NSArray *COMergeSortedArraysUsingSelector(NSArray *arrayA, NSArray *arrayB, SEL cmpSel)
{
	const NSUInteger arrayACount = [arrayA count];
	const NSUInteger arrayBCount = [arrayB count];
	NSMutableArray *result = [NSMutableArray arrayWithCapacity: arrayACount + arrayBCount];
	
	NSUInteger arrayAIndex = 0;
	NSUInteger arrayBIndex = 0;
	while (arrayAIndex < arrayACount || arrayBIndex < arrayBCount)
	{
		if (arrayAIndex == arrayACount)
		{
			[result addObject: [arrayB objectAtIndex: arrayBIndex++]];
		}
		else if (arrayBIndex == arrayBCount)
		{
			[result addObject: [arrayA objectAtIndex: arrayAIndex++]];
		}
		else
		{
			id arrayAElement = [arrayA objectAtIndex: arrayAIndex];
			id arrayBElement = [arrayB objectAtIndex: arrayBIndex];
			
			IMP cmpImp = [arrayAElement methodForSelector: cmpSel];
			NSComparisonResult cmpResult = ((NSComparisonResult (*)(id, SEL, id))cmpImp)(arrayAElement, cmpSel, arrayBElement);
			
			if (cmpResult == NSOrderedAscending || cmpResult == NSOrderedSame)
			{
				[result addObject: arrayAElement];
				[result addObject: arrayBElement];
			}
			else if (cmpResult == NSOrderedDescending)
			{
				[result addObject: arrayBElement];
				[result addObject: arrayAElement];
			}
			else
			{
				[NSException raise: NSInternalInconsistencyException
							format: @"comparison method returned invalid value"];
			}
			
			arrayAIndex++;
			arrayBIndex++;
		}
	}
	
	return result;
}


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
	if (![other isKindOfClass: [self class]])
	{
		[NSException raise: NSInvalidArgumentException
					format: @"Only diffs of the same class can be merged"];
	}
	
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
		/**
		 * equivelant to sortedOps = [[arrayA arrayByAddingObjectsFromArray: arrayB] sortedArrayUsingSelector: cmpSel]]
		 */
		NSArray *sortedOps = COMergeSortedArraysUsingSelector([self operations], [other operations], @selector(compare:));
		const NSUInteger sortedOpsCount = [sortedOps count];
				
		for (NSUInteger i = 0; i < sortedOpsCount; i++)
		{
			COSequenceEdit *op_i = [sortedOps objectAtIndex: i];

			// Does the operation after op1 overlap op1?
			NSMutableSet *overlappingEdits = nil;
			
			while (i + 1 < sortedOpsCount)
			{
				COSequenceEdit *op_i_plus_1 = [sortedOps objectAtIndex: i + 1];
				if ([op_i overlaps: op_i_plus_1])
				{
					/**
					 * Using the -allEdits method allows us to transparently break apart 
					 * COOverlappingSequenceEditGroup instances and recombine them
					 */
					if (overlappingEdits == nil)
					{
						overlappingEdits = [[NSMutableSet alloc] initWithSet: [op_i allEdits]];
					}
					[overlappingEdits unionSet: [op_i_plus_1 allEdits]];
					i++;
				}
				else
				{
					break;
				}
			}
			
			if (overlappingEdits != nil && [overlappingEdits count] > 1)
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
	
	COSequenceDiff *resultDiff = [[[[self class] alloc] initWithOperations: result] autorelease];
	return resultDiff;
}

- (BOOL) hasConflicts
{
	BOOL hasConflicts = NO;
	for (COSequenceEdit *edit in ops)
	{
		hasConflicts = hasConflicts || [edit hasConflicts];
	}
	return hasConflicts;
}

@end






@implementation COSequenceEdit

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

- (NSSet *)allEdits
{
	return [NSSet setWithObject: self];
}

- (COPrimitiveSequenceEdit *)anyNonconflictingEdit
{
	return (COPrimitiveSequenceEdit *)self;
}

- (BOOL) hasConflicts
{
	return NO;
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

+ (COOverlappingSequenceEditGroup *)overlappingEditGroupWithEdits: (NSSet *)edits
{
	if ([edits count] < 2)
	{
		[NSException raise: NSInvalidArgumentException
					format: @"+overlappingEditGroupWithEdits: expects at least 2 edits"];
	}
	
	// Compute the union of the ranges covered by edits,
	// check if they are conflicting or not
	
	COPrimitiveSequenceEdit *firstEdit = [edits anyObject];
	NSRange totalRange = [firstEdit range];
	BOOL allSame = YES;
	for (COPrimitiveSequenceEdit *edit in edits)
	{
		totalRange = NSUnionRange(totalRange, [edit range]);
		allSame = allSame && [firstEdit isEqualIgnoringSourceIdentifier: edit];
	}
	
	// Create edits dictionary
	
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	for (COPrimitiveSequenceEdit *edit in edits)
	{
		id identifier = [edit sourceIdentifier];
		if (nil == identifier)
		{
			[NSException raise: NSInvalidArgumentException
						format: @"sourceIdentifiers must not be nil"];
		}
			 
		NSMutableArray *array = [dict objectForKey: identifier];
		if (nil == array)
		{
			array = [NSMutableArray arrayWithObject: edit];
			[dict setObject: array
					 forKey: identifier];
		}
		else
		{
			[array addObject: edit];
		}
	}
	
	COOverlappingSequenceEditGroup *result = [[COOverlappingSequenceEditGroup alloc] init];
	result->range = totalRange;
	result->overlappingEdits = dict;
	result->conflicting = !allSame;
	return [result autorelease];
}

- (NSArray *) editsForSourceIdentifier: (id)anIdentifier
{
	return [NSArray arrayWithArray: [overlappingEdits objectForKey: anIdentifier]];
}

- (void) dealloc
{
	[overlappingEdits release];
	[super dealloc];
}

- (BOOL) isEqual:(id)object
{
	return [object isKindOfClass: [self class]] && 
		[overlappingEdits isEqual: ((COOverlappingSequenceEditGroup *)object)->overlappingEdits];
}

- (NSUInteger) hash
{
	return [NSStringFromClass([self class]) hash] ^ [overlappingEdits hash] ^ range.location ^ range.length;
}

- (NSSet *)allEdits
{
	NSMutableSet *set = [NSMutableSet set];
	for (NSArray *edits in [overlappingEdits allValues])
	{
		for (COPrimitiveSequenceEdit *edit in edits)
		{
			[set addObject: edit];
		}
	}
	return set;
}

- (COPrimitiveSequenceEdit *)anyNonconflictingEdit
{
	if (conflicting)
	{
		[NSException raise: NSGenericException
					format: @"-anyNonconflictingEdit called on an edit group with conflicts"];
	}
	
	id anyKey = [[overlappingEdits allKeys] objectAtIndex: 0];
	NSArray *edits = [overlappingEdits objectForKey: anyKey];
	return [edits objectAtIndex: 0];
}

- (BOOL) hasConflicts
{
	return conflicting;
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
