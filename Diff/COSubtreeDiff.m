#import "COSubtreeDiff.h"
#import "COMacros.h"
#import "ETUUID.h"
#import "COSubtree.h"
#import "COItem.h"
#import "COArrayDiff.h"


@implementation COUUIDAttributeTuple

+ (COUUIDAttributeTuple *) tupleWithUUID: (ETUUID *)aUUID attribute: (NSString *)anAttribute
{
	COUUIDAttributeTuple *result = [[[[self class] alloc] init] autorelease];
	result->uuid = [aUUID copy];
	result->attribute = [anAttribute copy];
	return result;
}

- (void) dealloc
{
	[uuid release];
	[attribute release];
	[super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
	return [self retain];
}

- (BOOL) isEqual:(id)object
{
	return [object isKindOfClass: [self class]]
		&& [uuid isEqual: [(COUUIDAttributeTuple *)object UUID]]
		&& [attribute isEqual: [(COUUIDAttributeTuple *)object attribute]];
}

- (NSUInteger) hash
{
	return 12878773850431782441ULL ^ [uuid hash] ^ [attribute hash];
}

- (ETUUID *)UUID
{
	return uuid;
}

- (NSString *)attribute
{
	return attribute;
}

@end


#pragma mark diff dictionary


@implementation CODiffDictionary

- (id) init
{
	SUPERINIT;
	dict = [[NSMutableDictionary alloc] init];
	return self;
}

- (void)dealloc
{
	[dict release];
	[super dealloc];
}

- (id) copyWithZone:(NSZone *)zone
{
	CODiffDictionary *result = [[[self class] alloc] init];
	for (COUUIDAttributeTuple *tuple in dict)
	{
		NSMutableSet *set = [[NSMutableSet alloc] initWithSet: [dict objectForKey: tuple]
													copyItems: YES];
		[result->dict setObject: set forKey: tuple];
		[set release];		
	}
	return result;
}

- (NSSet *) editsForUUID: (ETUUID *)aUUID attribute: (NSString *)aString
{
	return [self editsForTuple: [COUUIDAttributeTuple tupleWithUUID: aUUID attribute: aString]];
}

- (NSSet *) editsForTuple: (COUUIDAttributeTuple *)aTuple
{
	return [dict objectForKey: aTuple];
}

- (void) addEdit: (COSubtreeEdit *)anEdit
{
	COUUIDAttributeTuple *aTuple = [COUUIDAttributeTuple tupleWithUUID: [anEdit UUID]
															 attribute: [anEdit attribute]];
	NSMutableSet *set = [dict objectForKey: aTuple];
	if (set == nil)
	{
		set = [NSMutableSet set];
	}
	[set addObject: anEdit];
	[dict setObject: set forKey: aTuple];
}

- (void) removeEdit: (COSubtreeEdit *)anEdit
{
	for (NSMutableSet *set in [dict allValues])
	{
		if ([set containsObject: anEdit])
		{
			[set removeObject: anEdit];
			return;
		}
	}
	
	[NSException raise: NSInvalidArgumentException
				format: @"asked to remove edit %@ not in diff", anEdit];
}

- (NSArray *)allTuples
{
	return [dict allKeys];
}

@end



@implementation COSubtreeConflict
- (COSubtreeDiff *) parentDiff
{
	return parentDiff;
}

- (NSSet *) sourceIdentifiers
{
	return [NSSet setWithArray: [editsForSourceIdentifier allKeys]];
}

/**
 * @returns a set of COEdit objects owned by the parent
 * diff. the caller could for example, modify them, 
 * or remove some from the parent diff
 */
- (NSSet *) editsForSourceIdentifier: (id)anIdentifier
{
	return [editsForSourceIdentifier objectForKey: anIdentifier];
}

- (BOOL) isReallyConflicting
{
	return isReallyConflicting;
}

// FIXME

@end




@implementation COSubtreeDiff

- (id) initWithOldRootUUID: (ETUUID*)anOldRoot
			   newRootUUID: (ETUUID*)aNewRoot
{
	SUPERINIT;
	ASSIGN(oldRoot, anOldRoot);
	ASSIGN(newRoot, aNewRoot);
	diffDict = [[CODiffDictionary alloc] init];
	return self;
}

- (id) copyWithZone:(NSZone *)zone
{
	COSubtreeDiff *result = [[[self class] alloc] init];
	result->oldRoot = [oldRoot copyWithZone: zone];
	result->newRoot = [newRoot copyWithZone: zone];
	result->diffDict = [diffDict copyWithZone: zone];
	return result;
}


- (void) _diffItemBefore: (COItem *)itemA after: (COItem*)itemB
{
	NILARG_EXCEPTION_TEST(itemB);
	
	if (itemA != nil 
		&& ![[itemA UUID] isEqual: [itemB UUID]])
	{
		[NSException raise: NSInvalidArgumentException format: @"expected same UUID"];
	}
	
	NSMutableSet *removedAttrs = [NSMutableSet setWithArray: [itemA attributeNames]]; // itemA may be nil => may be empty set
	[removedAttrs minusSet: [NSSet setWithArray: [itemB attributeNames]]];
	
	NSMutableSet *addedAttrs = [NSMutableSet setWithArray: [itemB attributeNames]]; 
	[addedAttrs minusSet: [NSSet setWithArray: [itemA attributeNames]]];
	
	NSMutableSet *commonAttrs = [NSMutableSet setWithArray: [itemB attributeNames]];
	[commonAttrs intersectSet: [NSSet setWithArray: [itemA attributeNames]]];
	
	
	// process 'insert attribute's
	
	for (NSString *addedAttr in addedAttrs)
	{
		COStoreItemDiffOperationSetAttribute *insertOp = [[COStoreItemDiffOperationSetAttribute alloc] 
														  initWithType: [itemB typeForAttribute: addedAttr]
															value: [itemB valueForAttribute:addedAttr]];
		[diffDict addEdit: insertOp];
		[insertOp release];
	}
	
	// process deletes
	
	for (NSString *removedAttr in removedAttrs)
	{
		COStoreItemDiffOperationDeleteAttribute *deleteOp = [[COStoreItemDiffOperationDeleteAttribute alloc] init];
		[diffDict addEdit: deleteOp];
		[deleteOp release];
	}
	
	// process changes
	
	for (NSString *commonAttr in commonAttrs)
	{
		COType *typeA = [itemA typeForAttribute: commonAttr];
		COType *typeB = [itemB typeForAttribute: commonAttr];
		id valueA = [itemA valueForAttribute: commonAttr];
		id valueB = [itemB valueForAttribute: commonAttr];
		
		NSAssert(valueA != nil, @"value should not be nil");
		NSAssert(valueB != nil, @"value should not be nil");
		
		if (![typeB isEqual: typeA])
		{
			COStoreItemDiffOperationSetAttribute *insertOp = [[COStoreItemDiffOperationSetAttribute alloc] 
															  initWithType: typeB
																value: valueB];
			[diffDict addEdit: insertOp];
			[insertOp release];
		}
		else if (![valueB isEqual: valueA])
		{
			if ([typeA isMultivalued] && ![typeA isOrdered])
			{
				/*COSetDiff *setDiff = [[[COSetDiff alloc] initWithFirstSet: valueA
																secondSet: valueB
														 sourceIdentifier: @"FIXME"] autorelease];
				COStoreItemDiffOperationSetAttribute *editOp = [[COStoreItemDiffOperationModifySet alloc] 
																  initWithSetDiff: setDiff];
				[diffDict addEdit: editOp forUUID: uuid attribute: commonAttr];
				[editOp release];*/
			}
			else if ([typeA isMultivalued] && [typeA isOrdered])
			{
				/*COArrayDiff *arrayDiff = [[[COArrayDiff alloc] initWithFirstArray: valueA
																	  secondArray: valueB
																 sourceIdentifier: @"FIXME"] autorelease];
				COStoreItemDiffOperationModifyArray *editOp = [[COStoreItemDiffOperationModifyArray alloc] 
																	initWithArrayDiff: arrayDiff];
				[diffDict addEdit: editOp forUUID: uuid attribute: commonAttr];
				[editOp release];*/
			}
			else
			{
				COStoreItemDiffOperationSetAttribute *editOp = [[COStoreItemDiffOperationSetAttribute alloc] 
																  initWithType: typeB
																  value: valueB];
				[diffDict addEdit: editOp];
				[editOp release];
			}
		}
	}
}

+ (COSubtreeDiff *) diffSubtree: (COSubtree *)a
					withSubtree: (COSubtree *)b
			   sourceIdentifier: (id)aSource
{
	COSubtreeDiff *result = [[[self alloc] initWithOldRootUUID: [a UUID]
												   newRootUUID: [b UUID]] autorelease];

	for (ETUUID *aUUID in [b allUUIDs])
	{
		COItem *commonItemA = [[a subtreeWithUUID: aUUID] item]; // may be nil if the item was inserted in b
		COItem *commonItemB = [[b subtreeWithUUID: aUUID] item];
		
		[result _diffItemBefore: commonItemA after: commonItemB];
	}
	
	return result;
}

- (NSString *)description
{
	NSMutableString *desc = [NSMutableString stringWithString: [super description]];
	/*[desc appendFormat: @" {\n"];
	for (COStoreItemDiffOperation *edit in edits)
	{
		[desc appendFormat: @"\t%@:%@ %@\n", [edit UUID], [edit attribute], NSStringFromClass([edit class])];
	}
 	[desc appendFormat: @"}"];*/
	return desc;
}

- (COSubtree *) subtreeWithDiffAppliedToSubtree: (COSubtree *)aSubtree
{
	/**
	does applying a diff to a subtree in-place even make sense?
	 
	 any pointers to within the tree might point at deallocated objects
	 after applying the diff, since any object could be deallocated.
	 hence all pointers to within the subtree must be discarded
	 
	 also, if the root changes UUID, we would have to keep the same
	 COSubtree object but change its UUID. sounds like applying 
	 diff in-place doesn't make much sense.
	 
		 => or we could require that subtree diffs don't change the root UUID.
		 so if you want to diff/merge two subtrees with different roots, 
		 you would have to wrap them in a container. not sure if that is good....
	 
	 */

	NSMutableDictionary *newItems = [NSMutableDictionary dictionary];
	
	for (COItem *oldItem in [aSubtree allContainedStoreItems])
	{
		[newItems setObject: [[oldItem mutableCopy] autorelease]
					 forKey: [oldItem UUID]];
	}
	
	if (![[[aSubtree root] UUID] isEqual: oldRoot])
	{
		NSLog(@"WARNING: diff was created from a subtree with UUID %@ and being applied to a subtree with UUID %@", oldRoot, [[aSubtree root] UUID]);
	}
	
	for (COUUIDAttributeTuple *tuple in [diffDict allTuples])
	{
		COMutableItem *item = [newItems objectForKey: [tuple UUID]];
		
		if (item == nil)
		{
			item = [[COMutableItem alloc] initWithUUID: [tuple UUID]]; // FIXME: hack for inserted items
			[newItems setObject: item forKey: [tuple UUID]];
			[item release];
		}
		
		for (COSubtreeEdit *op in [diffDict editsForTuple: tuple])
		{
			[op applyTo: item attribute: [tuple attribute]];
		}
	}
	
	return [COSubtree subtreeWithItemSet: [NSSet setWithArray: [newItems allValues]]
								rootUUID: newRoot];
}

- (void) mergeWith: (COSubtreeDiff *)other
{
	/**
	 things that conflict:
	 - same embedded item inserted in more than one place
	 - deleting and setting the same attribute of the same object
	 */
	
	
	
}

- (COSubtreeDiff *)subtreeDiffByMergingWithDiff: (COSubtreeDiff *)other
{
	COSubtreeDiff *result = [self copy];
	[result mergeWith: other];
	return result;
}

- (BOOL) hasConflicts
{	
	for (COSubtreeConflict *conflict in conflicts)
	{
		if ([conflict isReallyConflicting])
			return YES;
	}
	return NO;
}

#pragma mark access (sub-objects may be mutated by caller)

- (NSSet *)edits
{
	NSMutableSet *allEdits = [NSMutableSet set];
	for (COUUIDAttributeTuple *tuple in [diffDict allTuples])
	{
		[allEdits unionSet: [diffDict editsForTuple: tuple]];
	}
	return [NSSet setWithSet: allEdits];
}
- (NSSet *)conflicts
{
	return conflicts;
}

#pragma mark access

- (NSSet *)modifiedItemUUIDs
{
	NSMutableSet *modifiedItemUUIDs = [NSMutableSet set];
	for (COUUIDAttributeTuple *tuple in [diffDict allTuples])
	{
		[modifiedItemUUIDs addObject: [tuple UUID]];
	}
	return [NSSet setWithSet: modifiedItemUUIDs];
}

#pragma mark mutation

/**
 * removes conflict (by extension, all the conflicting changes)... 
 * caller should subsequently insert or update edits to reflect the
 * resolution of the conflict.
 */
- (void) removeConflict: (COSubtreeConflict *)aConflict
{
	[conflicts removeObject: aConflict];
}
- (void) addEdit: (COSubtreeEdit *)anEdit
{
	[diffDict addEdit: anEdit];
}
- (void) removeEdit: (COSubtreeEdit *)anEdit
{
	[diffDict removeEdit: anEdit];
}

@end



#pragma mark operation classes



@implementation COSubtreeEdit

@synthesize UUID;
@synthesize attribute;

- (void) dealloc
{
	[UUID release];
	[attribute release];
	[super dealloc];
}

- (void) applyTo: (COMutableItem *)anItem attribute: (NSString *)anAttribute
{
	[NSException raise: NSGenericException format: @"subclass should have overridden"];
}

@end


@implementation COStoreItemDiffOperationSetAttribute

- (id) initWithType: (COType*)aType
			  value: (id)aValue
{
	SUPERINIT;
	ASSIGN(value, aValue);
	ASSIGN(type, aType);
	return self;
}

- (id) copyWithZone: (NSZone *)aZone
{
	COStoreItemDiffOperationSetAttribute *result = [[[self class] alloc] initWithType: type value: value];
	return result;
}

- (void)dealloc
{
	[value release];
	[type release];
	[super dealloc];
}

- (void) applyTo: (COMutableItem *)anItem attribute: (NSString *)anAttribute
{
	[anItem setValue: value
		forAttribute: anAttribute
				type: type];
}

@end


@implementation COStoreItemDiffOperationDeleteAttribute

- (void) applyTo: (COMutableItem *)anItem attribute: (NSString *)anAttribute
{
	if (nil == [anItem valueForAttribute: anAttribute])
	{
		[NSException raise: NSInternalInconsistencyException
					format: @"expeted attribute %@ to be already set", anAttribute];
	}
	[anItem removeValueForAttribute: anAttribute];
}

@end


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

