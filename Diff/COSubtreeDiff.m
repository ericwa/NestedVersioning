#import "COSubtreeDiff.h"
#import "COMacros.h"
#import "ETUUID.h"
#import "COSubtree.h"
#import "COItem.h"
#import "COSetDiff.h"
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
	return 12878773850431782441ULL | [uuid hash] |  [attribute hash];
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
		NSMutableArray *array = [[NSMutableArray alloc] initWithArray: [dict objectForKey: tuple]
															copyItems: YES];
		[result->dict setObject: array forKey: tuple];
		[array release];		
	}
	return result;
}

- (NSArray *) editsForUUID: (ETUUID *)aUUID attribute: (NSString *)aString
{
	return [self editsForTuple: [COUUIDAttributeTuple tupleWithUUID: aUUID attribute: aString]];
}

- (NSArray *) editsForTuple: (COUUIDAttributeTuple *)aTuple
{
	return [dict objectForKey: aTuple];
}

- (void) addEdit: (COStoreItemDiffOperation *)anEdit forUUID: (ETUUID *)aUUID attribute: (NSString *)aString
{
	COUUIDAttributeTuple *aTuple = [COUUIDAttributeTuple tupleWithUUID: aUUID attribute: aString];
	NSMutableArray *array = [dict objectForKey: aTuple];
	if (array == nil)
	{
		array = [NSMutableArray array];
	}
	[array addObject: anEdit];
	[dict setObject: array forKey: aTuple];
}

- (NSArray *)allTuples
{
	return [dict allKeys];
}

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
		COStoreItemDiffOperationSetAttribute *insertOp = [[COStoreItemDiffOperationSetAttribute alloc] 
														  initWithType: [itemB typeForAttribute: addedAttr]
															value: [itemB valueForAttribute:addedAttr]];
		[diffDict addEdit: insertOp forUUID: uuid attribute: addedAttr];
		[insertOp release];
	}
	
	// process deletes
	
	for (NSString *removedAttr in removedAttrs)
	{
		COStoreItemDiffOperationDeleteAttribute *deleteOp = [[COStoreItemDiffOperationDeleteAttribute alloc] init];
		[diffDict addEdit: deleteOp forUUID: uuid attribute: removedAttr];
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
			[diffDict addEdit: insertOp forUUID: uuid attribute: commonAttr];
			[insertOp release];
		}
		else if (![valueB isEqual: valueA])
		{
			if ([typeA isMultivalued] && ![typeA isOrdered])
			{
				COSetDiff *setDiff = [[[COSetDiff alloc] initWithFirstSet: valueA
																secondSet: valueB
														 sourceIdentifier: @"FIXME"] autorelease];
				COStoreItemDiffOperationSetAttribute *editOp = [[COStoreItemDiffOperationModifySet alloc] 
																  initWithSetDiff: setDiff];
				[diffDict addEdit: editOp forUUID: uuid attribute: commonAttr];
				[editOp release];
			}
			else if ([typeA isMultivalued] && [typeA isOrdered])
			{
				COArrayDiff *arrayDiff = [[[COArrayDiff alloc] initWithFirstArray: valueA
																	  secondArray: valueB
																 sourceIdentifier: @"FIXME"] autorelease];
				COStoreItemDiffOperationModifyArray *editOp = [[COStoreItemDiffOperationModifyArray alloc] 
																	initWithArrayDiff: arrayDiff];
				[diffDict addEdit: editOp forUUID: uuid attribute: commonAttr];
				[editOp release];
			}
			else
			{
				COStoreItemDiffOperationSetAttribute *editOp = [[COStoreItemDiffOperationSetAttribute alloc] 
																  initWithType: typeB
																  value: valueB];
				[diffDict addEdit: editOp forUUID: uuid attribute: commonAttr];
				[editOp release];
			}
		}
	}
}

+ (COSubtreeDiff *) diffSubtree: (COSubtree *)a
					withSubtree: (COSubtree *)b
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
		
		for (COStoreItemDiffOperation *op in [diffDict editsForTuple: tuple])
		{
			[op applyTo: item attribute: [tuple attribute]];
		}
	}
	
	return [COSubtree subtreeWithItemSet: [NSSet setWithArray: [newItems allValues]]
								rootUUID: newRoot];
}

- (void) mergeWith: (COSubtreeDiff *)other
{
	
}

- (COSubtreeDiff *)subtreeDiffByMergingWithDiff: (COSubtreeDiff *)other
{
	COSubtreeDiff *result = [self copy];
	[result mergeWith: other];
	return result;
}

- (BOOL) hasConflicts
{	
	return NO;
}

#pragma mark access (sub-objects may be mutated by caller)

- (NSSet *)edits
{
	return nil;
}
- (NSSet *)conflicts
{
	return nil;
}

#pragma mark access

- (NSSet *)modifiedItemUUIDs
{
	return nil;
}

#pragma mark mutation

/**
 * removes conflict (by extension, all the conflicting changes)... 
 * caller should subsequently insert or update edits to reflect the
 * resolution of the conflict.
 */
- (void) removeConflict: (COSubtreeConflict *)aConflict
{
}
- (void) addEdit: (COStoreItemDiffOperation *)anEdit
{
}
- (void) removeEdit: (COStoreItemDiffOperation *)anEdit
{
}

@end



#pragma mark item diffs 



@implementation COStoreItemDiffOperation
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


@implementation COStoreItemDiffOperationModifyArray

- (id) initWithArrayDiff: (COArrayDiff *)aDiff
{
	SUPERINIT;
	ASSIGN(arrayDiff, aDiff);
	return self;
}

- (id) copyWithZone: (NSZone *)aZone
{
	COStoreItemDiffOperationModifyArray *result = [[[self class] alloc] init];
	result->arrayDiff = [arrayDiff retain]; // FIXME!!!
	return result;
}

- (void)dealloc
{
	[arrayDiff release];
	[super dealloc];
}

- (void) applyTo: (COMutableItem *)anItem attribute: (NSString *)anAttribute
{
	NSArray *oldValue = [anItem valueForAttribute: anAttribute];
	NSArray *newValue = [arrayDiff arrayWithDiffAppliedTo: oldValue];
	[anItem setValue: newValue
		forAttribute: anAttribute
				type: [anItem typeForAttribute: anAttribute]];
}

@end


@implementation COStoreItemDiffOperationModifySet

- (id) initWithSetDiff: (COSetDiff *)aDiff
{
	SUPERINIT;
	ASSIGN(setDiff, aDiff);
	return self;
}

- (id) copyWithZone: (NSZone *)aZone
{
	COStoreItemDiffOperationModifySet *result = [[[self class] alloc] init];
	result->setDiff = [setDiff retain]; // FIXME!!!
	return result;
}

- (void)dealloc
{
	[setDiff release];
	[super dealloc];
}

- (void) applyTo: (COMutableItem *)anItem attribute: (NSString *)anAttribute
{
	NSSet *oldValue = [anItem valueForAttribute: anAttribute];
	NSSet *newValue = [setDiff setWithDiffAppliedTo: oldValue];
	[anItem setValue: newValue
		forAttribute: anAttribute
				type: [anItem typeForAttribute: anAttribute]];
}

@end

