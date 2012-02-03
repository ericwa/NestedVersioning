#import "COSubtree.h"
#import "COMacros.h"
#import "COItemPath.h"
#import "COSubtreeCopy.h"

@implementation COSubtree


/* @taskunit Creation */


- (id) init
{
	return [self initWithUUID: [ETUUID UUID]];
}

- (id) initWithUUID: (ETUUID*)aUUID
{
	NILARG_EXCEPTION_TEST(aUUID);
	
	SUPERINIT
	root = [[COMutableItem alloc] initWithUUID: aUUID];
	embeddedSubtrees = [[NSMutableDictionary alloc] init];
	return self;
}

- (void) dealloc
{
	[root release];
	[embeddedSubtrees release];
	[super dealloc];
}

+ (COSubtree *)subtree
{
	return [[[self alloc] init] autorelease];
}

- (id)copyWithNameMapping: (NSDictionary *)aMapping
{
	// FIXME: implement
	
	
	NSMutableDictionary *newItems = [NSMutableDictionary dictionary];
	
	COMutableItem *newRoot = [[root copy] autorelease];
	
	COSubtree *newCopy = [[COSubtree alloc] init];
	
	for (ETUUID *uuid in embeddedSubtrees)
	{
		COSubtree *tree = [[embeddedSubtrees objectForKey: uuid] copy];
		[newItems setObject: tree forKey: uuid];
		tree->parent = newCopy;
		[tree release];
	}
	
	ASSIGN(newCopy->root, newRoot);
	ASSIGN(newCopy->embeddedSubtrees, newItems);
	
	return newCopy;
}

- (id)copyWithZone:(NSZone *)zone
{
	return [self copyWithNameMapping: [NSDictionary dictionary]];
}

- (COSubtreeCopy *)subtreeCopyRenamingAllItems
{
	NSSet *oldNames = [self allUUIDs];
	NSMutableDictionary *mapping = [NSMutableDictionary dictionaryWithCapacity: [oldNames count]];
	
	for (ETUUID *oldName in oldNames)
	{
		[mapping setObject: [ETUUID UUID]
					forKey: oldName];
	}
	
	return [self subtreeCopyWithNameMapping: mapping];
}

- (COSubtreeCopy *)subtreeCopyWithNameMapping: (NSDictionary *)aMapping
{
	COSubtree *theCopy = [[self copyWithNameMapping: aMapping] autorelease];
	
	return [COSubtreeCopy subtreeCopyWithSubtree: theCopy
							   mappingDictionary: aMapping];
}


#pragma mark Access to the tree stucture


- (COSubtree *) parent
{
	return parent;
}

- (COSubtree *) root
{
	COSubtree *aRoot = self;
	while ([aRoot parent] != nil)
	{
		aRoot = [aRoot parent];
	}
	return aRoot;
}

- (BOOL) containsSubtreeWithUUID: (ETUUID *)aUUID
{
	return nil != [self subtreeWithUUID: aUUID];
}

- (NSSet *)allUUIDs
{
	return [[self allDescendentSubtreeUUIDs] setByAddingObject: [self UUID]];
}

- (NSSet *)allDescendentSubtreeUUIDs
{
	NSMutableSet *result = [NSMutableSet set];
	
	for (COSubtree *node in [self directDescendentSubtrees])
	{
		[result addObject: [node UUID]];
		[result unionSet: [node allDescendentSubtreeUUIDs]];
	}
	
	return result;
}

- (NSSet *)directDescendentSubtreeUUIDs
{
	return [NSSet setWithArray: [embeddedSubtrees allKeys]];
}

- (NSArray *)directDescendentSubtrees;
{
	return [embeddedSubtrees allValues];
}

/**
 * Searches the receiver for the subtree with the givent UUID.
 * Returns nil if not present
 */
- (COSubtree *) subtreeWithUUID: (ETUUID *)aUUID
{
	COSubtree *directDescendant = [embeddedSubtrees objectForKey: aUUID];
	if (directDescendant != nil)
	{
		return directDescendant;
	}
	
	for (COSubtree *node in [self directDescendentSubtrees])
	{
		COSubtree *recursiveResult = [node subtreeWithUUID: aUUID];
		if (recursiveResult != nil)
		{
			return recursiveResult;
		}
	}
	
	return nil;
}

- (COItemPath *) itemPathOfSubtreeWithUUID: (ETUUID *)aUUID
{
	COSubtree *destSubtree = [self subtreeWithUUID: aUUID];
	
	if (destSubtree == nil)
	{
		return nil;
	}
	
	COSubtree *destSubtreeParent = [destSubtree parent];
	
	// Search destSubtreeParent for [destSubtree UUID];
	// FIXME: Factor out?
	
	for (NSString *attr in [destSubtreeParent attributeNames])
	{
		if ([[destSubtreeParent->root allObjectsForAttribute: attr] containsObject: [destSubtree UUID]])
		{
			if ([[destSubtreeParent typeForAttribute: attr] isOrdered])
			{
				
			}
			else
			{
				
			}
		}
	}
	
	[NSException raise: NSInternalInconsistencyException
				format: @"COSubtree inconsistent"];
	return nil;
}



#pragma mark Access to the receiver's attributes/values



- (ETUUID *) UUID
{
	return [root UUID];
}

- (NSArray *) attributeNames
{
	return [root attributeNames];
}

- (COType *) typeForAttribute: (NSString *)anAttribute
{
	return [root typeForAttribute: anAttribute];
}
- (id) valueForAttribute: (NSString*)anAttribute
{
	id rootValue = [root valueForAttribute: anAttribute];
	COType *type = [self typeForAttribute: anAttribute];
	
	if ([[type primitiveType] isEqual: [COType embeddedItemType]])
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
			
			for (ETUUID *uuid in rootValue)
			{
				COSubtree *node = [embeddedSubtrees objectForKey: uuid];
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
			COSubtree *node = [embeddedSubtrees objectForKey: rootValue];
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



#pragma mark Mutation



- (void) setValue: (id)aValue
			  forAttribute: (NSString*)anAttribute
					  type: (COType *)aType
{
	if (![aType isPrimitive])
	{
		[NSException raise: NSInvalidArgumentException
					format: @"%@ expected a primitive type", NSStringFromSelector(_cmd)];
	}
	
	if ([aType isEqual: [COType embeddedItemType]])
	{
		
	}
	else
	{
		
	}
}

/*
- (void) setValue: (id)aValue
	 forAttribute: (NSString *)anAttribute
			 type: (COType *)aType
{
	if ([[aType primitiveType] isEqual: [COType embeddedItemType]])
	{
		NSSet *embeddedUUIDsForAllAttributes = [self embeddedSubtreeUUIDs];
		
		if ([aType isMultivalued])
		{
			NSSet *oldEmbeddedUUIDsForAttribute = [NSSet setWithArray: [root allObjectsForAttribute: anAttribute]];
			NSSet *newEmbeddedUUIDsForAttribute;
			if ([aType isOrdered])
			{
				newEmbeddedUUIDsForAttribute = [NSSet setWithArray: aValue];
			}
			else
			{
				newEmbeddedUUIDsForAttribute = aValue;
			}
			
			
		}
		else
		{
			
		}
		
		
		
		
		
		if ([aType isMultivalued])
		{
			id container;
			
			if ([aValue isKindOfClass: [NSCountedSet class]])
			{
				container = [NSCountedSet set];
			}
			else if ([aValue isKindOfClass: [NSArray class]])
			{
				container = [NSMutableArray array];
			}
			else if ([aValue isKindOfClass: [NSSet class]])
			{
				container = [NSMutableSet set];
			}
			else assert(0);

			for (COSubtree *aTree in aValue)
			{
				assert([aTree isKindOfClass: [COSubtree class]]);
				[container addObject: [aTree UUID]];
				[embeddedSubtrees setObject: aTree forKey: [aTree UUID]];
				((COSubtree*)aTree)->parent = self;
			}
			
			[root setValue: container forAttribute: anAttribute type: aType];
		}
		else
		{
			assert([aValue isKindOfClass: [self class]]);
			[embeddedSubtrees setObject: aValue forKey: [aValue UUID]];
			((COSubtree*)aValue)->parent = self;
			[root setValue: [aValue UUID] forAttribute: anAttribute type: aType];
		}
	}
	else
	{
		[root setValue:aValue forAttribute:anAttribute type:aType];
	}
}
*/


- (void)removeValueForAttribute: (NSString*)anAttribute
{
	[root removeValueForAttribute: anAttribute];
}


/**
 * Inserts the given subtree at the given item path.
 * The provided subtree is removed from its parent, if it has one.
 * i.e. [aSubtree parent] is mutated by the method call!
 *
 * Works regardless of whether aSubtree is a descendant of
 * [self parent].
 */
- (void) addSubtree: (COSubtree *)aSubtree
		 atItemPath: (COItemPath *)aPath
{
	if ([aSubtree parent] != nil)
	{
		// Remove from parent
		
		
		aSubtree->parent = nil;
	}
	
	
	if ([aSubtree root] == [self root])
	{
		// Move within root's subtree
	}
	else
	{
		
	}
	
	aSubtree->parent = [[self root] subtreeWithUUID: [aPath UUID]];
}

/**
 * Removes a subtree (regardless of where in the receiver or the receiver's children
 * it is located.) Throws an exception if the guven UUID is not present in the receiver.
 */
- (void) removeSubtreeWithUUID: (ETUUID *)aUUID
{
	if ([[self UUID] isEqual: aUUID])
	{
		[NSException raise: NSInvalidArgumentException
					format: @"-removeSubtreeWithUUID: can not remove the receiver"];
	}
	COItemPath *itemPath = [self itemPathOfSubtreeWithUUID: aUUID];
	
	// FIXMRE: remove aUUID from the set/array named by itemPath
}

- (void) moveSubtreeWithUUID: (ETUUID *)aUUID
				  toItemPath: (COItemPath *)aPath
{
	COSubtree *subtreeToMove = [self subtreeWithUUID: aUUID];
	[self addSubtree: subtreeToMove
		  atItemPath: aPath];
}




#pragma mark equality testing



- (BOOL) isEqual:(id)object
{
	if (![object isKindOfClass: [self class]])
	{
		return NO;
	}
	COSubtree *otherItemTree = (COSubtree*)object;
	
	if (![otherItemTree->root isEqual: root]) return NO;
	if (![otherItemTree->embeddedSubtrees isEqual: embeddedSubtrees]) return NO;
	return YES;
}

- (NSUInteger) hash
{
	return [root hash] ^ [embeddedSubtrees hash];
}

@end


@implementation COSubtree (ContentsProperty)

- (void) addTree: (COSubtree *)aValue
{
	[self addSubtree: aValue
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
		[NSException raise: NSInternalInconsistencyException
					format: @"contents attribute not a set type"];
	}
	return contents;
}

@end
