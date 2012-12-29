#import <Foundation/Foundation.h>
#import "COItem.h"

@class COEditingContext;
@class COItemTree;
@class COItemPath;

/**
 * General behaviour:
 When setting values, you can pass another COObject.
 
 If you do,
 1. if it's from the same context, you must ensure it's not the receiver or a parent of the receiver.
    The argument will be removed from its parent and placed in its destination.
 
 2. if it's from another context, it will be copied. If any UUIDs overlap any UUIDs in our context,
    they will be renamed.
 

 general comment on copying:
 
 - when we copy/move an embedded object from one persistent root to another, it keeps the same uuid. are there any cases where this could cause problems? what if the destination already has objects with some/all of those uuids? probably keep the familiar filesystem semantics:
 • copy & paste in the same directory (for CO: in the same persistent root), and it makes sense to assign new UUIDs since otherwise the copy&paste would do nothing.
 • copy & paste in to another directory (for CO: into another persistent root), and it makes sense to keep the same UUIDs, and overwrite any existing destination objects(?)
 
* This is a mutable model object for modelling the contents of a persistent
 * root... high-level counterpart to COItem. See comment in COItem.h.
 * COSubtree instances are arranged in a tree structure following
 * normal ObjC container semantics.
 *
 * Comment on NestedVersioning data model:
 *
 * Why is the data model a tree instead of a reference-counted graph?
 * We want our data model to have clear and simple semantics for copying
 * and moving sections of data, and by forcing users to structure data
 * in a tree they are defining the copying semantics of their data
 * as a side effect

 
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

- (COItemTree *) objectTree;

#pragma mark Mutation

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
