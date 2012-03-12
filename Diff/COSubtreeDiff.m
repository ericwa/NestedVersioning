#import "COSubtreeDiff.h"
#import "COMacros.h"
#import "ETUUID.h"
#import "COSubtree.h"
#import "COItem.h"
#import "COSetDiff.h"
#import "COArrayDiff.h"

@implementation COSubtreeDiff

- (id) initWithOldRootUUID: (ETUUID*)anOldRoot
			   newRootUUID: (ETUUID*)aNewRoot
{
	SUPERINIT;
	ASSIGN(oldRoot, anOldRoot);
	ASSIGN(newRoot, aNewRoot);
	ASSIGN(edits, [NSMutableSet set]);
	return self;
}

- (id) copyWithZone:(NSZone *)zone
{
	COSubtreeDiff *result = [[[self class] alloc] init];
	result->oldRoot = [oldRoot copyWithZone: zone];
	result->newRoot = [newRoot copyWithZone: zone];
	result->edits = [[NSMutableArray alloc] initWithArray: edits copyItems: YES];
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
														  initWithUUID: uuid
														  attribute: addedAttr
														  type: [itemB typeForAttribute: addedAttr]
														  value: [itemB valueForAttribute:addedAttr]];
		[edits addObject: insertOp];
		[insertOp release];
	}
	
	// process deletes
	
	for (NSString *removedAttr in removedAttrs)
	{
		COStoreItemDiffOperationDeleteAttribute *deleteOp = [[COStoreItemDiffOperationDeleteAttribute alloc] 
															 initWithUUID: uuid
															 attribute: removedAttr
															 type: [itemA typeForAttribute: removedAttr]];
		[edits addObject: deleteOp];
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
															  initWithUUID: uuid
															  attribute: commonAttr
															  type: typeB
															  value: valueB];
			[edits addObject: insertOp];
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
																  initWithUUID: uuid
																  attribute: commonAttr
																  type: typeB
																  setDiff: setDiff];
				[edits addObject: editOp];
				[editOp release];
			}
			else if ([typeA isMultivalued] && [typeA isOrdered])
			{
				COArrayDiff *arrayDiff = [[[COArrayDiff alloc] initWithFirstArray: valueA
																	  secondArray: valueB
																 sourceIdentifier: @"FIXME"] autorelease];
				COStoreItemDiffOperationModifyArray *editOp = [[COStoreItemDiffOperationModifyArray alloc] 
																	initWithUUID: uuid
																	attribute: commonAttr
																	type: typeB
																arrayDiff: arrayDiff];
				[edits addObject: editOp];
				[editOp release];
			}
			else
			{
				COStoreItemDiffOperationSetAttribute *editOp = [[COStoreItemDiffOperationSetAttribute alloc] 
																  initWithUUID: uuid
																  attribute: commonAttr
																  type: typeB
																  value: valueB];
				[edits addObject: editOp];
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
	[desc appendFormat: @" {\n"];
	for (COStoreItemDiffOperation *edit in edits)
	{
		[desc appendFormat: @"\t%@:%@ %@\n", [edit UUID], [edit attribute], NSStringFromClass([edit class])];
	}
 	[desc appendFormat: @"}"];
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
	
	for (COStoreItemDiffOperation *edit in edits)
	{
		COMutableItem *item = [newItems objectForKey: [edit UUID]];
		
		if (item == nil)
		{
			item = [[COMutableItem alloc] initWithUUID: [edit UUID]]; // FIXME: hack for inserted items
			[newItems setObject: item forKey: [edit UUID]];
			[item release];
		}
		
		[edit applyTo: item];
	}
	
	return [COSubtree subtreeWithItemSet: [NSSet setWithArray: [newItems allValues]]
								rootUUID: newRoot];
}

- (void) mergeWith: (COSubtreeDiff *)other
{

	/*
	NSSet *allUUIDs = [[NSSet setWithArray: [diff1->_editsByPropertyAndUUID allKeys]]
					   setByAddingObjectsFromArray: [diff2->_editsByPropertyAndUUID allKeys]];
	
	
	for (ETUUID *uuid in allUUIDs)
	{
		NSDictionary *propDict1 = [diff1->_editsByPropertyAndUUID objectForKey: uuid];
		NSDictionary *propDict2 = [diff2->_editsByPropertyAndUUID objectForKey: uuid];
		NSSet *allProperties = [[NSSet setWithArray: [propDict1 allKeys]]
								setByAddingObjectsFromArray: [propDict2 allKeys]];
		
		for (NSString *prop in allProperties)
		{
			COObjectGraphEdit *edit1 = [propDict1 objectForKey: prop]; // possibly nil
			COObjectGraphEdit *edit2 = [propDict2 objectForKey: prop]; // possibly nil
			
			// FIXME: modularize this
			
			if (edit1 != nil && edit2 != nil) 
			{
				if ([edit1 isKindOfClass: [COObjectGraphRemoveProperty class]] && [edit2 isKindOfClass: [COObjectGraphRemoveProperty class]])
				{
					//NSLog(@"Both are remove %@ (no conflict)", prop);
					[result record: edit1];
				}
				else if ([edit1 isKindOfClass: [COObjectGraphSetProperty class]] && [edit2 isKindOfClass: [COObjectGraphSetProperty class]]
						 && [[(COObjectGraphSetProperty*)edit1 newlySetValue] isEqual: [(COObjectGraphSetProperty*)edit2 newlySetValue]])
				{
					//NSLog(@"Both are set %@ to %@ (no conflict)", prop, [(COObjectGraphSetProperty*)edit1 newValue]);
					[result record: edit1];
				}
				else if ([edit1 isKindOfClass: [COObjectGraphModifyArray class]] && [edit2 isKindOfClass: [COObjectGraphModifyArray class]])
				{
					//NSLog(@"Both are modifying array %@.. trying array merge", prop);
					COMergeResult *merge = [[(COObjectGraphModifyArray*)edit1 diff] mergeWith: [(COObjectGraphModifyArray*)edit2 diff]];
					
					[result recordModifyArray: [[[COArrayDiff alloc] initWithOperations: [merge nonconflictingOps]] autorelease] forProperty: prop ofObjectUUID: uuid];
				}
				else if ([edit1 isKindOfClass: [COObjectGraphModifySet class]] && [edit2 isKindOfClass: [COObjectGraphModifySet class]])
				{
					//NSLog(@"Both are modifying set %@.. trying set merge", prop);
					COMergeResult *merge = [[(COObjectGraphModifySet*)edit1 diff] mergeWith: [(COObjectGraphModifySet*)edit2 diff]];
					
					[result recordModifySet: [[[COSetDiff alloc] initWithOperations: [merge nonconflictingOps]] autorelease] forProperty: prop ofObjectUUID: uuid];
				}
				else
				{
					// FIXME: handle modifying arrays
					//NSLog(@"Conflict: {\n\t%@\n\t%@\n}", edit1, edit2);
					//NSLog(@"WARNING: accepting left-hand-side..");
					[result record: edit1]; // FIXME: decide on output format...
				}
			}
			else if (edit1 != nil)
			{
				//NSLog(@"Accept/reject: {\n\t%@\n\t%@\n}", edit1, edit2);      
				[result record: edit1];
			}
			else if (edit2 != nil)
			{
				//NSLog(@"Reject/accept: {\n\t%@\n\t%@\n}", edit1, edit2);      
				[result record: edit2];
			}
			else assert(0);
		}
	}
	
	return result;
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
	return NO;
}

@end



#pragma mark item diffs 



@implementation COStoreItemDiffOperation

- (id) initWithUUID: (ETUUID*)aUUID attribute: (NSString*)anAttribute type: (COType*)aType
{
	NILARG_EXCEPTION_TEST(aUUID);
	NILARG_EXCEPTION_TEST(anAttribute);
	NILARG_EXCEPTION_TEST(aType);
	SUPERINIT;
	ASSIGN(attribute, anAttribute);
	ASSIGN(type, aType);
	ASSIGN(uuid, aUUID);
	return self;
}

- (id) copyWithZone: (NSZone *)aZone
{
	return [[[self class] alloc] initWithUUID: uuid attribute: attribute type:type];
}

- (void)dealloc
{
	[uuid release];
	[attribute release];
	[type release];
	[super dealloc];
}
- (NSString *) attribute
{
	return attribute;
}
- (ETUUID *) UUID
{
	return uuid;
}

@end

@implementation COStoreItemDiffOperationSetAttribute

- (id) initWithUUID: (ETUUID*)aUUID
		  attribute: (NSString*)anAttribute
			   type: (COType*)aType
			  value: (id)aValue
{
	if (nil == (self = [super initWithUUID: aUUID attribute: anAttribute type: aType]))
		return nil;
	
	ASSIGN(value, aValue);
	return self;
}

- (id) copyWithZone: (NSZone *)aZone
{
	COStoreItemDiffOperationSetAttribute *result = [[[self class] alloc] initWithUUID: uuid attribute: attribute type:type];
	result->value = [value copyWithZone: aZone];
	return result;
}

- (void)dealloc
{
	[value release];
	[super dealloc];
}

- (void) applyTo: (COMutableItem *)anItem
{
	[anItem setValue: value
		forAttribute: attribute
				type: type];
}

@end

@implementation COStoreItemDiffOperationDeleteAttribute

- (void) applyTo: (COMutableItem *)anItem
{
	if (nil == [anItem valueForAttribute: attribute])
	{
		[NSException raise: NSInternalInconsistencyException
					format: @"expeted attribute %@ to be already set", attribute];
	}
	[anItem removeValueForAttribute: attribute];
}

@end


@implementation COStoreItemDiffOperationModifyArray

- (id) initWithUUID: (ETUUID*)aUUID attribute: (NSString*)anAttribute type: (COType*)aType arrayDiff: (COArrayDiff *)aDiff
{
	if (nil == (self = [super initWithUUID: aUUID attribute: anAttribute type: aType]))
		return nil;
	
	ASSIGN(arrayDiff, aDiff);
	return self;
}

- (id) copyWithZone: (NSZone *)aZone
{
	COStoreItemDiffOperationModifyArray *result = [[[self class] alloc] initWithUUID: uuid attribute: attribute type:type];
	result->arrayDiff = [arrayDiff retain]; // FIXME!!!
	return result;
}

- (void)dealloc
{
	[arrayDiff release];
	[super dealloc];
}

- (void) applyTo: (COMutableItem *)anItem
{
	NSArray *oldValue = [anItem valueForAttribute: attribute];
	NSArray *newValue = [arrayDiff arrayWithDiffAppliedTo: oldValue];
	[anItem setValue: newValue
		forAttribute: attribute
				type: type];
}

@end


@implementation COStoreItemDiffOperationModifySet

- (id) initWithUUID: (ETUUID*)aUUID attribute: (NSString*)anAttribute type: (COType*)aType setDiff: (COSetDiff *)aDiff
{
	if (nil == (self = [super initWithUUID: aUUID attribute: anAttribute type: aType]))
		return nil;
	
	ASSIGN(setDiff, aDiff);
	return self;
}

- (id) copyWithZone: (NSZone *)aZone
{
	COStoreItemDiffOperationModifySet *result = [[[self class] alloc] initWithUUID: uuid attribute: attribute type:type];
	result->setDiff = [setDiff retain]; // FIXME!!!
	return result;
}

- (void)dealloc
{
	[setDiff release];
	[super dealloc];
}

- (void) applyTo: (COMutableItem *)anItem
{
	NSSet *oldValue = [anItem valueForAttribute: attribute];
	NSSet *newValue = [setDiff setWithDiffAppliedTo: oldValue];
	[anItem setValue: newValue
		forAttribute: attribute
				type: type];
}

@end

