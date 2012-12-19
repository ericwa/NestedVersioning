#import <Foundation/Foundation.h>
#import "COItem.h"

@class COEditingContext;
@class COObjectTree;
@class COItemPath;

/**
 * General behaviour:
 When setting values, you can pass another COObject.
 
 If you do,
 1. if it's from the same context, you must ensure it's not the receiver or a parent of the receiver.
    The argument will be removed from its parent and placed in its destination.
 
 2. if it's from another context, it will be copied. If any UUIDs overlap any UUIDs in our context,
    they will be renamed.
 
*/
@interface COObject : NSObject
{
    COEditingContext *parentContext_; // weak
    
    COObject *parent_; // weak
    COMutableItem *item;
}

#pragma mark Access to the receivers attributes/values

- (COEditingContext *)editingContext;

- (COItem *) item;

- (COUUID *) UUID;

- (NSArray *) attributeNames;

- (COType *) typeForAttribute: (NSString *)anAttribute;

- (id) valueForAttribute: (NSString*)anAttribute;

#pragma mark Access to the tree stucture

- (COObject *)parent;

- (COObject *) root;

- (BOOL) containsObject: (COObject *)aSubtree;

- (NSSet *)allUUIDs;

- (NSSet *)allContainedStoreItems;

- (NSSet *)allDescendentSubtreeUUIDs;

- (NSSet *)directDescendentSubtreeUUIDs;

- (NSSet *)directDescendentSubtrees;

- (COObject *) subtreeWithUUID: (COUUID *)aUUID;

- (COItemPath *) itemPathOfSubtreeWithUUID: (COUUID *)aUUID;

- (COObjectTree *) objectTree;

#pragma mark Mutation

- (void) setPrimitiveValue: (id)aValue
			  forAttribute: (NSString*)anAttribute
					  type: (COType *)aType;

- (void) setValue: (id)aValue
	 forAttribute: (NSString*)anAttribute
			 type: (COType *)aType;

- (void)   addObject: (id)aValue
toUnorderedAttribute: (NSString*)anAttribute
				type: (COType *)aType;

- (void)   addObject: (id)aValue
  toOrderedAttribute: (NSString*)anAttribute
			 atIndex: (NSUInteger)anIndex
				type: (COType *)aType;

- (void)   addObject: (id)aValue
  toOrderedAttribute: (NSString*)anAttribute
				type: (COType *)aType;

- (void)removeValueForAttribute: (NSString*)anAttribute;

- (void) removeSubtreeWithUUID: (COUUID *)aUUID;

- (void) removeSubtree: (COObject *)aSubtree;

#pragma mark Mutation Internal

- (COObject *) addSubtree: (COObject *)aSubtree
               atItemPath: (COItemPath *)aPath;

- (void) moveSubtreeWithUUID: (COUUID *)aUUID
				  toItemPath: (COItemPath *)aPath;

#pragma mark contents property

- (COObject *) addTree: (COObject *)aValue;

- (NSSet*) contents;

@end
