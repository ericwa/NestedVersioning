#import "COSequenceMerge.h"

NSArray *COMergeSortedArraysUsingSelector(NSArray *sortredArrayA, NSArray *sortredArrayB, SEL cmpSel)
{
	const NSUInteger arrayACount = [sortredArrayA count];
	const NSUInteger arrayBCount = [sortredArrayB count];
	NSMutableArray *result = [NSMutableArray arrayWithCapacity: arrayACount + arrayBCount];
	
	NSUInteger arrayAIndex = 0;
	NSUInteger arrayBIndex = 0;
	while (arrayAIndex < arrayACount || arrayBIndex < arrayBCount)
	{
		if (arrayAIndex == arrayACount)
		{
			[result addObject: [sortredArrayB objectAtIndex: arrayBIndex++]];
		}
		else if (arrayBIndex == arrayBCount)
		{
			[result addObject: [sortredArrayA objectAtIndex: arrayAIndex++]];
		}
		else
		{
			id arrayAElement = [sortredArrayA objectAtIndex: arrayAIndex];
			id arrayBElement = [sortredArrayB objectAtIndex: arrayBIndex];
			
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

static inline BOOL COOverlappingRanges(NSRange r1, NSRange r2)
{
	return (r1.location >= r2.location && r1.location < (r2.location + r2.length) && r1.length > 0)
		|| (r2.location >= r1.location && r2.location < (r1.location + r1.length) && r2.length > 0);
}

NSSet *COFindConflicts(NSArray *sortedOps)
{
	NSMutableSet *conflicts = [NSMutableSet set];
	const NSUInteger sortedOpsCount = [sortedOps count];
	
	for (NSUInteger i = 0; i < sortedOpsCount; i++)
	{
		const NSRange op_iRange = [(id<COEdit>)[sortedOps objectAtIndex: i] range];
		NSRange op_iOverlappingRange = op_iRange;
		
		// Does the operation after op_i overlap op_i?
		NSMutableIndexSet *overlappingEdits = nil;
		
		while (i + 1 < sortedOpsCount)
		{
			const NSRange op_i_plus_1Range = [(id<COEdit>)[sortedOps objectAtIndex: i + 1] range];

			if (COOverlappingRanges(op_iOverlappingRange, op_i_plus_1Range))
			{
				op_iOverlappingRange = NSUnionRange(op_iOverlappingRange, op_i_plus_1Range);
				if (overlappingEdits == nil)
				{
					overlappingEdits = [[NSMutableIndexSet alloc] init];
				}
				[overlappingEdits addIndex: i];
				[overlappingEdits addIndex: i + 1];
				i++;
			}
			else
			{
				break;
			}
		}
		
		if (overlappingEdits != nil && [overlappingEdits count] > 1)
		{
			[conflicts addObject: overlappingEdits];
		}
		
		[overlappingEdits release];
	}
		
	return conflicts;
}

NSArray *COEditsByUniquingNonconflictingDuplicates(NSArray *edits)
{
	NSSet *conflicts = COFindConflicts(edits);
	
	NSMutableIndexSet *duplicateEditsToRemove = [NSMutableIndexSet indexSet];
	
	for (NSIndexSet *conflict in conflicts)
	{
		id<COEdit> edit = nil;
		for (NSUInteger i = [conflict firstIndex]; i != NSNotFound; i = [conflict indexGreaterThanIndex: i])
		{
			id<COEdit> edit_i = [edits objectAtIndex: i];
			if (edit == nil)
			{
				edit = edit_i;
			}
			else
			{
				if (![edit isEqual: edit_i])
				{
					[NSException raise: NSInvalidArgumentException
								format: @"COEditsByUniquingNonconflictingDuplicates() should only be called on edit sequences with no real conflicts"];
				}
				else
				{
					[duplicateEditsToRemove addIndex: i];
				}
			}
		}
	}
	
	NSMutableArray *result = [NSMutableArray arrayWithArray: edits];
	for (NSUInteger i = [duplicateEditsToRemove firstIndex]; i != NSNotFound; i = [duplicateEditsToRemove indexGreaterThanIndex: i])
	{
		[result removeObjectAtIndex: i];
	}
	return result;
}
