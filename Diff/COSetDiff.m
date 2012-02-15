#import "COSetDiff.h"
#import "COMacros.h"

@implementation COSetDiff

- (id) initWithFirstSet: (NSSet *)first
              secondSet: (NSSet *)second
	   sourceIdentifier: (id)aSource
{
	NILARG_EXCEPTION_TEST(aSource);
	
	NSMutableSet *insertions = [NSMutableSet setWithSet: second];
	[insertions minusSet: first];
	
	NSMutableSet *deletions = [NSMutableSet setWithSet: first];
	[deletions minusSet: second];
	
	SUPERINIT;
	ASSIGN(insertionsForSourceIdentifier, [NSDictionary dictionaryWithObject: insertions forKey: aSource]);
	ASSIGN(deletionsForSourceIdentifier, [NSDictionary dictionaryWithObject: deletions forKey: aSource]);
	return self;
}

- (void) dealloc
{
	[insertionsForSourceIdentifier release];
	[deletionsForSourceIdentifier release];
	[super dealloc];
}

- (NSSet *)insertionSet
{
	NSMutableSet *added = [NSMutableSet set];
	for (NSSet *addition in [insertionsForSourceIdentifier allValues])
	{
		[added unionSet: addition];
	}
	return added;
}

- (NSSet *)deletionSet
{
	NSMutableSet *removed = [NSMutableSet set];
	for (NSSet *removal in [deletionsForSourceIdentifier allValues])
	{
		[removed unionSet: removal];
	}
	return removed;
}

- (NSSet *)insertionSetForSourceIdentifier: (id)anIdentifier
{
	return [insertionsForSourceIdentifier objectForKey: anIdentifier];
}

- (NSSet *)deletionSetForSourceIdentifier: (id)anIdentifier
{
	return [deletionsForSourceIdentifier objectForKey: anIdentifier];
}

- (void) applyTo: (NSMutableSet*)set
{
	for (NSSet *addition in [insertionsForSourceIdentifier allValues])
	{
		[set unionSet: addition];
	}
	for (NSSet *removal in [deletionsForSourceIdentifier allValues])
	{
		[set minusSet: removal];
	}
}

- (NSSet *)setWithDiffAppliedTo: (NSSet *)set;
{
	NSMutableSet *mutableSet = [NSMutableSet setWithSet: set];
	[self applyTo: mutableSet];
	return mutableSet;
}

- (id) valueWithDiffAppliedToValue: (id)aValue
{
	return [self setWithDiffAppliedTo: aValue];
}

- (COSetDiff *)setDiffByMergingWithDiff: (COSetDiff *)other
{  
	if ([[self deletionSet] intersectsSet: [other insertionSet]]
		|| [[self insertionSet] intersectsSet: [other deletionSet]])
	{
		[NSException raise: NSInvalidArgumentException
					format: @"set diffs being merged could not have originated from the same set and are illegal to merge"];
	}
	
	if ([[NSSet setWithArray: [insertionsForSourceIdentifier allKeys]] intersectsSet: 
			[NSSet setWithArray: [other->insertionsForSourceIdentifier allKeys]]]
		|| [[NSSet setWithArray: [deletionsForSourceIdentifier allKeys]] intersectsSet: 
			[NSSet setWithArray: [other->deletionsForSourceIdentifier allKeys]]])
	{
		[NSException raise: NSInvalidArgumentException
					format: @"set diffs being merged should have unique source identifiers"];
	}
	
	NSMutableDictionary *newInsertions = [NSMutableDictionary dictionaryWithDictionary: insertionsForSourceIdentifier];
	[newInsertions addEntriesFromDictionary: other->insertionsForSourceIdentifier];
	
	NSMutableDictionary *newDeletions = [NSMutableDictionary dictionaryWithDictionary: deletionsForSourceIdentifier];
	[newDeletions addEntriesFromDictionary: other->deletionsForSourceIdentifier];
	
	COSetDiff *result = [[[COSetDiff alloc] init] autorelease];
	ASSIGN(result->insertionsForSourceIdentifier, newInsertions);
	ASSIGN(result->deletionsForSourceIdentifier, newDeletions);
	return result;
}

@end
