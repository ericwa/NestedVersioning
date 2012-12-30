#import "COObject.h"
#import "COType.h"
#import "COItem.h"
#import "COItemTree.h"
#import "COEditingContext.h"
#import "COEditingContextPrivate.h"
#import "COItemPath.h"
#import "COMacros.h"

@implementation COObject (Private)

- (id) initWithItem: (COItem *)anItem parentContext: (COEditingContext *)aContext parent: (COObject *)aParent
{
    SUPERINIT;
    [self updateItem: anItem
       parentContext: aContext
              parent: aParent];
    return self;
}

- (void) updateItem: (COItem *)anItem parentContext: (COEditingContext *)aContext parent: (COObject *)aParent
{
    item_ = [anItem mutableCopy];
    parentContext_ = aContext;
    parent_ = aParent;
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
    // FIXME Watch out that COEditingContext manages the parent_ pointer
    [item_ release];
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
	return [item_ typeForAttribute: anAttribute];
}
- (id) valueForAttribute: (NSString*)anAttribute
{
	id rootValue = [item_ valueForAttribute: anAttribute];
	COType *type = [self typeForAttribute: anAttribute];
	
	if ([type isPrimitiveTypeEqual: [COType embeddedItemType]])
	{
		if ([type isMultivalued])
		{
			id container;
			
			if ([type isOrdered])
			{
				container = [NSMutableArray array];;
			}
			else
			{
				container = [NSMutableSet set];
			}
			
			for (COUUID *uuid in rootValue)
			{
				COObject *node = [parentContext_ objectForUUID: uuid];
				if (node == nil)
				{
					[NSException raise: NSInternalInconsistencyException
								format: @"broken COItemTreeNode instance: missing sub-node %@", uuid];
				}
				
				[container addObject: node];
			}
			
			return container;
		}
		else
		{
			COObject *node = [parentContext_ objectForUUID: rootValue];
			if (node == nil)
			{
				[NSException raise: NSInternalInconsistencyException
							format: @"broken COItemTreeNode instance: missing sub-node %@", rootValue];
			}
			
			return node;
		}
	}
	else
	{
		return rootValue;
	}
}



#pragma mark Access to the tree stucture


- (COObject *) parentObject
{
	return parent_;
}

- (COObject *) rootObject
{
	return [parentContext_ rootObject];
}

- (BOOL) containsObject: (COObject *)anObject
{
	for (; anObject != nil; anObject = [anObject parentObject])
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
	
	COObject *destObjectParent = [destObject parentObject];
	
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



- (void) setValue: (id)aValue
	 forAttribute: (NSString*)anAttribute
			 type: (COType *)aType
{
    // FIXME: Track removed objects if we overwrote a Object
    
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
				type: (COType *)aType
{
	if ([aType isPrimitiveTypeEqual: [COType embeddedItemType]])
	{
		[self addObject:  aValue atItemPath: [COItemPath pathWithItemUUID: [self UUID]
												  unorderedCollectionName: anAttribute
																	 type: aType]];
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
				type: (COType *)aType
{
	if ([aType isPrimitiveTypeEqual: [COType embeddedItemType]])
	{
		[self addObject:  aValue atItemPath: [COItemPath pathWithItemUUID: [self UUID]
																arrayName: anAttribute
														   insertionIndex: anIndex
																	 type: aType]];
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
				type: (COType *)aType
{
	NSUInteger anIndex = [[item_ valueForAttribute: anAttribute] count];
    
	[self addObject: aValue
 toOrderedAttribute: anAttribute
			atIndex: anIndex
			   type: aType];
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
	COObject *parentOfObjectToRemove = [anObject parentObject];
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
	COObject *parentOfObjectToRemove = [aObject parentObject];
    
	COItemPath *itemPath = [parentOfObjectToRemove itemPathOfDescendentObjectWithUUID: aUUID];
	NSAssert([[itemPath UUID] isEqual: [parentOfObjectToRemove UUID]], @"");
	[itemPath removeValue: aUUID inStoreItem: parentOfObjectToRemove->item_];
    [parentContext_ recordModifiedObjectUUID: [parentOfObjectToRemove UUID]];
    
    // add to self
    
    [aPath insertValue: aUUID inStoreItem: self->item_];
    aObject->parent_ = self;
    [parentContext_ recordModifiedObjectUUID: [self UUID]];
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
