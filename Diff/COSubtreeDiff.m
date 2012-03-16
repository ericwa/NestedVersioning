#import "COSubtreeDiff.h"
#import "COMacros.h"
#import "ETUUID.h"
#import "COSubtree.h"
#import "COItem.h"
#import "COArrayDiff.h"



#pragma mark diff dictionary



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

- (NSSet *) allEdits
{
	NSMutableSet *result = [NSMutableSet set];
	for (NSSet *edits in [editsForSourceIdentifier allValues])
	{
		[result unionSet: edits];
	}
	return result;
}

/**
 * private
 */
- (void) removeEdit: (COSubtreeEdit *)anEdit
{
	for (NSMutableSet *edits in [editsForSourceIdentifier allValues])
	{
		if ([edits containsObject: anEdit])
		{
			[edits removeObject: anEdit];
		}
	}
}

/**
 * Defined based on -[COSubtreeEdit isNonconflictingWith:]
 */
- (BOOL) isNonconflicting
{
	NSSet *allEdits = [self allEdits];
	if ([allEdits count] > 0)
	{
		COSubtreeEdit *referenceEdit = [allEdits anyObject];
		for (COSubtreeEdit *edit in allEdits)
		{
			if (![referenceEdit isEqualIgnoringSourceIdentifier: edit])
				return NO;
		}
	}
	return YES;
}

// FIXME

@end




@implementation COSubtreeDiff

#pragma mark other stuff

- (id) initWithOldRootUUID: (ETUUID*)anOldRoot
			   newRootUUID: (ETUUID*)aNewRoot
{
	SUPERINIT;
	ASSIGN(oldRoot, anOldRoot);
	ASSIGN(newRoot, aNewRoot);
	dict = [[NSMutableDictionary alloc] init];
	return self;
}

- (void) dealloc
{
	[oldRoot release];
	[newRoot release];
	[dict release];
	[super dealloc];
}

- (id) copyWithZone:(NSZone *)zone
{
	COSubtreeDiff *result = [[[self class] alloc] init];
	result->oldRoot = [oldRoot copyWithZone: zone];
	result->newRoot = [newRoot copyWithZone: zone];
	
	// copy dict
	
	for (COUUIDAttributeTuple *tuple in dict)
	{
		NSMutableSet *set = [[NSMutableSet alloc] initWithSet: [dict objectForKey: tuple]
													copyItems: YES];
		[result->dict setObject: set forKey: tuple];
		[set release];		
	}
	
	return result;
}


- (id)insertionWithLocation: (NSUInteger)aLocation
			 insertedObject: (id)anObject
		   sourceIdentifier: (id)aSource;

- (id)deletionWithRange: (NSRange)aRange
	   sourceIdentifier: (id)aSource;

- (id)modificationWithRange: (NSRange)aRange
			 insertedObject: (id)anObject
		   sourceIdentifier: (id)aSource;




i


- (void) _diffValueBefore: (id)valueA
					after: (id)valueB
					 type: (COType *)type
				 itemUUID: (ETUUID *)itemUUID
				attribute: (NSString *)anAttribute
{
	if ([type isMultivalued] && ![type isOrdered])
	{
		/*COSetDiff *setDiff = [[[COSetDiff alloc] initWithFirstSet: valueA
		 secondSet: valueB
		 sourceIdentifier: @"FIXME"] autorelease];
		 COStoreItemDiffOperationSetAttribute *editOp = [[COStoreItemDiffOperationModifySet alloc] 
		 initWithSetDiff: setDiff];
		 [diffDict addEdit: editOp forUUID: uuid attribute: commonAttr];
		 [editOp release];*/
	}
	else if ([type isMultivalued] && [type isOrdered])
	{
		
	}
	else
	{
		COStoreItemDiffOperationSetAttribute *editOp = [[COStoreItemDiffOperationSetAttribute alloc] 
														initWithType: type
														value: valueB];
		[diffDict addEdit: editOp];
		[editOp release];
	}
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
			[self _diffValueBefore: valueA
							 after: valueB
							  type: typeA
						  itemUUID: [itemA UUID]
						 attribute:  commonAttr];
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
		
		[result _diffItemBefore: commonItemA after: commonItemB sourceIdentifier: aSource];
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
		
		// FIXME: special handling for array edits.
		
		for (COSubtreeEdit *op in [diffDict editsForTuple: tuple])
		{
			[op applyTo: item];
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
		if (![conflict isNonconflicting])
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
 *
 * note that if an edit is part of two confclits, removing one
 * conflict will also delete all of its edits, including any
 * that are in other conflicts.
 */
- (void) removeConflict: (COSubtreeConflict *)aConflict
{
	for (COSubtreeEdit *edit in [aConflict allEdits])
	{
		[self removeEdit: edit];
	}
	[conflicts removeObject: aConflict];
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
	
	[self _updateConflictsForAddingEdit: anEdit];
}

- (void) _updateConflictsForRemovingEdit: (COSubtreeEdit *)anEdit
{
	for (COSubtreeConflict *conflict in [NSSet setWithSet: conflicts])
	{
		for (COSubtreeEdit *edit in [conflict allEdits])
		{
			if (edit == anEdit)
			{
				[conflict removeEdit: edit];
			}
		}
	}
}

- (void) removeEdit: (COSubtreeEdit *)anEdit
{
	for (NSMutableSet *set in [dict allValues])
	{
		if ([set containsObject: anEdit])
		{
			[self _updateConflictsForRemovingEdit: anEdit];
			
			[set removeObject: anEdit];
			return;
		}
	}
	
	[NSException raise: NSInvalidArgumentException
				format: @"asked to remove edit %@ not in diff", anEdit];
}

@end

