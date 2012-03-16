#import "COSubtreeDiff.h"
#import "COMacros.h"
#import "ETUUID.h"
#import "COSubtree.h"
#import "COItem.h"
#import "COArrayDiff.h"
#import "COSubtreeEdits.h"


#pragma mark diff dictionary


@implementation CODiffDictionary

- (id) init
{
	SUPERINIT;
	diffDictStorage = [[NSMutableSet alloc] init];
	return self;
}

- (void)dealloc
{
	[diffDictStorage release];
	[super dealloc];
}

- (id) copyWithZone:(NSZone *)zone
{
	CODiffDictionary *result = [[[self class] alloc] init];
	
	ASSIGN(result->diffDictStorage, [[NSMutableSet alloc] initWithSet: diffDictStorage copyItems: YES]);
	
	//for (COUUIDAttributeTuple *tuple in dict)
	//{
	//	NSMutableSet *set = [[NSMutableSet alloc] initWithSet: [dict objectForKey: tuple]
	//												copyItems: YES];
	//	[result->dict setObject: set forKey: tuple];
	//	[set release];		
	//}
	
	return result;
}

- (NSSet *) editsForUUID: (ETUUID *)aUUID attribute: (NSString *)aString
{
	NSMutableSet *result = [NSMutableSet set];
	for (COSubtreeEdit *edit in diffDictStorage)
	{
		if ([[edit UUID] isEqual: aUUID] && [[edit attribute] isEqual: aString])
		{
			[result addObject: edit];
		}
	}
	return result;
}

- (NSSet *) editsForUUID: (ETUUID *)aUUID
{
	NSMutableSet *result = [NSMutableSet set];
	for (COSubtreeEdit *edit in diffDictStorage)
	{
		if ([[edit UUID] isEqual: aUUID])
		{
			[result addObject: edit];
		}
	}
	return result;
}

- (void) addEdit: (COSubtreeEdit *)anEdit
{
	[diffDictStorage addObject: anEdit];
}

- (void) removeEdit: (COSubtreeEdit *)anEdit
{
	[diffDictStorage removeObject: anEdit];
}

- (NSSet *)allEditedUUIDs
{
	NSMutableSet *result = [NSMutableSet set];
	for (COSubtreeEdit *edit in diffDictStorage)
	{
		[result addObject: [edit UUID]];
	}
	return result;
}
- (NSSet *)allEdits
{
	return [NSSet setWithSet: diffDictStorage];
}

@end



@implementation COSubtreeConflict

- (id) initWithParentDiff: (COSubtreeDiff *)aParent
{
	SUPERINIT;
	
	parentDiff = aParent;
	editsForSourceIdentifier = [[NSMutableDictionary alloc] init];

	return self;
}

- (void) dealloc
{
	[editsForSourceIdentifier release];
	[super dealloc];
}

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
 * private
 */
- (void) addEdit: (COSubtreeEdit *)anEdit
{
	NSMutableSet *set = [editsForSourceIdentifier objectForKey: [anEdit sourceIdentifier]];
	if (nil == set)
	{
		set = [NSMutableSet set];
		[editsForSourceIdentifier setObject: set forKey: [anEdit sourceIdentifier]];
	}
	[set addObject: anEdit];
}


/**
 * Defined based on -[COSubtreeEdit isEqualIgnoringSourceIdentifier:]
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
	diffDict = [[CODiffDictionary alloc] init];
	conflicts = [[NSMutableSet alloc] init];
	return self;
}

- (void) dealloc
{
	[oldRoot release];
	[newRoot release];
	[diffDict release];
	[super dealloc];
}

- (id) copyWithZone:(NSZone *)zone
{
	COSubtreeDiff *result = [[[self class] alloc] init];
	result->oldRoot = [oldRoot copyWithZone: zone];
	result->newRoot = [newRoot copyWithZone: zone];
	result->diffDict = [diffDict copyWithZone: zone];
	result->conflicts = [[NSMutableSet alloc] init];
	
	// copy conflicts. this is complicated because it has to map
	// references to the receiver's COSubtreeEdits in the receiver's COSubtreeConflicts
	// to COSubtreeEdits in 'result'.
	
	for (COSubtreeConflict *source in conflicts)
	{
		COSubtreeConflict *dest = [[COSubtreeConflict alloc] init];
		dest->parentDiff = result;
		dest->editsForSourceIdentifier = [[NSMutableDictionary alloc] init];
		
		for (id sourceIdentifier in source->editsForSourceIdentifier)
		{
			NSMutableSet *sourceEditsForSourceIdentifier = [source->editsForSourceIdentifier objectForKey: sourceIdentifier];
			NSMutableSet *destEditsForSourceIdentifier = [[NSMutableSet alloc] init];
			
			for (COSubtreeEdit *edit in sourceEditsForSourceIdentifier)
			{
				[destEditsForSourceIdentifier addObject: [result->diffDict->diffDictStorage member: edit]];
			}
			
			[dest->editsForSourceIdentifier setObject: destEditsForSourceIdentifier forKey: sourceIdentifier];
			[destEditsForSourceIdentifier release];
		}
		
		[result->conflicts addObject: dest];
		[dest release];
	}
	
	return result;
}


- (id)insertionWithLocation: (NSUInteger)aLocation
			 insertedObject: (id)anObject
		   sourceIdentifier: (id)aSource
{
}

- (id)deletionWithRange: (NSRange)aRange
	   sourceIdentifier: (id)aSource
{
}

- (id)modificationWithRange: (NSRange)aRange
			 insertedObject: (id)anObject
		   sourceIdentifier: (id)aSource
{
}


- (void) _recordSetValue: (id)aValue type: (COType *)aType forAttribute: (NSString*)anAttribute UUID: (ETUUID *)aUUID sourceIdentifier: (id)aSource
{
	COStoreItemDiffOperationSetAttribute *insertOp = nil;
	[diffDict addEdit: insertOp];
	[insertOp release];
}

- (void) _recordDeleteAttribute: (NSString*)anAttribute UUID: (ETUUID *)aUUID sourceIdentifier: (id)aSource
{
	COStoreItemDiffOperationDeleteAttribute *deleteOp = nil;
	[diffDict addEdit: deleteOp];
	[deleteOp release];
}

- (void) _diffValueBefore: (id)valueA
					after: (id)valueB
					 type: (COType *)type
				 itemUUID: (ETUUID *)itemUUID
				attribute: (NSString *)anAttribute
		 sourceIdentifier: (id)aSource
{
	if ([type isMultivalued] && ![type isOrdered])
	{

	}
	else if ([type isMultivalued] && [type isOrdered])
	{
		
	}
	else
	{
		[self _recordSetValue: valueB
						 type: type
				 forAttribute: anAttribute
						 UUID: itemUUID
			 sourceIdentifier: aSource];
	}
}



- (void) _diffItemBefore: (COItem *)itemA after: (COItem*)itemB sourceIdentifier: (id)aSource
{
	NILARG_EXCEPTION_TEST(itemB);
	
	if (itemA != nil 
		&& ![[itemA UUID] isEqual: [itemB UUID]])
	{
		[NSException raise: NSInvalidArgumentException format: @"expected same UUID"];
	}
	
	ETUUID *uuid = [itemB UUID];
	
	NSMutableSet *removedAttrs = [NSMutableSet setWithArray: [itemA attributeNames]]; // itemA may be nil => may be empty set
	[removedAttrs minusSet: [NSSet setWithArray: [itemB attributeNames]]];
	
	NSMutableSet *addedAttrs = [NSMutableSet setWithArray: [itemB attributeNames]]; 
	[addedAttrs minusSet: [NSSet setWithArray: [itemA attributeNames]]];
	
	NSMutableSet *commonAttrs = [NSMutableSet setWithArray: [itemB attributeNames]];
	[commonAttrs intersectSet: [NSSet setWithArray: [itemA attributeNames]]];
	
	
	// process 'insert attribute's
	
	for (NSString *addedAttr in addedAttrs)
	{
		[self _recordSetValue: [itemB valueForAttribute: addedAttr]
						 type: [itemB typeForAttribute: addedAttr]
				 forAttribute: addedAttr
						 UUID: uuid
			 sourceIdentifier: aSource];
	}
	
	// process deletes
	
	for (NSString *removedAttr in removedAttrs)
	{
		[self _recordDeleteAttribute: removedAttr
								UUID: uuid
					sourceIdentifier: aSource];
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
			[self _recordSetValue: valueB
							 type: typeB
					 forAttribute: commonAttr
							 UUID: uuid
				 sourceIdentifier: aSource];
		}
		else if (![valueB isEqual: valueA])
		{
			[self _diffValueBefore: valueA
							 after: valueB
							  type: typeA
						  itemUUID: uuid
						 attribute: commonAttr
				  sourceIdentifier: aSource];
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
	// FIXME
	/*
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
	*/
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
	return [diffDict allEdit];
}
- (NSSet *)conflicts
{
	return conflicts;
}

#pragma mark access

- (NSSet *)modifiedItemUUIDs
{
	return [diffDict allEditedUUIDs];
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
	[diffDict addEdit: anEdit];
	
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
	[self _updateConflictsForRemovingEdit: anEdit];
	
	[diffDict removeEdit: anEdit];
}

@end

