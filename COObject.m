#import "COObject.h"
#import "COType.h"
#import "COItem.h"
#import "COItemTree.h"
#import "COEditingContext.h"
#import "COEditingContextPrivate.h"
#import "COItemPath.h"
#import "COMacros.h"
#import "COSchemaRegistry.h"
#import "COSchema.h"

NSString *kCOSchemaName = @"COSchemaName";

@implementation COObject (Private)

- (id) initWithItem: (COItem *)anItem
      parentContext: (COEditingContext *)aContext
{
    SUPERINIT;
    [self updateItem: anItem
       parentContext: aContext];
    return self;
}

- (void) updateItem: (COItem *)anItem parentContext: (COEditingContext *)aContext
{
    item_ = [anItem mutableCopy];
    parentContext_ = aContext;
}

- (void) markAsRemovedFromContext
{
    parentContext_ = nil;
    // FIXME: Add checks in various places that throw an exception if a user
    // tries to do anything with a COObject with a nil editingContext
}

@end

@implementation COObject

- (void) dealloc
{
    parentContext_ = nil;
    DESTROY(item_);
    [super dealloc];
}

#pragma mark Access to the receivers attributes/values


- (COEditingContext *) editingContext
{
    return parentContext_;
}

- (COItem *) item
{
	return [[item_ copy] autorelease];
}

- (COUUID *) UUID
{
	return [item_ UUID];
}

- (NSSet *) attributeNames
{
	return [item_ attributeNames];
}

- (COType *) typeForAttribute: (NSString *)anAttribute
{
    COType *schemaType = [[[parentContext_ schemaRegistry] schemaForName: [self schemaName]]
                        typeForProperty: anAttribute];
    
    if (schemaType != nil)
    {
        return schemaType;
    }
    
	return [item_ typeForAttribute: anAttribute];
}
- (id) valueForAttribute: (NSString*)anAttribute
{
	id rootValue = [item_ valueForAttribute: anAttribute];
	COType *type = [self typeForAttribute: anAttribute];
	
	if ([type isPrimitiveTypeEqual: [COType embeddedItemType]])
	{
		return [self convertCOUUIDValueToCOObject: rootValue];
	}
    else if ([type isPrimitiveTypeEqual: [COType referenceType]])
    {
        return [self convertCOUUIDValueToCOObject: rootValue];
    }
	else
	{
		return rootValue;
	}
}

- (NSString *) schemaName
{
    // NOTE: -valueForAttribute: calls -typeForAttribute:, which calls -schemaName,
    //       so we can't call -valueForAttribute:. Access item_ directly, instead.
    return [item_ valueForAttribute: kCOSchemaName];
}

#pragma mark Access to the tree stucture

- (COObject *) embeddedObjectParent
{
    return [parentContext_ embeddedObjectParent: self];
}

- (BOOL) containsObject: (COObject *)anObject
{
	for (; anObject != nil; anObject = [anObject embeddedObjectParent])
	{
		if (anObject == self)
		{
			return YES;
		}
	}
	return NO;
}

- (NSSet *) allObjectUUIDs
{
	return [[self allDescendentObjectUUIDs] setByAddingObject: [self UUID]];
}

- (NSSet *) allStoreItems
{
	NSMutableSet *result = [NSMutableSet set];
	
	[result addObject: [[item_ copy] autorelease]];
	
	for (COObject *node in [self directDescendentObjects])
	{
		[result unionSet: [node allStoreItems]];
	}
	
	return result;
}

- (NSSet *) allDescendentObjectUUIDs
{
	NSMutableSet *result = [NSMutableSet set];
	
	for (COObject *node in [self directDescendentObjects])
	{
		[result addObject: [node UUID]];
		[result unionSet: [node allDescendentObjectUUIDs]];
	}
	
	return result;
}

- (NSSet *) directDescendentObjectUUIDs
{
	return [item_ embeddedItemUUIDs];
}

- (NSSet *) directDescendentObjects
{
    NSSet *uuids = [item_ embeddedItemUUIDs];
	NSMutableSet *result = [NSMutableSet setWithCapacity: [uuids count]];
    for (COUUID *uuid in uuids)
    {
        [result addObject: [parentContext_ objectForUUID: uuid]];
    }
    return result;
}

/**
 * Searches the receiver for the Object with the givent UUID.
 * Returns nil if not present
 */
- (COObject *) descendentObjectForUUID: (COUUID *)aUUID
{
	COObject *object = [parentContext_ objectForUUID: aUUID];
    if ([self containsObject: object])
    {
        return object;
    }
	else
    {
        return nil;
    }
}

- (COItemPath *) itemPathOfDescendentObjectWithUUID: (COUUID *)aUUID
{
	COObject *destObject = [self descendentObjectForUUID: aUUID];
	
	if (destObject == nil)
	{
		return nil;
	}
	
	COObject *destObjectParent = [destObject embeddedObjectParent];
	
	// Search destObjectParent's attributes for [destObject UUID];
	// FIXME: Factor out?
	
	for (NSString *attr in [destObjectParent attributeNames])
	{
		if ([[destObjectParent->item_ allObjectsForAttribute: attr] containsObject: [destObject UUID]])
		{
			COType *type = [destObjectParent typeForAttribute: attr];
			if ([type isMultivalued])
			{
				if ([type isOrdered])
				{
					NSUInteger index = [[destObjectParent->item_ allObjectsForAttribute: attr] indexOfObject: [destObject UUID]];
					
					return [COItemPath pathWithItemUUID: [destObjectParent UUID]
											  arrayName: attr
										 insertionIndex: index
												   type: type];
				}
				else
				{
					return [COItemPath pathWithItemUUID: [destObjectParent UUID]
								unorderedCollectionName: attr
												   type: type];
				}
			}
			else
			{
				return [COItemPath pathWithItemUUID: [destObjectParent UUID]
										  valueName: attr
											   type: type];
			}
		}
	}
	
	[NSException raise: NSInternalInconsistencyException
				format: @"COObject inconsistent"];
	return nil;
}

- (COItemTree *) itemTree
{
    NSMutableDictionary *objects = [NSMutableDictionary dictionary];
    for (COItem *i in [self allStoreItems])
    {
        [objects setObject: i forKey: [i UUID]];
    }
    
    return [[[COItemTree alloc] initWithItemForUUID: objects rootItemUUID: [self UUID]] autorelease];
}

#pragma mark Mutation

- (id) convertCOObjectValueToCOUUID: (id)aValue
{
    if ([aValue isKindOfClass: [COObject class]])
    {
        return [aValue UUID];
    }
    else if ([aValue isKindOfClass: [NSCountedSet class]])
    {
        NSCountedSet *replacement = [NSCountedSet set];
        for (COObject *object in aValue)
        {
            [replacement addObject: [object UUID]];
        }
        return replacement;
    }
    else if ([aValue isKindOfClass: [NSSet class]])
    {
        NSMutableSet *replacement = [NSMutableSet set];
        for (COObject *object in aValue)
        {
            [replacement addObject: [object UUID]];
        }
        return [NSSet setWithSet: replacement];
    }
    else if ([aValue isKindOfClass: [NSArray class]])
    {
        NSMutableArray *replacement = [NSMutableArray array];
        for (COObject *object in aValue)
        {
            [replacement addObject: [object UUID]];
        }
        return [NSArray arrayWithArray: replacement];
    }
    NSParameterAssert(NO);
    return nil;
}

- (id) convertCOUUIDValueToCOObject: (id)aValue
{
    if ([aValue isKindOfClass: [COUUID class]])
    {
        return [parentContext_ objectForUUID: aValue];
    }
    else if ([aValue isKindOfClass: [NSCountedSet class]])
    {
        NSCountedSet *replacement = [NSCountedSet set];
        for (COObject *object in aValue)
        {
            [replacement addObject: [parentContext_ objectForUUID: aValue]];
        }
        return replacement;
    }
    else if ([aValue isKindOfClass: [NSSet class]])
    {
        NSMutableSet *replacement = [NSMutableSet set];
        for (COObject *object in aValue)
        {
            [replacement addObject: [parentContext_ objectForUUID: aValue]];
        }
        return [NSSet setWithSet: replacement];
    }
    else if ([aValue isKindOfClass: [NSArray class]])
    {
        NSMutableArray *replacement = [NSMutableArray array];
        for (COObject *object in aValue)
        {
            [replacement addObject: [parentContext_ objectForUUID: aValue]];
        }
        return [NSArray arrayWithArray: replacement];
    }
    NSParameterAssert(NO);
    return nil;
}

- (void) setValue: (id)aValue
	 forAttribute: (NSString*)anAttribute
{
    [self setValue: aValue forAttribute: anAttribute type: [self typeForAttribute: anAttribute]];
}

- (void) setValue: (id)aValue
	 forAttribute: (NSString*)anAttribute
			 type: (COType *)aType
{
    NSParameterAssert(aType != nil);
    
	if ([aType isPrimitiveTypeEqual: [COType embeddedItemType]])
	{
		if (![aType isMultivalued])
		{
			[self addObject:  aValue atItemPath: [COItemPath pathWithItemUUID: [self UUID]
                                                                              valueName: anAttribute
                                                                                   type: aType]];
		}
		else
		{
			[self removeValueForAttribute: anAttribute];
			
			if ([aType isOrdered])
			{
				NSArray *array = (NSArray *)aValue;
				const NSUInteger count = [array count];
				for (NSUInteger i=0; i<count; i++)
				{
					COObject *anObject = [array objectAtIndex: i];
					
					[self addObject:  anObject
                                    atItemPath: [COItemPath pathWithItemUUID: [self UUID]
                                                                   arrayName: anAttribute
                                                              insertionIndex: i
                                                                        type: aType]];
				}
			}
			else
			{
				for (COObject *anObject in aValue)
				{
					[self addObject:  anObject
                                    atItemPath: [COItemPath pathWithItemUUID: [self UUID]
                                                     unorderedCollectionName: anAttribute
                                                                        type: aType]];
				}
			}
		}
	}
	else if ([aType isPrimitiveTypeEqual: [COType referenceType]])
	{
		[item_ setValue: [self convertCOObjectValueToCOUUID: aValue]
           forAttribute: anAttribute
                   type: aType];
        
        [parentContext_ recordModifiedObjectUUID: [self UUID]];
	}
	else
	{
		[item_ setValue: aValue
		  forAttribute: anAttribute
				  type: aType];
        
        [parentContext_ recordModifiedObjectUUID: [self UUID]];
	}
}



- (void)   addObject: (id)aValue
toUnorderedAttribute: (NSString*)anAttribute
{
    COType *aType = [self typeForAttribute: anAttribute];
    NSParameterAssert(aType != nil);
    
	if ([aType isPrimitiveTypeEqual: [COType embeddedItemType]])
	{
		[self addObject:  aValue atItemPath: [COItemPath pathWithItemUUID: [self UUID]
												  unorderedCollectionName: anAttribute
																	 type: aType]];
	}
    else if ([aType isPrimitiveTypeEqual: [COType referenceType]])
    {
		[item_ addObject: [aValue UUID]
    toUnorderedAttribute: anAttribute
                    type: aType];
        
        [parentContext_ recordModifiedObjectUUID: [self UUID]];
    }
	else
	{
		[item_ addObject: aValue
   toUnorderedAttribute: anAttribute
				   type: aType];
        
        [parentContext_ recordModifiedObjectUUID: [self UUID]];
	}
	
}

- (void)   addObject: (id)aValue
  toOrderedAttribute: (NSString*)anAttribute
			 atIndex: (NSUInteger)anIndex
{
    COType *aType = [self typeForAttribute: anAttribute];
    NSParameterAssert(aType != nil);

	if ([aType isPrimitiveTypeEqual: [COType embeddedItemType]])
	{
		[self addObject:  aValue atItemPath: [COItemPath pathWithItemUUID: [self UUID]
																arrayName: anAttribute
														   insertionIndex: anIndex
																	 type: aType]];
	}
    else if ([aType isPrimitiveTypeEqual: [COType referenceType]])
    {
		[item_ addObject: [aValue UUID]
      toOrderedAttribute: anAttribute
                 atIndex: anIndex
                    type: aType];
        
        [parentContext_ recordModifiedObjectUUID: [self UUID]];
    }
	else
	{
		[item_ addObject: aValue
	 toOrderedAttribute: anAttribute
				atIndex: anIndex
				   type: aType];
        
        [parentContext_ recordModifiedObjectUUID: [self UUID]];
	}
}

- (void)   addObject: (id)aValue
  toOrderedAttribute: (NSString*)anAttribute
{
    COType *aType = [self typeForAttribute: anAttribute];
    NSParameterAssert([aType isOrdered]);

	NSUInteger anIndex = [[item_ valueForAttribute: anAttribute] count];
    
	[self addObject: aValue
 toOrderedAttribute: anAttribute
			atIndex: anIndex];
}

- (void) removeValueForAttribute: (NSString*)anAttribute
{
	if ([[item_ typeForAttribute: anAttribute] isPrimitiveTypeEqual: [COType embeddedItemType]])
	{
		for (COUUID *uuidToRemove in [item_ allObjectsForAttribute: anAttribute])
		{
            [parentContext_ removeUnreachableObjectAndChildren: uuidToRemove];
		}
	}
    
	[item_ removeValueForAttribute: anAttribute];
}

/**
 * Removes a Object (regardless of where in the receiver or the receiver's children
 * it is located.) Throws an exception if the guven UUID is not present in the receiver.
 */
- (void) removeDescendentObjectWithUUID: (COUUID *)aUUID
{
	[self removeDescendentObject: [self descendentObjectForUUID: aUUID]];
}

- (void) removeDescendentObject: (COObject *)anObject
{
	if (anObject == self)
	{
		[NSException raise: NSInvalidArgumentException
					format: @"-removeObjectWithUUID: can not remove the receiver"];
	}
	if (![self containsObject: anObject])
	{
		[NSException raise: NSInvalidArgumentException
					format: @"argument must be inside the reciever to remove it"];
	}
	
	COUUID *aUUID = [anObject UUID];
	COObject *parentOfObjectToRemove = [anObject embeddedObjectParent];
	COItemPath *itemPath = [self itemPathOfDescendentObjectWithUUID: aUUID];
	NSAssert([[itemPath UUID] isEqual: [parentOfObjectToRemove UUID]], @"");
	[itemPath removeValue: aUUID inStoreItem: parentOfObjectToRemove->item_];

    [parentContext_ removeUnreachableObjectAndChildren: aUUID];
}

#pragma mark Mutation Internal

- (COObject *) addItemTree: (COItemTree *)aTree
                atItemPath: (COItemPath *)aPath
{
    // see if there are any name conflicts
    
    NSMutableSet *conflictingNames = [NSMutableSet setWithSet: [parentContext_ allObjectUUIDs]];
    [conflictingNames intersectSet: [NSSet setWithArray: [aTree itemUUIDs]]];
    
    if ([conflictingNames count] > 0)
    {
        NSLog(@"names %@ need to be remapped", conflictingNames);
     
        NSMutableDictionary *mapping = [NSMutableDictionary dictionary];
        for (COUUID *name in conflictingNames)
        {
            [mapping setObject: [COUUID UUID]
                        forKey: name];
        }
        
        aTree = [aTree itemTreeWithNameMapping: mapping];
    }
    
    // now, there are no name conflicts.
    
    COObject *result = [parentContext_ updateObject: [aTree rootItemUUID]
                                     fromItemTree: aTree
                                          setParent: self];
    [aPath insertValue: [aTree rootItemUUID] inStoreItem: self->item_];
    
    // record dirty objects

    [parentContext_ recordModifiedObjectUUID: [self UUID]];
    for (COUUID *uuid in [aTree itemUUIDs])
    {
        [parentContext_ recordInsertedObjectUUID: uuid];
    }
    
    return result;
}

- (void) addObjectSameContext: (COObject *)aObject
                   atItemPath: (COItemPath *)aPath
{
    if (aObject == self)
    {
        [NSException raise: NSInvalidArgumentException format: @"can't add an object to itself"];
    }
    if ([aObject containsObject: self])
    {
        [NSException raise: NSInvalidArgumentException format: @"can't add an object to a child of itself"];
    }
    
    // remove from parent
    
    COUUID *aUUID = [aObject UUID];
	COObject *parentOfObjectToRemove = [aObject embeddedObjectParent];
    
    if (parentOfObjectToRemove != nil)
    {
        COItemPath *itemPath = [parentOfObjectToRemove itemPathOfDescendentObjectWithUUID: aUUID];
        NSAssert([[itemPath UUID] isEqual: [parentOfObjectToRemove UUID]], @"");
        [itemPath removeValue: aUUID inStoreItem: parentOfObjectToRemove->item_];
        [parentContext_ recordModifiedObjectUUID: [parentOfObjectToRemove UUID]];
    }
    
    // add to self
    
    [aPath insertValue: aUUID inStoreItem: self->item_];
    [parentContext_ recordModifiedObjectUUID: [self UUID]];
    [parentContext_ recordAddedEmbededObject: aUUID toObject: [self UUID]];
}

- (COObject *) addObject: (COObject *)anObject
               atItemPath: (COItemPath *)aPath
{
    NSParameterAssert([[self UUID] isEqual: [aPath UUID]]);
 
    if ([anObject editingContext] == [self editingContext])
    {
        // Move
        [self addObjectSameContext: anObject
                        atItemPath: aPath];
        return anObject;
    }
    else
    {
        // Copy
        return [self addItemTree: [anObject itemTree]
                      atItemPath: aPath];
    }
}

- (void) moveDescendentObjectWithUUID: (COUUID *)aUUID
				  toItemPath: (COItemPath *)aPath
{
	COObject *objectToMove = [self descendentObjectForUUID: aUUID];
	[self addObject: objectToMove
		  atItemPath: aPath];
}



#pragma mark contents property


- (COObject *) addObjectToContents: (COObject *)aValue
{
    return 	[self addObject:  aValue
		  atItemPath: [COItemPath pathWithItemUUID: [self UUID]
						   unorderedCollectionName: @"contents"
											  type: [COType setWithPrimitiveType: [COType embeddedItemType]]]];
}

- (NSSet*) contents
{
	NSSet *contents = (NSSet*)[self valueForAttribute: @"contents"];
	if (nil == contents)
	{
		return [NSSet set];
	}
	
	if (![contents isKindOfClass: [NSSet class]])
	{
		//[NSException raise: NSInternalInconsistencyException
		//			format: @"contents attribute not a set type"];
		NSLog(@"Warning, contents attribute of %@ not a set type: %@", [self UUID], contents);
		return [NSSet set];
	}
	return contents;
}

- (COEditingContext *) independentEditingContext
{
    return [[[COEditingContext alloc] initWithItemTree: [self itemTree]] autorelease];
}

// Logging


- (NSString *) selfDescription
{
	return [NSString stringWithFormat: @"%@ (%@)", [self valueForAttribute: @"name"], [self UUID]];
}

- (NSString *) tabs: (NSUInteger)i
{
	NSMutableString *result = [NSMutableString string];
	for (NSUInteger j=0; j<i; j++)
		[result appendFormat: @"\t"];
	return result;
}

- (NSString *) descriptionWithIndent: (NSUInteger)i
{
	NSMutableString *result = [NSMutableString string];
	[result appendFormat: @"%@%@\n", [self tabs: i], [self selfDescription]];
	
	if ([[self typeForAttribute: @"contents"] isPrimitiveTypeEqual: [COType embeddedItemType]]
		&& [[self typeForAttribute: @"contents"] isMultivalued])
	{
		for (COObject *content in [self valueForAttribute: @"contents"])
		{
			[result appendFormat: @"%@", [content descriptionWithIndent: i+1]];
		}
	}
	
	return result;
}

- (NSString *) description
{
	return [self descriptionWithIndent: 0];
}

// Equality

- (BOOL) isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }
	if (![object isKindOfClass: [self class]])
	{
		return NO;
	}
    
    COObject *otherObject = (COObject *)object;

    if (otherObject->parentContext_ == parentContext_)
    {
        // Within a context, an object can only be equal to itself.
        
        return object == self;
    }
    else
    {
        // Deep equality test between objects in two contexts

        if (![item_ isEqual: otherObject->item_])
        {
            return NO;
        }
        
        // Recursively call -isEqual on the NSSet of contained COObject instances
        return [[self directDescendentObjects] isEqual: [otherObject directDescendentObjects]];
    }
}

- (NSUInteger) hash
{
	return [[item_ UUID] hash] ^ 8748262350970910369ULL;
}

@end
