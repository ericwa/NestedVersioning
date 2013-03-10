#import <Foundation/Foundation.h>
#import "COItem.h"

@class COEditingContext;
@class COItemTree;
@class COItemPath;

NSString *kCOSchemaName;

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
    COMutableItem *item_;
}

#pragma mark Access to the receivers attributes/values

- (COEditingContext *) editingContext;

- (COItem *) item;

- (COUUID *) UUID;

- (NSSet *) attributeNames;

- (COType *) typeForAttribute: (NSString *)anAttribute;

- (id) valueForAttribute: (NSString*)anAttribute;

- (NSString *) schemaName;

#pragma mark Access to the tree stucture

- (COObject *) embeddedObjectParent;

- (BOOL) containsObject: (COObject *)anObject;

- (NSSet *) allObjectUUIDs;

- (NSSet *) allStoreItems;

- (NSSet *) allDescendentObjectUUIDs;

- (NSSet *) directDescendentObjectUUIDs;

- (NSSet *) directDescendentObjects;

- (COObject *) descendentObjectForUUID: (COUUID *)aUUID;

- (COItemPath *) itemPathOfDescendentObjectWithUUID: (COUUID *)aUUID;

- (COItemTree *) itemTree;

#pragma mark Mutation

/**
 * Can only be used if we have a schema already set, or that attribute already had an
 * explicit type set.
 */
- (void) setValue: (id)aValue
	 forAttribute: (NSString*)anAttribute;

- (void) setValue: (id)aValue
	 forAttribute: (NSString*)anAttribute
			 type: (COType *)aType;

- (void) setValue: (id)aValue
	 forAttribute: (NSString*)anAttribute;

- (void)   addObject: (id)aValue
toUnorderedAttribute: (NSString*)anAttribute;

- (void)   addObject: (id)aValue
  toOrderedAttribute: (NSString*)anAttribute
			 atIndex: (NSUInteger)anIndex;

- (void)   addObject: (id)aValue
  toOrderedAttribute: (NSString*)anAttribute;

- (void) removeValueForAttribute: (NSString*)anAttribute;

- (void) removeDescendentObjectWithUUID: (COUUID *)aUUID;

- (void) removeDescendentObject: (COObject *)anObject;

#pragma mark Mutation Internal

- (COObject *) addObject: (COObject *)anObject
              atItemPath: (COItemPath *)aPath;

- (void) moveDescendentObjectWithUUID: (COUUID *)aUUID
                           toItemPath: (COItemPath *)aPath;

#pragma mark contents property

- (COObject *) addObjectToContents: (COObject *)aValue;

- (NSSet *) contents;

- (COEditingContext *) independentEditingContext;

@end
