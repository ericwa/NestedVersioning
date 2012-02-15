#import "COArrayDiff.h"
#include "diff.h"

#import "COMacros.h"

@implementation COArrayDiff

static bool comparefn(size_t i, size_t j, void *userdata1, void *userdata2)
{
	return [[(NSArray*)userdata1 objectAtIndex: i] isEqual:
			[(NSArray*)userdata2 objectAtIndex: j]];
}

- (NSArray *)opsWithFirstArray: (NSArray *)a
				   secondArray: (NSArray *)b
			  sourceIdentifier: (id)aSource
{
	NSMutableArray *resultArray = [NSMutableArray array];
	
	//NSLog(@"ArrayDiffing %d vs %d objects", [a count], [b count]);
	
	diffresult_t *result = diff_arrays([a count], [b count], comparefn, a, b);
	
	for (size_t i=0; i<diff_editcount(result); i++)
	{
		diffedit_t edit = diff_edit_at_index(result, i);
		
		NSRange firstRange = NSMakeRange(edit.range_in_a.location, edit.range_in_a.length);
		NSRange secondRange = NSMakeRange(edit.range_in_b.location, edit.range_in_b.length);
		
		switch (edit.type)
		{
			case difftype_insertion:
				if (secondRange.length > 0)
				{
					[resultArray addObject: [COSequenceInsertion insertionWithLocation: firstRange.location
																		insertedObject: [b subarrayWithRange: secondRange]
																	  sourceIdentifier: aSource]];
				}
				break;
			case difftype_deletion:
				[resultArray addObject: [COSequenceDeletion deletionWithRange: firstRange
															 sourceIdentifier: aSource]];
				break;
			case difftype_modification:
				[resultArray addObject: [COSequenceModification modificationWithRange: firstRange
																	   insertedObject: [b subarrayWithRange: secondRange]
																	 sourceIdentifier: aSource]];
																				  
				break;
		}
	}
	
	diff_free(result);
	
	return resultArray;
}


- (id) initWithFirstArray: (NSArray *)first
			  secondArray: (NSArray *)second
		 sourceIdentifier: (id)aSource
{
	self = [super initWithOperations: [self opsWithFirstArray: first
												  secondArray: second
											 sourceIdentifier: aSource]];	
	return self;
}

/**
 * Applys the receiver to the given mutable array
 */
- (void) applyTo: (NSMutableArray*)array
{
	if ([self hasConflicts])
	{
		[NSException raise: NSGenericException
					format: @"Cannot apply diff with conflicts"];
	}
	
	NSInteger i = 0;
	for (COSequenceEdit *op in ops)
	{
		if ([op isKindOfClass: [COSequenceInsertion class]])
		{
			COSequenceInsertion *opp = (COSequenceInsertion*)op;
			NSRange range = NSMakeRange([op range].location + i, [[opp insertedObject] count]);
			
			[array insertObjects: (NSArray *)[opp insertedObject]
					   atIndexes: [NSIndexSet indexSetWithIndexesInRange: range]];
			
			i += range.length;
		}
		else if ([op isKindOfClass: [COSequenceDeletion class]])
		{
			NSRange range = NSMakeRange([op range].location + i, [op range].length);
			
			[array removeObjectsAtIndexes: [NSIndexSet indexSetWithIndexesInRange: range]];
			i -= range.length;
		}
		else if ([op isKindOfClass: [COSequenceModification class]])
		{
			COSequenceModification *opp = (COSequenceModification*)op;
			NSRange deleteRange = NSMakeRange([opp range].location + i, [opp range].length);
			NSRange insertRange = NSMakeRange([opp range].location + i, [(NSArray *)[opp insertedObject] count]);
			
			[array removeObjectsAtIndexes: [NSIndexSet indexSetWithIndexesInRange: deleteRange]];
			[array insertObjects: (NSArray *)[opp insertedObject]
					   atIndexes: [NSIndexSet indexSetWithIndexesInRange: insertRange]];
			i += (insertRange.length - deleteRange.length);
		}
		else
		{
			[NSException raise: NSInternalInconsistencyException
						format: @"Unexpected edit type"];
		}    
	}
}

- (NSArray *)arrayWithDiffAppliedTo: (NSArray *)array
{
	NSMutableArray *mutableArray = [NSMutableArray arrayWithArray: array];
	[self applyTo: mutableArray];
	return mutableArray;
}

- (id) valueWithDiffAppliedToValue: (id)aValue
{
	return [self arrayWithDiffAppliedTo: aValue];
}

@end

