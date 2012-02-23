#import "COSubtree.h"
#import "COMacros.h"
#import "COItemPath.h"
#import "COSubtreeCopy.h"

@implementation COSubtree

- (void) debug
{
	// check consistency of parent pointers
	
	for (COSubtree *subtree in [embeddedSubtrees allValues])
	{
		assert([subtree parent] == self);
		assert([subtree root] == [self root]);
		[subtree debug];
	}
	
	// check for 1:1 correspondence between embedded items
	// in our COItem and the embeddedSubtrees dictionary
	
	assert([[self directDescendentSubtreeUUIDs] isEqual:
				[NSSet setWithArray: [embeddedSubtrees allKeys]]]);
}

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

- (id) initWithItemDictionary: (NSDictionary *)items
					 rootUUID: (ETUUID *)aRootUUID
{
	NILARG_EXCEPTION_TEST(items);
	NILARG_EXCEPTION_TEST(aRootUUID);
	
	if ([items objectForKey: aRootUUID] == nil)
	{
		[NSException raise: NSInvalidArgumentException
					format: @"items do not form a valid tree"];
	}
	
	SUPERINIT;
	root = [[items objectForKey: aRootUUID] mutableCopy];
	embeddedSubtrees = [[NSMutableDictionary alloc] init];
	
	// WARNING: the receiver is in an inconsistent state right now
	// so -directDescendentSubtreeUUIDs must not access embeddedSubtrees
	// since it is not yet set up.
	for (ETUUID *aUUID in [self directDescendentSubtreeUUIDs])
	{
		COSubtree *subTree = [[[self class] alloc] initWithItemDictionary: items
																 rootUUID: aUUID];
		subTree->parent = self;
		[embeddedSubtrees setObject: subTree
							 forKey: aUUID];
		[subTree release];
	}
	
	[self debug];
	
	return self;
}

- (void) dealloc
{
	for (COSubtree *aSubtree in [embeddedSubtrees allValues])
	{
		aSubtree->parent = nil;
	}
	DESTROY(root);
	DESTROY(embeddedSubtrees);
	[super dealloc];
}

+ (COSubtree *)subtree
{
	return [[[self alloc] init] autorelease];
}

+ (COSubtree *)subtreeWithItemSet: (NSSet*)items
						 rootUUID: (ETUUID *)aRootUUID
{
	// We put the items in a temporary dictionary by UUID 
	// to make constructing the tree more convenient
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity: [items count]];
	
	for (COItem *item in items)
	{
		[dict setObject: item forKey: [item UUID]];
	}
	
	return [[[self alloc] initWithItemDictionary: dict rootUUID: aRootUUID] autorelease];
}

- (id)copyWithNameMapping: (NSDictionary *)aMapping
{
	COMutableItem *newRoot = [[root mutableCopyWithNameMapping: aMapping] autorelease];

	NSMutableDictionary *newItems = [NSMutableDictionary dictionary];
	
	COSubtree *newCopy = [[COSubtree alloc] init];
	
	for (COSubtree *tree in [embeddedSubtrees allValues])
	{
		COSubtree *treeCopy = [tree copyWithNameMapping: aMapping];
		[newItems setObject: treeCopy forKey: [treeCopy UUID]];
		treeCopy->parent = newCopy;
		[treeCopy release];
	}
	
	ASSIGN(newCopy->root, newRoot);
	ASSIGN(newCopy->embeddedSubtrees, newItems);
	
	[newCopy debug];
	
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

- (NSSet *)allContainedStoreItems
{
	NSMutableSet *result = [NSMutableSet set];
	
	[result addObject: [[root copy] autorelease]];
	
	for (COSubtree *node in [self directDescendentSubtrees])
	{
		[result unionSet: [node allContainedStoreItems]];
	}
	
	return result;
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
	// WARNING: See comment in initWithItemDictionary:rootUUID:.
	// We call this method there before the embeddedSubtrees ivar is set up,
	// so we must not access it here.
	
	NSMutableSet *set = [NSMutableSet set];
	
	for (NSString *attr in [root attributeNames])
	{
		COType *type = [root typeForAttribute: attr];
		if ([[type primitiveType] isEqual: [COType embeddedItemType]])
		{
			[set addObjectsFromArray: [root allObjectsForAttribute: attr]];
		}
	}
	
	return [NSSet setWithSet: set];
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
	if ([[self UUID] isEqual: aUUID])
	{
		return self;
	}
	
	COSubtree *directDescendant = [embeddedSubtrees objectForKey: aUUID];
	if (directDescendant != nil)
	{
		assert([directDescendant root] == [self root]);
		return directDescendant;
	}
	
	for (COSubtree *node in [self directDescendentSubtrees])
	{
		COSubtree *recursiveResult = [node subtreeWithUUID: aUUID];
		if (recursiveResult != nil)
		{
			assert([recursiveResult root] == [self root]);
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
	
	// Search destSubtreeParent's attributes for [destSubtree UUID];
	// FIXME: Factor out?
	
	for (NSString *attr in [destSubtreeParent attributeNames])
	{
		if ([[destSubtreeParent->root allObjectsForAttribute: attr] containsObject: [destSubtree UUID]])
		{
			COType *type = [destSubtreeParent typeForAttribute: attr];
			if ([type isMultivalued])
			{
				if ([type isOrdered])
				{
					NSUInteger index = [[destSubtreeParent->root allObjectsForAttribute: attr] indexOfObject: [destSubtree UUID]];
					
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



#pragma mark Access to the receiver's attributes/values


- (COItem *) item
{
	return [[root copy] autorelease];
}

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
}

- (void) setValue: (id)aValue
	 forAttribute: (NSString*)anAttribute
			 type: (COType *)aType
{
	if ([[aType primitiveType] isEqual: [COType embeddedItemType]])
	{
		if (![aType isMultivalued])
		{
			[self addSubtree: aValue atItemPath: [COItemPath pathWithItemUUID: [self UUID]
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
					COSubtree *aSubtree = [array objectAtIndex: i];
					
					[self addSubtree: aSubtree
						  atItemPath: [COItemPath pathWithItemUUID: [self UUID]
														 arrayName: anAttribute
													insertionIndex: i
															  type: aType]];
				}
			}
			else
			{
				for (COSubtree *aSubtree in aValue)
				{
					[self addSubtree: aSubtree
						  atItemPath: [COItemPath pathWithItemUUID: [self UUID]
										   unorderedCollectionName: anAttribute
															  type: aType]];
				}
			}
		}
	}
	else
	{
		[root setValue: aValue
		  forAttribute: anAttribute
				  type: aType];
	}
	
	[self debug];
}

- (void)   addObject: (id)aValue
toUnorderedAttribute: (NSString*)anAttribute
				type: (COType *)aType
{
	if ([[aType primitiveType] isEqual: [COType embeddedItemType]])
	{
		[self addSubtree: aValue atItemPath: [COItemPath pathWithItemUUID: [self UUID]
												  unorderedCollectionName: anAttribute
																	 type: aType]];
	}
	else
	{
		[root addObject: aValue
   toUnorderedAttribute: anAttribute
				   type: aType];
	}
	
	[self debug];
}

- (void)   addObject: (id)aValue
  toOrderedAttribute: (NSString*)anAttribute
			 atIndex: (NSUInteger)anIndex
				type: (COType *)aType
{
	if ([[aType primitiveType] isEqual: [COType embeddedItemType]])
	{
		[self addSubtree: aValue atItemPath: [COItemPath pathWithItemUUID: [self UUID]
																arrayName: anAttribute
														   insertionIndex: anIndex
																	 type: aType]];
	}
	else
	{
		[root addObject: aValue
	 toOrderedAttribute: anAttribute
				atIndex: anIndex
				   type: aType];
	}
	
	[self debug];
}

- (void)   addObject: (id)aValue
  toOrderedAttribute: (NSString*)anAttribute
				type: (COType *)aType
{
	NSUInteger anIndex = [[root valueForAttribute: anAttribute] count];
						  
	[self addObject: aValue
 toOrderedAttribute: anAttribute
			atIndex: anIndex
			   type: aType];
}

- (void)removeValueForAttribute: (NSString*)anAttribute
{
	if ([[[root typeForAttribute: anAttribute] primitiveType] isEqual: [COType embeddedItemType]])
	{
		for (ETUUID *uuidToRemove in [root allObjectsForAttribute: anAttribute])
		{
			[embeddedSubtrees removeObjectForKey: uuidToRemove];
		}
	}
		
	[root removeValueForAttribute: anAttribute];
	
	[self debug];
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
	if (![[self UUID] isEqual: [aPath UUID]] &&
		![self containsSubtreeWithUUID: [aPath UUID]])
	{
		[NSException raise: NSInvalidArgumentException
					format: @"itemPath must be inside the receiver"];
	}
	
	[aSubtree retain]; // balanced by release at end of method
	
	if ([aSubtree parent] != nil)
	{
		[[aSubtree parent] removeSubtreeWithUUID: [aSubtree UUID]];
		aSubtree->parent = nil;
	}
	
	// see if there are any name conflicts
	
	NSMutableSet *conflictingNames = [NSMutableSet setWithSet: [[self root] allUUIDs]];
	[conflictingNames intersectSet: [aSubtree allUUIDs]];
	
	if ([conflictingNames count] > 0)
	{
		[NSException raise: NSInvalidArgumentException
					format: @"addSubtree:atItemPath: expects no name conflicts"];
	}
	
	// set up the parent and insert the tree
	
	if ([[aPath UUID] isEqual: [self UUID]])
	{
		aSubtree->parent = self;
	}
	else
	{
		aSubtree->parent = [self subtreeWithUUID: [aPath UUID]];
	}
	[aSubtree->parent->embeddedSubtrees setObject: aSubtree
										   forKey: [aSubtree UUID]];
	[aPath insertValue: [aSubtree UUID]
		   inStoreItem: aSubtree->parent->root];  
	
	[aSubtree release]; // balance retain at start of method
	
	[self debug];
}

- (COSubtreeCopy *) addSubtreeRenamingObjectsOnConflict: (COSubtree *)aSubtree
											 atItemPath: (COItemPath *)aPath
{
	// see if there are any name conflicts
	
	NSMutableSet *conflictingNames = [NSMutableSet setWithSet: [[self root] allUUIDs]];
	[conflictingNames intersectSet: [aSubtree allUUIDs]];
	
	NSLog(@"Renaming conflicting UUIDS: %@", conflictingNames);
	NSMutableDictionary *renameDict = [NSMutableDictionary dictionaryWithCapacity: [conflictingNames count]];
	for (ETUUID *conflictingName in conflictingNames)
	{
		[renameDict setObject: [ETUUID UUID] forKey: conflictingName];
	}
	
	COSubtree *aSubtreeRenamed = [[aSubtree copyWithNameMapping: renameDict] autorelease];
		
	[self addSubtree: aSubtreeRenamed
		  atItemPath: aPath];
	
	[aSubtreeRenamed debug];
	
	return [COSubtreeCopy subtreeCopyWithSubtree: aSubtreeRenamed
							   mappingDictionary: renameDict];
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
	COSubtree *parentOfSubtreeToRemove = [[self subtreeWithUUID: aUUID] parent];
	if (parentOfSubtreeToRemove == nil)
	{
		[NSException raise: NSInvalidArgumentException
					format: @"argument must be inside the reciever to remove it"];
	}
	
	COItemPath *itemPath = [self itemPathOfSubtreeWithUUID: aUUID];	
	NSAssert([[itemPath UUID] isEqual: [parentOfSubtreeToRemove UUID]], @"");
	[itemPath removeValue: aUUID inStoreItem: parentOfSubtreeToRemove->root];
	[parentOfSubtreeToRemove->embeddedSubtrees removeObjectForKey: aUUID];
	
	[self debug];
}

- (void) moveSubtreeWithUUID: (ETUUID *)aUUID
				  toItemPath: (COItemPath *)aPath
{
	COSubtree *subtreeToMove = [self subtreeWithUUID: aUUID];
	[self addSubtree: subtreeToMove
		  atItemPath: aPath];
}

- (void) renameWithNameMapping: (NSDictionary *)aMapping
{
	COMutableItem *newRoot = [[root mutableCopyWithNameMapping: aMapping] autorelease];
	ASSIGN(root, newRoot);
	
	NSMutableDictionary *newItems = [NSMutableDictionary dictionary];
	for (COSubtree *tree in [embeddedSubtrees allValues])
	{
		[tree renameWithNameMapping: aMapping];
		[newItems setObject: tree forKey: [tree UUID]];
	}
	
	ASSIGN(embeddedSubtrees, newItems);
	
	[self debug];
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



#pragma mark Serialization


- (id) plist
{
	NSMutableArray *itemPlists = [NSMutableArray array];
	
	for (COItem *item in [self allContainedStoreItems])
	{
		[itemPlists addObject: [item plist]];
	}
	
	return D([[self UUID] stringValue], @"rootUUID",
			 itemPlists, @"items");
}

+ (COSubtree *)subtreeWithPlist: (id)aPlist
{
	ETUUID *rootUUID = [ETUUID UUIDWithString: [aPlist objectForKey: @"rootUUID"]];
	NSMutableSet *itemSet = [NSMutableSet set];
	
	for (id itemPlist in [aPlist objectForKey: @"items"])
	{
		[itemSet addObject: [[[COItem alloc] initWithPlist: itemPlist] autorelease]];
	}
	
	return [self subtreeWithItemSet: itemSet rootUUID: rootUUID];
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
