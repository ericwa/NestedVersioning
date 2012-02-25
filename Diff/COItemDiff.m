#import "COItemDiff.h"
#import "COMacros.h"
#import "COType+Diff.h"

// operation classes

@interface COStoreItemDiffOperation : NSObject
{
	NSString *attribute;
	COType *type;
}
- (id) initWithAttribute: (NSString*)anAttribute type: (COType*)aType;
- (void) applyTo: (COMutableItem *)anItem;

@end

@interface COStoreItemDiffOperationSetUUID : COStoreItemDiffOperation
{
	ETUUID *uuid;
}
- (id) initWithUUID: (ETUUID*)aUUID;
@end

@interface COStoreItemDiffOperationInsertAttribute : COStoreItemDiffOperation 
{
	id value;
}
- (id) initWithAttribute: (NSString*)anAttribute
					type: (COType*)aType
				   value: (id)aValue;

@end



@interface COStoreItemDiffOperationDeleteAttribute : COStoreItemDiffOperation
@end

/**
 * Type changes
 */
@interface COStoreItemDiffOperationReplaceAttribute : COStoreItemDiffOperationInsertAttribute
@end

/**
 * Type stays the same
 */
@interface COStoreItemDiffOperationModifyAttribute : COStoreItemDiffOperation
{
	id <COValueDiff> valueDiff;
}

- (id) initWithAttribute: (NSString*)anAttribute
					type: (COType*)aType
				oldValue: (id)valueA
				newValue: (id)valueB;

@end

// operation implementations

@implementation COStoreItemDiffOperation
- (id) initWithAttribute: (NSString*)anAttribute type: (COType*)aType
{
	NILARG_EXCEPTION_TEST(anAttribute);
	NILARG_EXCEPTION_TEST(aType);
	SUPERINIT;
	ASSIGN(attribute, anAttribute);
	ASSIGN(type, aType);
	return self;
}

- (void)dealloc
{
	[attribute release];
	[type release];
	[super dealloc];
}

@end

@implementation COStoreItemDiffOperationSetUUID

- (id) initWithUUID: (ETUUID*)aUUID
{
	NILARG_EXCEPTION_TEST(aUUID);
	SUPERINIT;
	ASSIGN(uuid, aUUID);
	return self;
}

- (void)dealloc
{
	[uuid release];
	[super dealloc];
}

- (void) applyTo: (COMutableItem *)anItem
{
	[anItem setUUID: uuid];
}

@end

@implementation COStoreItemDiffOperationInsertAttribute

- (id) initWithAttribute: (NSString*)anAttribute
					type: (COType*)aType
				   value: (id)aValue
{
	if (nil == (self = [super initWithAttribute: anAttribute type: aType]))
		return nil;
	
	ASSIGN(value, aValue);
	return self;
}

- (void)dealloc
{
	[value release];
	[super dealloc];
}

- (void) applyTo: (COMutableItem *)anItem
{
	if (nil != [anItem valueForAttribute: attribute])
	{
		[NSException raise: NSInternalInconsistencyException
					format: @"expeted attribute %@ to be unset", attribute];
	}
	[anItem setValue: value
		forAttribute: attribute
				type: type];
}

@end

@implementation COStoreItemDiffOperationReplaceAttribute

- (void) applyTo: (COMutableItem *)anItem
{
	if (nil == [anItem valueForAttribute: attribute])
	{
		[NSException raise: NSInternalInconsistencyException
					format: @"expeted attribute %@ to be already set", attribute];
	}
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



@implementation COStoreItemDiffOperationModifyAttribute

- (id) initWithAttribute: (NSString*)anAttribute
					type: (COType*)aType
				oldValue: (id)valueA
				newValue: (id)valueB
{
	if (nil == (self = [super initWithAttribute: anAttribute type: aType]))
		return nil;
	
	ASSIGN(valueDiff, [aType diffValue: valueA withValue: valueB]);
	
	return self;
}

- (void)dealloc
{
	[valueDiff release];
	[super dealloc];
}

- (void) applyTo: (COMutableItem *)anItem
{
	id oldValue = [anItem valueForAttribute: attribute];
	id newValue = [valueDiff valueWithDiffAppliedToValue: oldValue];
	[anItem setValue: newValue
		forAttribute: attribute
				type: type];
}

@end


// Main implementation

@implementation COItemDiff

- (id)initWithEdits: (NSSet*)aSet
{
	SUPERINIT;
	ASSIGN(edits, aSet);
	return self;
}

- (void) dealloc
{
	[edits release];
	[super dealloc];
}

+ (COItemDiff *)diffItem: (COItem *)itemA
				withItem: (COItem *)itemB
{
	NILARG_EXCEPTION_TEST(itemA);
	NILARG_EXCEPTION_TEST(itemB);
	
	NSMutableSet *edits = [NSMutableSet set];	
	
	if (![[itemA UUID] isEqual: [itemB UUID]])
	{
		NSLog(@"Warning, diffing items with different UUIDs (%@, %@)",
				[itemA UUID], [itemB UUID]);
		
		COStoreItemDiffOperationSetUUID *setUUIDOp = [[COStoreItemDiffOperationSetUUID alloc] initWithUUID: [itemB UUID]];
		[edits addObject: setUUIDOp];
		[setUUIDOp release];
	}
	
	NSMutableSet *removedAttrs = [NSMutableSet setWithArray: [itemA attributeNames]];
	[removedAttrs minusSet: [NSSet setWithArray: [itemB attributeNames]]];
	
	NSMutableSet *addedAttrs = [NSMutableSet setWithArray: [itemB attributeNames]];
	[addedAttrs minusSet: [NSSet setWithArray: [itemA attributeNames]]];
	
	NSMutableSet *commonAttrs = [NSMutableSet setWithArray: [itemB attributeNames]];
	[commonAttrs intersectSet: [NSSet setWithArray: [itemA attributeNames]]];
	
	
	// process 'insert attribute's

	for (NSString *addedAttr in addedAttrs)
	{
		COStoreItemDiffOperationInsertAttribute *insertOp = [[COStoreItemDiffOperationInsertAttribute alloc] 
															 initWithAttribute: addedAttr
																		type: [itemB typeForAttribute: addedAttr]
																		value: [itemB valueForAttribute:addedAttr]];
		[edits addObject: insertOp];
		[insertOp release];
	}
	
	// process deletes
	
	for (NSString *removedAttr in removedAttrs)
	{
		COStoreItemDiffOperationDeleteAttribute *deleteOp = [[COStoreItemDiffOperationDeleteAttribute alloc] 
															 initWithAttribute: removedAttr
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
		
		if (![typeB isEqual: typeA])
		{
			COStoreItemDiffOperationReplaceAttribute *editOp = [[COStoreItemDiffOperationReplaceAttribute alloc]
																initWithAttribute: commonAttr
																type: [itemB typeForAttribute: commonAttr]
																value: [itemB valueForAttribute:commonAttr]];
			[edits addObject:editOp];
			[editOp release];
		}
		else if (![valueB isEqual: valueA])
		{
			COStoreItemDiffOperationModifyAttribute *editOp = [[COStoreItemDiffOperationModifyAttribute alloc]
															   initWithAttribute: commonAttr
																			type: [itemB typeForAttribute: commonAttr]
																		oldValue: [itemA valueForAttribute:commonAttr]
																		newValue: [itemB valueForAttribute:commonAttr]];
			[edits addObject:editOp];
			[editOp release];
		}
	}
	
	return [[[self alloc] initWithEdits: edits] autorelease];
}

- (void) applyTo: (COMutableItem*)aMutableItem
{
	for (COStoreItemDiffOperation *op in edits)
	{
		[op applyTo: aMutableItem];
	}
}

- (COItem *)itemWithDiffAppliedTo: (COItem *)anItem
{
	COMutableItem *newItem = [[anItem mutableCopy] autorelease];
	[self applyTo: newItem];
	return newItem;
}

- (NSUInteger) editCount
{
	return [edits count];
}

- (COItemDiff *)itemDiffByMergingWithDiff: (COItemDiff *)other
{
	return nil;
	
#if 0
	COObjectGraphDiff *result = [[[COObjectGraphDiff alloc] init] autorelease];
	//NSLog(@"Merging %@ and %@...", diff1, diff2);
	
	NILARG_EXCEPTION_TEST(diff1);
	NILARG_EXCEPTION_TEST(diff2);
	
	// Merge inserts and deletes
	
	NSSet *diff1Inserts = [NSSet setWithArray: [diff1->_insertedObjectsByUUID allKeys]];
	NSSet *diff2Inserts = [NSSet setWithArray: [diff2->_insertedObjectsByUUID allKeys]];	
	
	NSMutableSet *insertConflicts = [NSMutableSet setWithSet: diff1Inserts];
	[insertConflicts intersectSet: diff2Inserts];
	for (ETUUID *aUUID in insertConflicts)
	{
		// Warn about conflicts
		if ([[diff1->_insertedObjectsByUUID objectForKey: aUUID] editingContext] != 
			[[diff2->_insertedObjectsByUUID objectForKey: aUUID] editingContext])
		{
			//NSLog(@"ERROR: Insert/Insert conflict with UUID %@. LHS wins.", aUUID);
		}
	}
	
	NSMutableDictionary *allInserts = [NSMutableDictionary dictionary];
	[allInserts addEntriesFromDictionary: diff2->_insertedObjectsByUUID];
	[allInserts addEntriesFromDictionary: diff1->_insertedObjectsByUUID]; // If there are duplicate keys diff1 wins
	[result->_insertedObjectsByUUID setDictionary: allInserts];
	
	NSSet *allDeletedUUIDs = [diff1->_deletedObjectUUIDs setByAddingObjectsFromSet: diff2->_deletedObjectUUIDs];
	[result->_deletedObjectUUIDs setSet: allDeletedUUIDs];
	
	
	// Merge edits
	
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
#endif
}

- (BOOL) hasConflicts
{
	// FIXME: The only way we have conflicts is if 
	// a) one of the array diffs has conflicts
	// or
	// b) across all ways of resolving conflicts in array diffs,
	//    there is an embedded item inserted in two places.
	return NO;
}

@end
