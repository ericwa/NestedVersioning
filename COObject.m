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
    item_ = [anItem mutableCopy]; // Important
    parentContext_ = aContext;
    return self;
}

/**
 * Does not automatically update relationship cache in context
 */
- (void) setItem: (COItem *)anItem
{
    if (item_ != anItem)
    {
        [item_ release];
        item_ = [anItem mutableCopy]; // Important
    }
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

- (COUUID *) UUID
{
	return [item_ UUID];
}

- (NSArray *) attributeNames
{
    COSchema *schema = [self schema];
    if (schema != nil)
    {
        // TODO: Performance
        return [[[schema propertyNames] setByAddingObjectsFromArray:
                    [item_ attributeNames]] allObjects];
    }
    else
    {
        return [item_ attributeNames];
    }
}

- (COType) typeForAttribute: (NSString *)anAttribute
{
    COType schemaType = [[self schema] typeForProperty: anAttribute];
    if (schemaType != 0)
    {
        return schemaType;
    }
    
	return [item_ typeForAttribute: anAttribute];
}

- (id) valueForAttribute: (NSString*)anAttribute
{
	id rootValue = [item_ valueForAttribute: anAttribute];
	COType type = [self typeForAttribute: anAttribute];
	
    // TODO: Perofmrance. Cache COObject version?
    return [self convertCOUUIDValueToCOObject: rootValue type_: type];
}

- (NSString *) schemaName
{
    // NOTE: -valueForAttribute: calls -typeForAttribute:, which calls -schemaName,
    //       so we can't call -valueForAttribute:. Access item_ directly, instead.
    return [item_ valueForAttribute: kCOSchemaName];
}

- (COSchema *) schema
{
    return [[parentContext_ schemaRegistry] schemaForName: [self schemaName]];
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

- (NSSet *) objectSetForUUIDs_: (NSSet *)uuids
{
	NSMutableSet *result = [NSMutableSet setWithCapacity: [uuids count]];
    for (COUUID *uuid in uuids)
    {
        [result addObject: [parentContext_ objectForUUID: uuid]];
    }
    return result;
}

- (NSSet *) directDescendentObjects
{
    NSSet *uuids = [item_ embeddedItemUUIDs];
	return [self objectSetForUUIDs_: uuids];
}

- (NSSet *) embeddedOrReferencedObjects
{
    NSSet *uuids = [[item_ referencedItemUUIDs] setByAddingObjectsFromSet: [item_ embeddedItemUUIDs]];
  	return [self objectSetForUUIDs_: uuids];
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
			COType type = [destObjectParent typeForAttribute: attr];
			if (COTypeIsMultivalued(type))
			{
				if (COTypeIsOrdered(type))
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

#pragma mark Mutation

- (id) convertCOObjectValueToCOUUID: (id)aValue
                              type_: (COType)aType
{
    if (COPrimitiveType(aType) != kCOEmbeddedItemType
        && COPrimitiveType(aType) != kCOReferenceType)
    {
        return aValue;
    }
    
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
                              type_: (COType)aType
{
    if (COPrimitiveType(aType) != kCOEmbeddedItemType
        && COPrimitiveType(aType) != kCOReferenceType)
    {
        return aValue;
    }
    
    if ([aValue isKindOfClass: [COUUID class]])
    {
        return [parentContext_ objectForUUID: aValue];
    }
    else if ([aValue isKindOfClass: [NSCountedSet class]])
    {
        NSCountedSet *replacement = [NSCountedSet set];
        for (COUUID *object in aValue)
        {
            [replacement addObject: [parentContext_ objectForUUID: object]];
        }
        return replacement;
    }
    else if ([aValue isKindOfClass: [NSSet class]])
    {
        NSMutableSet *replacement = [NSMutableSet set];
        for (COUUID *object in aValue)
        {
            [replacement addObject: [parentContext_ objectForUUID: object]];
        }
        return [NSSet setWithSet: replacement];
    }
    else if ([aValue isKindOfClass: [NSArray class]])
    {
        NSMutableArray *replacement = [NSMutableArray array];
        for (COUUID *object in aValue)
        {
            [replacement addObject: [parentContext_ objectForUUID: object]];
        }
        return [NSArray arrayWithArray: replacement];
    }
    NSParameterAssert(NO);
    return nil;
}

/**
 * Can only be used if we have a schema already set, or that attribute already had an
 * explicit type set.
 */
- (void) setValue: (id)aValue
	 forAttribute: (NSString*)anAttribute
{
    [self setValue: aValue
      forAttribute: anAttribute
              type: [self typeForAttribute: anAttribute]];
}


- (void) setValueWithCOUUID: (id)aValue
               forAttribute: (NSString*)anAttribute
                       type: (COType)aType
{
    id oldValue = [item_ valueForAttribute: anAttribute];
    COType oldType = [item_ typeForAttribute: anAttribute];
    
    // Remove objects in newValue from their old parents
    // as perscribed by the COEditingContext class docs
    
    // FIXME: Ugly implementation
    if (COPrimitiveType(aType) == kCOEmbeddedItemType)
    {
        for (COUUID *beingInserted in aValue)
        {
            COObject *objectBeingInserted = [parentContext_ objectForUUID: beingInserted];
            COObject *objectBeingInsertedParent = [objectBeingInserted embeddedObjectParent];
            
            if (objectBeingInsertedParent != nil)
            {
                COItemPath *path = [objectBeingInsertedParent itemPathOfDescendentObjectWithUUID: beingInserted];
                
                assert([[path UUID] isEqual: [objectBeingInsertedParent UUID]]);
                
                [path removeValue: beingInserted inStoreItem: objectBeingInsertedParent->item_];
            }
        }
    }
    
    
    [item_ setValue: aValue
       forAttribute: anAttribute
               type: aType];
    
    [parentContext_ updateRelationshipIntegrityWithOldValue: oldValue
                                                    oldType: oldType
                                                   newValue: aValue
                                                    newType: aType
                                                forProperty: anAttribute
                                                   ofObject: [self UUID]];
}

- (void) setValue: (id)aValue
	 forAttribute: (NSString*)anAttribute
			 type: (COType)aType
{
    [self setValueWithCOUUID: [self convertCOObjectValueToCOUUID: aValue type_: aType]
                forAttribute: anAttribute
                        type: aType];
}

// TODO: Reuse or scrap...

//- (void)   addObject: (id)aValue
//toUnorderedAttribute: (NSString*)anAttribute
//{
//    COType aType = [self typeForAttribute: anAttribute];
//    NSParameterAssert(aType != 0);
//    
//	if (COPrimitiveType(aType) == kCOEmbeddedItemType)
//	{
//		[self addObject:  aValue atItemPath: [COItemPath pathWithItemUUID: [self UUID]
//												  unorderedCollectionName: anAttribute
//																	 type: aType]];
//	}
//    else if (COPrimitiveType(aType) == kCOReferenceType)
//    {
//		[item_ addObject: [aValue UUID]
//    toUnorderedAttribute: anAttribute
//                    type: aType];
//        
//        [parentContext_ recordModifiedObjectUUID: [self UUID]];
//    }
//	else
//	{
//		[item_ addObject: aValue
//   toUnorderedAttribute: anAttribute
//				   type: aType];
//        
//        [parentContext_ recordModifiedObjectUUID: [self UUID]];
//	}
//	
//}
//
//- (void)   addObject: (id)aValue
//  toOrderedAttribute: (NSString*)anAttribute
//			 atIndex: (NSUInteger)anIndex
//{
//    COType aType = [self typeForAttribute: anAttribute];
//    NSParameterAssert(aType != 0);
//
//	if (COPrimitiveType(aType) == kCOEmbeddedItemType)
//	{
//		[self addObject:  aValue atItemPath: [COItemPath pathWithItemUUID: [self UUID]
//																arrayName: anAttribute
//														   insertionIndex: anIndex
//																	 type: aType]];
//	}
//    else if (COPrimitiveType(aType) == kCOReferenceType)
//    {
//		[item_ addObject: [aValue UUID]
//      toOrderedAttribute: anAttribute
//                 atIndex: anIndex
//                    type: aType];
//        
//        [parentContext_ recordModifiedObjectUUID: [self UUID]];
//    }
//	else
//	{
//		[item_ addObject: aValue
//	 toOrderedAttribute: anAttribute
//				atIndex: anIndex
//				   type: aType];
//        
//        [parentContext_ recordModifiedObjectUUID: [self UUID]];
//	}
//}
//
//- (void)   addObject: (id)aValue
//  toOrderedAttribute: (NSString*)anAttribute
//{
//    COType aType = [self typeForAttribute: anAttribute];
//    NSParameterAssert(COTypeIsOrdered(aType));
//
//	NSUInteger anIndex = [[item_ valueForAttribute: anAttribute] count];
//    
//	[self addObject: aValue
// toOrderedAttribute: anAttribute
//			atIndex: anIndex];
//}
//
//- (void) removeValueForAttribute: (NSString*)anAttribute
//{
//	if (COPrimitiveType([item_ typeForAttribute: anAttribute]) == kCOEmbeddedItemType)
//	{
//		for (COUUID *uuidToRemove in [item_ allObjectsForAttribute: anAttribute])
//		{
//            [parentContext_ removeUnreachableObjectAndChildren: uuidToRemove];
//		}
//	}
//    
//	[item_ removeValueForAttribute: anAttribute];
//}
//
///**
// * Removes a Object (regardless of where in the receiver or the receiver's children
// * it is located.) Throws an exception if the guven UUID is not present in the receiver.
// */
//- (void) removeDescendentObjectWithUUID: (COUUID *)aUUID
//{
//	[self removeDescendentObject: [self descendentObjectForUUID: aUUID]];
//}
//
//- (void) removeDescendentObject: (COObject *)anObject
//{
//	if (anObject == self)
//	{
//		[NSException raise: NSInvalidArgumentException
//					format: @"-removeObjectWithUUID: can not remove the receiver"];
//	}
//	if (![self containsObject: anObject])
//	{
//		[NSException raise: NSInvalidArgumentException
//					format: @"argument must be inside the reciever to remove it"];
//	}
//	
//	COUUID *aUUID = [anObject UUID];
//	COObject *parentOfObjectToRemove = [anObject embeddedObjectParent];
//	COItemPath *itemPath = [self itemPathOfDescendentObjectWithUUID: aUUID];
//	NSAssert([[itemPath UUID] isEqual: [parentOfObjectToRemove UUID]], @"");
//	[itemPath removeValue: aUUID inStoreItem: parentOfObjectToRemove->item_];
//
//    [parentContext_ removeUnreachableObjectAndChildren: aUUID];
//}


#pragma mark KVC-like ordered collection accessors and mutation methods

- (NSUInteger) countOfAttribute: (NSString *)attribute
{
    
}

- (id) objectInAttribute: (NSString *)attribute
                 atIndex: (NSUInteger)index
{
    
}

- (void) insertObject: (id)anObject
          inAttribute: (NSString*)anAttribute
              atIndex: (NSString *)anIndex
{
    
}

- (void) removeObjectFromAttribute: (NSString*)anAttribute
                           atIndex: (NSString *)anIndex
{
    
}

#pragma mark KVC-like unordered collection accessors and mutation methods

- (NSEnumerator *) enumeratorOfAttribute: (NSString*)anAttribute
{
    
}

- (BOOL) memberOfAttribute: (NSString*)anAttribute
{
    
}

- (void) addObject: (id)anObject
       inAttribute: (NSString*)anAttribute
{
    
}

- (void) removeObject: (id)anObject
        fromAttribute: (NSString*)anAttribute
{
    
}

// Logging

- (NSString *) selfDescription
{
	return [NSString stringWithFormat: @"[COObject %@]", [self UUID]];
}

static NSString *tabs(NSUInteger i)
{
	NSMutableString *result = [NSMutableString string];
	for (NSUInteger j=0; j<i; j++)
    {
		[result appendFormat: @"\t"];
    }
	return result;
}

- (NSString *) descriptionWithIndent: (NSUInteger)i
{
	NSMutableString *result = [NSMutableString string];
	[result appendFormat: @"%@%@\n", tabs(i), [self selfDescription]];
	
    for (COObject *content in [self directDescendentObjects])
    {
        [result appendFormat: @"%@", [content descriptionWithIndent: i+1]];
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
