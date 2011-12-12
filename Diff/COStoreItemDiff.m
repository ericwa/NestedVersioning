#import "COStoreItemDiff.h"
#import "COMacros.h"

// operation classes

@interface COStoreItemDiffOperation : NSObject
{
	NSString *attribute;
	COType *type;
}
- (id) initWithAttribute: (NSString*)anAttribute type: (COType*)aType;
- (void) applyTo: (COStoreItem *)anItem;

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



@interface COStoreItemDiffOperationModifyAttribute : COStoreItemDiffOperation
{
}

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

- (void) applyTo: (COStoreItem *)anItem
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

- (void) applyTo: (COStoreItem *)anItem
{
	[anItem setValue: value
		forAttribute: attribute
				type: type];
}

@end



@implementation COStoreItemDiffOperationDeleteAttribute

- (void) applyTo: (COStoreItem *)anItem
{
	[anItem removeValueForAttribute: attribute];
}

@end



@implementation COStoreItemDiffOperationModifyAttribute

@end


// Main implementation

@implementation COStoreItemDiff

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

+ (COStoreItemDiff *)diffItem: (COStoreItem *)itemA
					 withItem: (COStoreItem *)itemB
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
		
		if (![typeB isEqual: typeA] || ![valueB isEqual: valueA])
		{
			COStoreItemDiffOperationInsertAttribute *editOp = [[COStoreItemDiffOperationInsertAttribute alloc] 
																 initWithAttribute: commonAttr
																 type: [itemB typeForAttribute: commonAttr]
																 value: [itemB valueForAttribute:commonAttr]];
			[edits addObject:editOp];
			[editOp release];
		}
	}
	
	return [[[self alloc] initWithEdits: edits] autorelease];
}

- (COStoreItem *)itemWithDiffAppliedTo: (COStoreItem *)anItem
{
	COStoreItem *newItem = [[anItem copy] autorelease];
	for (COStoreItemDiffOperation *op in edits)
	{
		[op applyTo: newItem];
	}
	return newItem;
}

@end
