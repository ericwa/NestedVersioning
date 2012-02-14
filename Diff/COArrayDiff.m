#import "COArrayDiff.h"
#include "diff.h"

#import "COMacros.h"

static bool comparefn(size_t i, size_t j, void *userdata1, void *userdata2)
{
	return [[(NSArray*)userdata1 objectAtIndex: i] isEqual:
	[(NSArray*)userdata2 objectAtIndex: j]];
}

@interface COArrayDiff (Private)

- (void)diffWithA: (NSArray*)a B: (NSArray*)b;

@end

@implementation COArrayDiff

- (id) initWithFirstArray: (NSArray *)first secondArray: (NSArray *)second
{
	SUPERINIT;
	[self diffWithA:first
				  B:second];
	return self;
}

- (void) dealloc
{
	[ops release];
	[super dealloc];
}

#if 0
- (void)diffWithA: (NSArray*)a B: (NSArray*)b
{
	ops = [[NSMutableArray alloc] init];
	
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
					[ops addObject: [COArrayDiffOperationInsert insertWithLocation: firstRange.location
																		   objects: [b subarrayWithRange: secondRange]]];
				}
				break;
			case difftype_deletion:
				[ops addObject: [COArrayDiffOperationDelete deleteWithRange: firstRange]];
				break;
			case difftype_modification:
				[ops addObject: [COArrayDiffOperationModify modifyWithRange: firstRange
																 newObjects: [b subarrayWithRange: secondRange]]];
				break;
		}
	}
	
	diff_free(result);
}



/**
 * Applys the receiver to the given mutable array
 */
- (void) applyTo: (NSMutableArray*)array
{
	NSInteger i = 0;
	for (COSequenceDiffOperation *op in ops)
	{
		if ([op isKindOfClass: [COArrayDiffOperationInsert class]])
		{
			COArrayDiffOperationInsert *opp = (COArrayDiffOperationInsert*)op;
			NSRange range = NSMakeRange([op range].location + i, [[opp insertedObjects] count]);
			
			[array insertObjects: [opp insertedObjects]
					   atIndexes: [NSIndexSet indexSetWithIndexesInRange: range]];
			
			i += range.length;
		}
		else if ([op isKindOfClass: [COArrayDiffOperationDelete class]])
		{
			NSRange range = NSMakeRange([op range].location + i, [op range].length);
			
			[array removeObjectsAtIndexes: [NSIndexSet indexSetWithIndexesInRange: range]];
			i -= range.length;
		}
		else if ([op isKindOfClass: [COArrayDiffOperationModify class]])
		{
			COArrayDiffOperationModify *opp = (COArrayDiffOperationModify*)op;
			NSRange deleteRange = NSMakeRange([opp range].location + i, [opp range].length);
			NSRange insertRange = NSMakeRange([opp range].location + i, [[opp insertedObjects] count]);
			
			[array removeObjectsAtIndexes: [NSIndexSet indexSetWithIndexesInRange: deleteRange]];
			[array insertObjects: [opp insertedObjects]
					   atIndexes: [NSIndexSet indexSetWithIndexesInRange: insertRange]];
			i += (insertRange.length - deleteRange.length);
		}
		else
		{
			assert(0);
		}    
	}
}
#endif

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

