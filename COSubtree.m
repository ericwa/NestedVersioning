#import "COSubtree.h"
#import "COMacros.h"

@implementation COSubtree

- (id) initWithUUID: (ETUUID*)aUUID
{
	NILARG_EXCEPTION_TEST(aUUID);
	
	SUPERINIT
	root = [[COMutableItem alloc] initWithUUID: aUUID];
	embeddedSubtrees = [[NSMutableDictionary alloc] init];
	return self;
}

- (id) init
{
	return [self initWithUUID: [ETUUID UUID]];
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

- (ETUUID *)UUID
{
	return [root UUID];
}


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

- (void) setValue: (id)aValue
	 forAttribute: (NSString *)anAttribute
			 type: (COType *)aType
{
	if ([[aType primitiveType] isEqual: [COType embeddedItemType]])
	{
		NSSet *embeddedUUIDsForAllAttributes = [self embeddedItemTreeNodeUUIDs];
		
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

- (void)removeValueForAttribute: (NSString*)anAttribute
{
	[root removeValueForAttribute: anAttribute];
}

- (NSSet *)embeddedItemTreeNodeUUIDs
{
	return [NSSet setWithArray: [embeddedSubtrees allKeys]];
}
- (NSArray *)embeddedSubtrees
{
	return [embeddedSubtrees allValues];
}

/** @taskunit I/O */

- (NSSet*) allContainedStoreItems
{
	NSMutableSet *result = [NSMutableSet set];
	
	[result addObject: root];
	
	for (COSubtree *node in [self embeddedSubtrees])
	{
		[result unionSet: [node allContainedStoreItems]];
	}
	return result;
}

- (NSSet*) allContainedStoreItemUUIDs
{
	NSMutableSet *result = [NSMutableSet set];
	for (COMutableItem *item in [self allContainedStoreItems])
	{
		[result addObject: [item UUID]];
	}
	return result;
}

/** @taskunit convenience */

- (void) addTree: (COSubtree *)aValue
 forSetAttribute: (NSString*)anAttribute
{
	id container = [self valueForAttribute: anAttribute];
	COType *type = [self typeForAttribute: anAttribute];
	
	if (container == nil)
	{
		container = [NSSet setWithObject: aValue];
	}
	else
	{
		assert([type isEqual: [COType setWithPrimitiveType: [COType embeddedItemType]]]);
		container = [container setByAddingObject: aValue];
	}
	
	[self setValue: container
	  forAttribute: anAttribute
			  type: [COType setWithPrimitiveType: [COType embeddedItemType]]];
}

- (void) removeTree: (COSubtree *)aValue
	forSetAttribute: (NSString*)anAttribute
{
	id container = [NSMutableSet setWithSet: [self valueForAttribute: anAttribute]];
	COType *type = [self typeForAttribute: anAttribute];
	assert(type == nil || [type isEqual: [COType setWithPrimitiveType: [COType embeddedItemType]]]);

	[container removeObject: aValue];
	
	[self setValue: container
	  forAttribute: anAttribute
			  type: [COType setWithPrimitiveType: [COType embeddedItemType]]];
}

- (void) addTree: (COSubtree *)aValue
{
	[self addTree: aValue
  forSetAttribute: @"contents"];
}
- (void) removeTree: (COSubtree *)aValue
{
	[self removeTree: aValue
	 forSetAttribute: @"contents"];
}

- (NSSet*)contents
{
	NSSet *contents = [self valueForAttribute: @"contents"];
	if (contents != nil)
	{
		return contents;
	}
	return [NSSet set];
}

- (id)copyWithZone:(NSZone *)zone
{
	NSMutableDictionary *newItems = [NSMutableDictionary dictionary];
	
	COMutableItem *newRoot = [[root copy] autorelease];
	
	COSubtree *newCopy = [[COSubtree alloc] init];
	
	for (ETUUID *uuid in embeddedSubtrees)
	{
		COSubtree *tree = [[embeddedSubtrees objectForKey: uuid] copyWithZone: zone];
		[newItems setObject: tree forKey: uuid];
		tree->parent = newCopy;
		[tree release];
	}
	
	ASSIGN(newCopy->root, newRoot);
	ASSIGN(newCopy->embeddedSubtrees, newItems);
		   
	return newCopy;
}

- (COSubtreeCopy *)subtreeCopyRenamingAllItems
{
	NSSet *oldNames = [self allContainedStoreItemUUIDs];
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
	[NSException raise: NSInternalInconsistencyException format: @"unimplemented"];
}

/** @taskunit equality testing */

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

