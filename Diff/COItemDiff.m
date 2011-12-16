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
	// FIXME: Fail if the attribute already has a value
	[anItem setValue: value
		forAttribute: attribute
				type: type];
}

@end

@implementation COStoreItemDiffOperationReplaceAttribute

- (void) applyTo: (COMutableItem *)anItem
{
	// FIXME: Fail of the attribute does _not_ already have a value
	[anItem setValue: value
		forAttribute: attribute
				type: type];
}

@end

@implementation COStoreItemDiffOperationDeleteAttribute

- (void) applyTo: (COMutableItem *)anItem
{
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

- (COItem *)itemWithDiffAppliedTo: (COItem *)anItem
{
	COMutableItem *newItem = [[anItem mutableCopy] autorelease];
	for (COStoreItemDiffOperation *op in edits)
	{
		[op applyTo: newItem];
	}
	return newItem;
}

@end
