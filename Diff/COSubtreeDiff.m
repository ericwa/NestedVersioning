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

- (NSSet *) modifiedAttributesForUUID: (ETUUID *)aUUID
{
	NSMutableSet *result = [NSMutableSet set];
	for (COSubtreeEdit *edit in diffDictStorage)
	{
		if ([[edit UUID] isEqual: aUUID])
		{
			[result addObject: [edit attribute]];
		}
	}
	return [NSSet setWithSet: result];
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
	return [NSSet setWithSet: result];
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
	return [NSSet setWithSet: result];
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
	return [NSSet setWithSet: result];
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

- (id) copyWithZone: (NSZone *)aZone
{
	COSubtreeConflict *aCopy = [[[self class] allocWithZone: aZone] init];
	aCopy->parentDiff = nil;
	aCopy->editsForSourceIdentifier = [[NSMutableDictionary alloc] init];
	for (id aSource in editsForSourceIdentifier)
	{
		NSMutableSet *aSet = [editsForSourceIdentifier objectForKey: aSource];
		[aCopy->editsForSourceIdentifier setObject: [NSMutableSet setWithSet: aSet]
											forKey: aSource];
	}
	
	return aCopy;
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
	embeddedItemInsertionConflicts = [[NSMutableSet alloc] init];
	equalEditConflicts = [[NSMutableSet alloc] init];
	sequenceEditConflicts = [[NSMutableSet alloc] init];
	editTypeConflicts = [[NSMutableSet alloc] init];
	return self;
}

- (void) dealloc
{
	[oldRoot release];
	[newRoot release];
	[diffDict release];
	[embeddedItemInsertionConflicts release];
	[equalEditConflicts release];
	[sequenceEditConflicts release];
	[editTypeConflicts release];
	[super dealloc];
}

- (id) copyWithZone:(NSZone *)zone
{
	COSubtreeDiff *result = [[[self class] alloc] init];
	result->oldRoot = [oldRoot copyWithZone: zone];
	result->newRoot = [newRoot copyWithZone: zone];
	result->diffDict = [diffDict copyWithZone: zone];
	
	result->embeddedItemInsertionConflicts = [[NSMutableSet alloc] initWithSet: embeddedItemInsertionConflicts
																	 copyItems: YES];
	result->equalEditConflicts = [[NSMutableSet alloc] initWithSet: equalEditConflicts
														 copyItems: YES];
	result->sequenceEditConflicts = [[NSMutableSet alloc] initWithSet: sequenceEditConflicts
															copyItems: YES];
	result->editTypeConflicts = [[NSMutableSet alloc] initWithSet: editTypeConflicts
														copyItems: YES];

	for (COSubtreeConflict *conflict in result->embeddedItemInsertionConflicts)
	{
		conflict->parentDiff = result;
	}
	for (COSubtreeConflict *conflict in result->equalEditConflicts)
	{
		conflict->parentDiff = result;
	}
	for (COSubtreeConflict *conflict in result->sequenceEditConflicts)
	{
		conflict->parentDiff = result;
	}
	for (COSubtreeConflict *conflict in result->editTypeConflicts)
	{
		conflict->parentDiff = result;
	}
	
	/*
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
	*/
	
	
	return result;
}

// begin CODiffArraysDelegate

- (void)recordInsertionWithLocation: (NSUInteger)aLocation
					insertedObjects: (id)anArray
						   userInfo: (id)info
{
	COSequenceInsertion *op = [[COSequenceInsertion alloc] initWithUUID: [info objectForKey: @"UUID"]
															  attribute: [info objectForKey: @"attribute"]
													   sourceIdentifier: [info objectForKey: @"sourceIdentifier"]
															   location: aLocation
																   type: [info objectForKey: @"type"]
																objects: anArray];
	[self addEdit: op];
	[op release];
}

- (void)recordDeletionWithRange: (NSRange)aRange
					   userInfo: (id)info
{
	COSequenceDeletion *op = [[COSequenceDeletion alloc] initWithUUID: [info objectForKey: @"UUID"]
															attribute: [info objectForKey: @"attribute"]
													 sourceIdentifier: [info objectForKey: @"sourceIdentifier"]
																range: aRange];
	[self addEdit: op];
	[op release];
}

- (void)recordModificationWithRange: (NSRange)aRange
					insertedObjects: (id)anArray
						   userInfo: (id)info
{
	COSequenceModification *op = [[COSequenceModification alloc] initWithUUID: [info objectForKey: @"UUID"]
																	attribute: [info objectForKey: @"attribute"]
															 sourceIdentifier: [info objectForKey: @"sourceIdentifier"]
																		range: aRange
																		 type: [info objectForKey: @"type"]
																	  objects: anArray];
	[self addEdit: op];
	[op release];
}

// end CODiffArraysDelegate

- (void) _recordSetValue: (id)aValue type: (COType *)aType forAttribute: (NSString*)anAttribute UUID: (ETUUID *)aUUID sourceIdentifier: (id)aSourceIdentifier
{
	COSetAttribute *op = [[COSetAttribute alloc] initWithUUID: aUUID attribute: anAttribute sourceIdentifier: aSourceIdentifier type: aType value: aValue];
	[self addEdit: op];
	[op release];
}

- (void) _recordDeleteAttribute: (NSString*)anAttribute UUID: (ETUUID *)aUUID sourceIdentifier: (id)aSourceIdentifier
{
	CODeleteAttribute *op = [[COSetAttribute alloc] initWithUUID: aUUID attribute: anAttribute sourceIdentifier: aSourceIdentifier];
	[self addEdit: op];
	[op release];
}

- (void) _recordSetInsertionOfValue: (id)aValue type: (COType *)aType forAttribute: (NSString*)anAttribute UUID: (ETUUID *)aUUID sourceIdentifier: (id)aSourceIdentifier
{
	COSetInsertion *op = [[COSetInsertion alloc] initWithUUID: aUUID attribute: anAttribute sourceIdentifier: aSourceIdentifier type: aType object: aValue];
	[self addEdit: op];
	[op release];
}

- (void) _recordSetDeletionOfValue: (id)aValue type: (COType *)aType forAttribute: (NSString*)anAttribute UUID: (ETUUID *)aUUID sourceIdentifier: (id)aSourceIdentifier
{
	COSetDeletion *op = [[COSetDeletion alloc] initWithUUID: aUUID attribute: anAttribute sourceIdentifier: aSourceIdentifier type: aType object: aValue];
	[self addEdit: op];
	[op release];
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
		NSMutableSet *insertions = [NSMutableSet setWithSet: (NSSet *)valueB];
		[insertions minusSet: (NSSet *)valueA];
		
		for (id value in insertions)
		{
			[self _recordSetInsertionOfValue: value type: type forAttribute: anAttribute UUID: itemUUID sourceIdentifier: aSource];
		}
		
		NSMutableSet *deletions = [NSMutableSet setWithSet: (NSSet *)valueA];
		[deletions minusSet: (NSSet *)valueB];
		
		for (id value in deletions)
		{
			[self _recordSetDeletionOfValue: value type: type forAttribute: anAttribute UUID: itemUUID sourceIdentifier: aSource];
		}
	}
	else if ([type isMultivalued] && [type isOrdered])
	{
		CODiffArrays(valueA, valueB, self, D(itemUUID, @"UUID", anAttribute, @"attribute", aSource, @"sourceIdentifier", type, @"type"));
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
	[desc appendFormat: @" {\n"];
	for (COSubtreeEdit *edit in [self allEdits])
	{
		[desc appendFormat: @"\t%@\n", [edit description]];
	}
 	[desc appendFormat: @"}"];
	return desc;
}

static void COApplyEditsToMutableItem(NSSet *edits, COMutableItem *anItem)
{
	COSubtreeEdit *anyEdit = [edits anyObject];
	
	// set, delete attribute
	
	if ([anyEdit isKindOfClass: [COSetAttribute class]])
	{
		assert([edits count] == 1);
		[anItem setValue: [(COSetAttribute *)anyEdit value]
			forAttribute: [anyEdit attribute]
					type: [(COSetAttribute *)anyEdit type]];
		return;
	}
	
	if ([anyEdit isKindOfClass: [CODeleteAttribute class]])
	{
		assert([edits count] == 1);
		[anItem removeValueForAttribute: [anyEdit attribute]];
		return;
	}
	
	// editing set multivalueds
	
	if ([anyEdit isKindOfClass: [COSetInsertion class]] || 
		[anyEdit isKindOfClass: [COSetDeletion class]])
	{
		NSMutableSet *newSet = [NSMutableSet setWithSet: [anItem valueForAttribute: [anyEdit attribute]]];
		
		for (COSubtreeEdit *edit in edits)
		{
			if ([edit isMemberOfClass: [COSetInsertion class]])
			{
				[newSet addObject: [(COSetInsertion *)edit object]];
			}
			else if ([edit isMemberOfClass: [COSetDeletion class]])
			{
				[newSet removeObject: [(COSetDeletion *)edit object]];
			}
			else
			{
				[NSException raise: NSInternalInconsistencyException
							format: @"unknown set edit type: %@", edit];
			}
		}
		
		[anItem setValue: newSet
			forAttribute: [anyEdit attribute]
					type: [anItem typeForAttribute: [anyEdit attribute]]];
		return;
	}
	
	// editing array multivalue
	
	if ([anyEdit isKindOfClass: [COSequenceEdit class]])
	{
		for (COSubtreeEdit *edit in [edits allObjects])
		{
			if (![edit isKindOfClass: [COSequenceEdit class]])
			{
				[NSException raise: NSInternalInconsistencyException
							format: @"all edits should be sequence edits"];
			}
		}
		
		NSArray *editsSorted = [[edits allObjects] sortedArrayUsingSelector: @selector(compare:)];
		
		NSArray *originalArray = [anItem valueForAttribute: [anyEdit attribute]];
		NSArray *newArray = COArrayByApplyingEditsToArray(originalArray, editsSorted);
		
		[anItem setValue: newArray
			forAttribute: [anyEdit attribute]
					type: [anItem typeForAttribute: [anyEdit attribute]]];
		return;
	}
	
	[NSException raise: NSInternalInconsistencyException
				format: @"unknown edit type %@", anyEdit];
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

	if (![[[aSubtree root] UUID] isEqual: oldRoot])
	{
		[NSException raise: NSInvalidArgumentException
					format: @"diff was created from a subtree with UUID %@ and being applied to a subtree with UUID %@", oldRoot, [[aSubtree root] UUID]];
	}
	
	if ([self hasConflicts])
	{
		[NSException raise: NSInvalidArgumentException
					format: @"resolve conflicts before applying diff"];	
	}
	
	// set up dictionary to store items in
	
	NSMutableDictionary *newItems = [NSMutableDictionary dictionary];
	
	for (COItem *oldItem in [aSubtree allContainedStoreItems])
	{
		[newItems setObject: [[oldItem mutableCopy] autorelease]
					 forKey: [oldItem UUID]];
	}
	
	// apply all of the edits
	
	for (ETUUID *modifiedUUID in [diffDict allEditedUUIDs])
	{
		COMutableItem *item = [newItems objectForKey: modifiedUUID];
		
		if (item == nil)
		{
			item = [[COMutableItem alloc] initWithUUID: modifiedUUID];
			[newItems setObject: item forKey: modifiedUUID];
			[item release];
		}		
		
		for (NSString *modifiedAttribute in [diffDict modifiedAttributesForUUID: modifiedUUID])
		{
			NSSet *edits = [diffDict editsForUUID: modifiedUUID attribute: modifiedAttribute];
			
			assert([edits count] > 0);
		
			COApplyEditsToMutableItem(edits, item);
		}
	}
	
	return [COSubtree subtreeWithItemSet: [NSSet setWithArray: [newItems allValues]]
								rootUUID: newRoot];
}

- (void) mergeWith: (COSubtreeDiff *)other
{
	if (![other->oldRoot isEqual: self->oldRoot]
		|| ![other->newRoot isEqual: self->newRoot])
	{
		[NSException raise: NSInvalidArgumentException
					format: @"for now, merging subtree diffs with conflicting changes to the root UUID of the tree is unsupported."];
	}	
	
	for (COSubtreeEdit *edit in [other allEdits])
	{
		[self addEdit: edit];
	}
}

- (COSubtreeDiff *)subtreeDiffByMergingWithDiff: (COSubtreeDiff *)other
{
	COSubtreeDiff *result = [self copy];
	[result mergeWith: other];
	return result;
}

- (BOOL) hasConflicts
{	
	for (COSubtreeConflict *conflict in [self conflicts])
	{
		if (![conflict isNonconflicting])
			return YES;
	}
	return NO;
}

#pragma mark access (sub-objects may be mutated by caller)

- (NSSet *)allEdits
{
	return [diffDict allEdits];
}
- (NSSet *)conflicts
{
	NSMutableSet *result = [NSMutableSet set];
	[result unionSet: embeddedItemInsertionConflicts];
	[result unionSet: equalEditConflicts];
	[result unionSet: sequenceEditConflicts];
	[result unionSet: editTypeConflicts];
	return [NSSet setWithSet: result];
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
 * that are in other conflicts. (but this method uses
 * -[self removeEdit:] which will handle updating those
 * other conflicts.)
 */
- (void) removeConflict: (COSubtreeConflict *)aConflict
{
	for (COSubtreeEdit *edit in [aConflict allEdits])
	{
		[self removeEdit: edit];
	}
	[embeddedItemInsertionConflicts removeObject: aConflict];
	[equalEditConflicts removeObject: aConflict];
	[sequenceEditConflicts removeObject: aConflict];
	[editTypeConflicts removeObject: aConflict];
}

- (COSubtreeConflict *) findOrCreateConflictInMutableSet: (NSMutableSet *)aSet containingEdit: (COSubtreeEdit *)existingEdit
{
	COSubtreeConflict *conflict = nil;
	
	for (COSubtreeConflict *aConflict in aSet)
	{
		if ([[aConflict allEdits] containsObject: existingEdit])
		{
			conflict = aConflict;
			break;
		}
	}
	
	if (conflict == nil)
	{
		conflict = [[[COSubtreeConflict alloc] initWithParentDiff: self] autorelease];
		[conflict addEdit: existingEdit];
		[aSet addObject: conflict];
	}
	
	return conflict;
}


- (NSSet *) embeddedItemInsertionConflicts // insert item uuid X at two different places
{
	return embeddedItemInsertionConflicts;
}

- (void) recordEmbeddedItemInsertionConflictEdit: (COSubtreeEdit *)newEdit withEdit: (COSubtreeEdit *)existingEdit
{
	COSubtreeConflict *conflict = [self findOrCreateConflictInMutableSet: embeddedItemInsertionConflicts containingEdit: existingEdit];
	[conflict addEdit: newEdit];
}

- (NSSet *) equalEditConflicts // e.g. set [4:2] to ("h", "i") and [4:2] to ("h", "i")
{
	return equalEditConflicts;
}

- (void) recordEqualEditConflictEdit: (COSubtreeEdit *)newEdit withEdit: (COSubtreeEdit *)existingEdit
{
	COSubtreeConflict *conflict = [self findOrCreateConflictInMutableSet: equalEditConflicts containingEdit: existingEdit];
	[conflict addEdit: newEdit];
}

- (NSSet *) sequenceEditConflicts // e.g. set [4:5] and [4:3]. doesn't include equal sequence edit conflicts
{
	return sequenceEditConflicts;
}

- (void) recordSequenceEditConflictEdit: (COSubtreeEdit *)newEdit withEdit: (COSubtreeEdit *)existingEdit
{
	COSubtreeConflict *conflict = [self findOrCreateConflictInMutableSet: sequenceEditConflicts containingEdit: existingEdit];
	[conflict addEdit: newEdit];
}

- (NSSet *) editTypeConflicts // e.g. delete + set
{
	return editTypeConflicts;
}

- (void) recordEditTypeConflictEdit: (COSubtreeEdit *)newEdit withEdit: (COSubtreeEdit *)existingEdit
{
	COSubtreeConflict *conflict = [self findOrCreateConflictInMutableSet: editTypeConflicts containingEdit: existingEdit];
	[conflict addEdit: newEdit];
}

- (void) _updateConflictsForAddingEdit: (COSubtreeEdit *)anEdit
{
	/**
	two types of conflicts:
	  - A. all edits in the conflict belong to the same UUID.attribute
	  - B. not all edits in the conflict belong to the same UUID.attribute
	 
	 -type B conflicts are all "embedded item inserted in more than one place" conflicts.
	 -"embedded item inserted in more than one place" conflicts can also be type A conflicts
	   (diff x inserts Q at index 0, diff y inserts Q at index 3...)
	 
	 -conflict uniqueness:
	 
		= each edit can belong to at most 1 "embedded item inserted in more than one place" conflict
	    = "equal edit" conflicts should be separate from other conflicts
        = overlapping, but non-equal, sequence edit conflicts should be separate from other conflicts (?)
		= "conflicting edit types for UUID.attribute" conflicts should be separate from other conflicts.
	 
	 so, each edit could be in up to 4 conflicts.
	 
	 */

	// check for existing edits for that same attribute
	
	NSSet *existingEditsForSameAttribute = [diffDict editsForUUID: [anEdit UUID]
														attribute: [anEdit attribute]];
	
	if ([existingEditsForSameAttribute count] > 0)
	{
		// first, check for the existing edits being of a different type (automatic conflict)
		
		for (COSubtreeEdit *edit in existingEditsForSameAttribute)
		{
			if (![anEdit isSameKindOfEdit: edit])
			{
				[self recordEditTypeConflictEdit: anEdit withEdit: edit];
			}
		}
		
		// now check for, if it is a sequence edit, overlapping edits
		
		if ([anEdit isKindOfClass: [COSequenceEdit class]])
		{
			
			// remember, some of these might be "equal" - they don't count as sequence edits
		}
		
		// create a conflict for equal edits
		
	}

	// check for same embedded item inserted in more than one place
	
	NSSet *anEditEmbeddedItemInsertions = [anEdit insertedEmbeddedItemUUIDs];
	for (COSubtreeEdit *edit in [self allEdits])
	{
		if (![edit isEqual: anEdit])
		{
			NSSet *editEmbeddedItemInsertions = [edit insertedEmbeddedItemUUIDs];
			if ([anEditEmbeddedItemInsertions intersectsSet: editEmbeddedItemInsertions])
			{
				// edit and anEdit conflict! create a new conflict or update an existing one.
				[self recordEmbeddedItemInsertionConflictEdit: anEdit withEdit: edit];
			}
		}
	}
}

- (void) addEdit: (COSubtreeEdit *)anEdit
{
	[diffDict addEdit: anEdit];
	
	[self _updateConflictsForAddingEdit: anEdit];
}

- (void) _updateConflictsForRemovingEdit: (COSubtreeEdit *)anEdit
{
	for (COSubtreeConflict *conflict in [self conflicts])
	{
		for (COSubtreeEdit *edit in [conflict allEdits])
		{
			if (edit == anEdit)
			{
				[conflict removeEdit: edit];
			}
		}
		// FIXME: remove the conflict if it has no edits left?
	}
}

- (void) removeEdit: (COSubtreeEdit *)anEdit
{
	[self _updateConflictsForRemovingEdit: anEdit];
	
	[diffDict removeEdit: anEdit];
}

@end

