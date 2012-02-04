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
	
	if ([aType isEqual: [COType embeddedItemType]])
	{
		[self addSubtree: aValue atItemPath: [COItemPath pathWithItemUUID: [self UUID]
																valueName: anAttribute
																	 type: aType]];
	}
	else
	{
		[root setValue: aValue
		  forAttribute: anAttribute
				  type: aType];
	}
}

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
