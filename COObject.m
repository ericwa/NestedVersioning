#import "COObject.h"
#import "COType.h"
#import "COItem.h"
#import "COEditingContext.h"
#import "COEditingContextPrivate.h"
#import "COItemPath.h"
#import "COMacros.h"

@implementation COObject

- (id) initWithItem: (COItem *)anItem parentContext: (COEditingContext *)aContext parent: (COObject *)aParent
{
    SUPERINIT;
    item = [anItem mutableCopy];
    parentContext_ = aContext;
    parent_ = aParent;
    return self;
}

- (void) dealloc
{
    // FIXME Watch out that COEditingContext manages the parent_ pointer
    [item release];
    [super dealloc];
}

#pragma mark Access to the receivers attributes/values


- (COEditingContext *)editingContext
{
    return parentContext_;
}

- (COItem *) item
{
	return [[item copy] autorelease];
}

- (COUUID *) UUID
{
	return [item UUID];
}

- (NSArray *) attributeNames
{
	return [item attributeNames];
}

- (COType *) typeForAttribute: (NSString *)anAttribute
{
	return [item typeForAttribute: anAttribute];
}
- (id) valueForAttribute: (NSString*)anAttribute
{
	id rootValue = [item valueForAttribute: anAttribute];
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


- (COObject *) parent
{
	return parent_;
}

- (COObject *) root
{
	return [parentContext_ rootObject];
}

- (BOOL) containsSubtree: (COObject *)aSubtree
{
	for (; aSubtree != nil; aSubtree = [aSubtree parent])
	{
		if (aSubtree == self)
		{
			return YES;
		}
	}
	return NO;
}

- (NSSet *)allUUIDs
{
	return [[self allDescendentSubtreeUUIDs] setByAddingObject: [self UUID]];
}

- (NSSet *)allContainedStoreItems
{
	NSMutableSet *result = [NSMutableSet set];
	
	[result addObject: [[item copy] autorelease]];
	
	for (COObject *node in [self directDescendentSubtrees])
	{
		[result unionSet: [node allContainedStoreItems]];
	}
	
	return result;
}

- (NSSet *)allDescendentSubtreeUUIDs
{
	NSMutableSet *result = [NSMutableSet set];
	
	for (COObject *node in [self directDescendentSubtrees])
	{
		[result addObject: [node UUID]];
		[result unionSet: [node allDescendentSubtreeUUIDs]];
	}
	
	return result;
}

- (NSSet *)directDescendentSubtreeUUIDs
{
	return [item embeddedItemUUIDs];
}

- (NSArray *)directDescendentSubtrees
{
    NSSet *uuids = [item embeddedItemUUIDs];
	NSMutableArray *result = [NSMutableArray arrayWithCapacity: [uuids count]];
    for (COUUID *uuid in uuids)
    {
        [result addObject: [parentContext_ objectForUUID: uuid]];
    }
    return result;
}

/**
 * Searches the receiver for the subtree with the givent UUID.
 * Returns nil if not present
 */
- (COObject *) subtreeWithUUID: (COUUID *)aUUID
{
	COObject *object = [parentContext_ objectForUUID: aUUID];
    if ([self containsSubtree: object])
    {
        return object;
    }
	else
    {
        return nil;
    }
}

- (COItemPath *) itemPathOfSubtreeWithUUID: (COUUID *)aUUID
{
	COObject *destSubtree = [self subtreeWithUUID: aUUID];
	
	if (destSubtree == nil)
	{
		return nil;
	}
	
	COObject *destSubtreeParent = [destSubtree parent];
	
	// Search destSubtreeParent's attributes for [destSubtree UUID];
	// FIXME: Factor out?
	
	for (NSString *attr in [destSubtreeParent attributeNames])
	{
		if ([[destSubtreeParent->item allObjectsForAttribute: attr] containsObject: [destSubtree UUID]])
		{
			COType *type = [destSubtreeParent typeForAttribute: attr];
			if ([type isMultivalued])
			{
				if ([type isOrdered])
				{
					NSUInteger index = [[destSubtreeParent->item allObjectsForAttribute: attr] indexOfObject: [destSubtree UUID]];
					
					return [COItemPath pathWithItemUUID: [destSubtreeParent UUID]
											  arrayName: attr
										 insertionIndex: index
												   type: type];
				}
				else
				{
					return [COItemPath pathWithItemUUID: [destSubtreeParent UUID]
								unorderedCollectionName: attr
												   type: type];
				}
			}
			else
			{
				return [COItemPath pathWithItemUUID: [destSubtreeParent UUID]
										  valueName: attr
											   type: type];
			}
		}
	}
	
	[NSException raise: NSInternalInconsistencyException
				format: @"COSubtree inconsistent"];
	return nil;
}

- (COObjectTree *) objectTree
{
    NSMutableDictionary *objects = [NSMutableDictionary dictionary];
    for (COItem *item in [self allContainedStoreItems])
    {
        [objects setObject: item forKey: [item UUID]];
    }
    
    return [[[COObjectTree alloc] initWithItemForUUID: objects root: [self UUID]] autorelease];
}

#pragma mark Mutation



- (void) setPrimitiveValue: (id)aValue
			  forAttribute: (NSString*)anAttribute
					  type: (COType *)aType
{
	if (![aType isPrimitive])
	{
		[NSException raise: NSInvalidArgumentException
					format: @"%@ expected a primitive type", NSStringFromSelector(_cmd)];
	}
	
	[self setValue: aValue
	  forAttribute: anAttribute
			  type: aType];
    
    [parentContext_ recordDirtyObject: self];
}

- (void) setValue: (id)aValue
	 forAttribute: (NSString*)anAttribute
			 type: (COType *)aType
{
	if ([aType isPrimitiveTypeEqual: [COType embeddedItemType]])
	{
		if (![aType isMultivalued])
		{
			[self addSubtree:  aValue atItemPath: [COItemPath pathWithItemUUID: [self UUID]
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
					COObject *aSubtree = [array objectAtIndex: i];
					
					[self addSubtree:  aSubtree
                                    atItemPath: [COItemPath pathWithItemUUID: [self UUID]
                                                                   arrayName: anAttribute
                                                              insertionIndex: i
                                                                        type: aType]];
				}
			}
			else
			{
				for (COObject *aSubtree in aValue)
				{
					[self addSubtree:  aSubtree
                                    atItemPath: [COItemPath pathWithItemUUID: [self UUID]
                                                     unorderedCollectionName: anAttribute
                                                                        type: aType]];
				}
			}
		}
	}
	else
	{
		[item setValue: aValue
		  forAttribute: anAttribute
				  type: aType];
        
        [parentContext_ recordDirtyObject: self];
	}

}



- (void)   addObject: (id)aValue
toUnorderedAttribute: (NSString*)anAttribute    
				type: (COType *)aType
{
	if ([aType isPrimitiveTypeEqual: [COType embeddedItemType]])
	{
		[self addSubtree:  aValue atItemPath: [COItemPath pathWithItemUUID: [self UUID]
												  unorderedCollectionName: anAttribute
																	 type: aType]];
	}
	else
	{
		[item addObject: aValue
   toUnorderedAttribute: anAttribute
				   type: aType];
        
        [parentContext_ recordDirtyObject: self];
	}
	
}

- (void)   addObject: (id)aValue
  toOrderedAttribute: (NSString*)anAttribute
			 atIndex: (NSUInteger)anIndex
				type: (COType *)aType
{
	if ([aType isPrimitiveTypeEqual: [COType embeddedItemType]])
	{
		[self addSubtree:  aValue atItemPath: [COItemPath pathWithItemUUID: [self UUID]
																arrayName: anAttribute
														   insertionIndex: anIndex
																	 type: aType]];
	}
	else
	{
		[item addObject: aValue
	 toOrderedAttribute: anAttribute
				atIndex: anIndex
				   type: aType];
        
        [parentContext_ recordDirtyObject: self];
	}
}

- (void)   addObject: (id)aValue
  toOrderedAttribute: (NSString*)anAttribute
				type: (COType *)aType
{
	NSUInteger anIndex = [[item valueForAttribute: anAttribute] count];
    
	[self addObject: aValue
 toOrderedAttribute: anAttribute
			atIndex: anIndex
			   type: aType];
}

- (void)removeValueForAttribute: (NSString*)anAttribute
{
	if ([[item typeForAttribute: anAttribute] isPrimitiveTypeEqual: [COType embeddedItemType]])
	{
		for (COUUID *uuidToRemove in [item allObjectsForAttribute: anAttribute])
		{
            [parentContext_ removeUnreachableObjectAndChildren: uuidToRemove];
		}
	}
    
	[item removeValueForAttribute: anAttribute];
}

/**
 * Removes a subtree (regardless of where in the receiver or the receiver's children
 * it is located.) Throws an exception if the guven UUID is not present in the receiver.
 */
- (void) removeSubtreeWithUUID: (COUUID *)aUUID
{
	[self removeSubtree: [self subtreeWithUUID: aUUID]];
}

- (void) removeSubtree: (COObject *)aSubtree
{
	if (aSubtree == self)
	{
		[NSException raise: NSInvalidArgumentException
					format: @"-removeSubtreeWithUUID: can not remove the receiver"];
	}
	if (![self containsSubtree: aSubtree])
	{
		[NSException raise: NSInvalidArgumentException
					format: @"argument must be inside the reciever to remove it"];
	}
	
	COUUID *aUUID = [aSubtree UUID];
	COObject *parentOfSubtreeToRemove = [aSubtree parent];
	COItemPath *itemPath = [self itemPathOfSubtreeWithUUID: aUUID];
	NSAssert([[itemPath UUID] isEqual: [parentOfSubtreeToRemove UUID]], @"");
	[itemPath removeValue: aUUID inStoreItem: parentOfSubtreeToRemove->item];

    [parentContext_ removeUnreachableObjectAndChildren: aUUID];
}

#pragma mark Mutation Internal

- (void) addObjectTree: (COObjectTree *)aTree
            atItemPath: (COItemPath *)aPath
{
    // see if there are any name conflicts
    
    NSMutableSet *conflictingNames = [NSMutableSet setWithSet: [parentContext_ allUUIDs]];
    [conflictingNames intersectSet: [NSSet setWithArray: [aTree objectUUIDs]]];
    
    if ([conflictingNames count] > 0)
    {
        NSLog(@"names %@ need to be remapped", conflictingNames);
     
        NSMutableDictionary *mapping = [NSMutableDictionary dictionary];
        for (COUUID *name in conflictingNames)
        {
            [mapping setObject: [COUUID UUID]
                        forKey: name];
        }
        
        aTree = [aTree objectTreeWithNameMapping: mapping];
    }
    
    // now, there are no name conflicts.
    
    COObject *newObject = [parentContext_ createObjectWithDescendents: [aTree root]
                                                       fromObjectTree: aTree
                                                               parent: self];
    [aPath insertValue: [aTree root] inStoreItem: self->item];
    
    // record dirty objects

    [parentContext_ recordDirtyObject: self];
    for (COUUID *uuid in [aTree objectUUIDs])
    {
        [parentContext_ recordDirtyObjectUUID: uuid];
    }
}

- (void) addObjectSameContext: (COObject *)aObject
                   atItemPath: (COItemPath *)aPath
{
    if (aObject == self)
    {
        [NSException raise: NSInvalidArgumentException format: @"can't add an object to itself"];
    }
    if ([aObject containsSubtree: self])
    {
        [NSException raise: NSInvalidArgumentException format: @"can't add an object to a child of itself"];
    }
    
    // remove from parent
    
    COUUID *aUUID = [aObject UUID];
	COObject *parentOfSubtreeToRemove = [aObject parent];
    
	COItemPath *itemPath = [parentOfSubtreeToRemove itemPathOfSubtreeWithUUID: aUUID];
	NSAssert([[itemPath UUID] isEqual: [parentOfSubtreeToRemove UUID]], @"");
	[itemPath removeValue: aUUID inStoreItem: parentOfSubtreeToRemove->item];
    [parentContext_ recordDirtyObject: parentOfSubtreeToRemove];
    
    // add to self
    
    [aPath insertValue: aUUID inStoreItem: self->item];
    aObject->parent_ = self;
    [parentContext_ recordDirtyObject: self];
}


/**
 * Inserts the given subtree at the given item path.
 * The provided subtree is removed from its parent, if it has one.
 * i.e. [aSubtree parent] is mutated by the method call!
 *
 * Works regardless of whether aSubtree is a descendant of
 * [self parent].
 */
- (void) addSubtree: (COObject *)aSubtree
		 atItemPath: (COItemPath *)aPath
{
    NSParameterAssert([[self UUID] isEqual: [aPath UUID]]);
 
    if ([aSubtree editingContext] == [self editingContext])
    {
        [self addObjectSameContext: aSubtree
                        atItemPath: aPath];
    }
    else
    {
        [self addObjectTree: [aSubtree objectTree]
                 atItemPath: aPath];
    }
}

- (void) moveSubtreeWithUUID: (COUUID *)aUUID
				  toItemPath: (COItemPath *)aPath
{
	COObject *subtreeToMove = [self subtreeWithUUID: aUUID];
	[self addSubtree: subtreeToMove
		  atItemPath: aPath];
}



#pragma mark contents property


- (void) addTree: (COObject *)aValue
{
	[self addSubtree:  aValue
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


- (NSString *)selfDescription
{
	return [NSString stringWithFormat: @"%@ (%@)", [self valueForAttribute: @"name"], [self UUID]];
}

- (NSString *)tabs: (NSUInteger)i
{
	NSMutableString *result = [NSMutableString string];
	for (NSUInteger j=0; j<i; j++)
		[result appendFormat: @"\t"];
	return result;
}

- (NSString *)descriptionWithIndent: (NSUInteger)i
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

- (NSString *)description
{
	return [self descriptionWithIndent: 0];
}

// Equality

- (BOOL) isEqual:(id)object
{
	if (![object isKindOfClass: [self class]])
	{
		return NO;
	}
    COObject *otherObject = (COObject *)object;

    if (otherObject->parentContext_ == parentContext_)
    {
        return object == self;
    }
    else
    {
        // FIXME: For now, objects in different contexts are equal if they have the same UUID.
        // We should instead do a deep equality test.
        return [[self UUID] isEqual: [object UUID]];
    }
}

- (NSUInteger) hash
{
	return [[item UUID] hash];
}

@end

@implementation COObject (Private)

- (void) markAsRemovedFromContext
{
    parentContext_ = nil;
    // FIXME: Add checks in various places that throw an exception if a user
    // tries to do anything with a COObject with a nil editingContext
}

@end