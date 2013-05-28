#import <Foundation/Foundation.h>
#import "COItem.h"

@class COEditingContext;
@class COItemTree;
@class COItemPath;
@class COSchema;

NSString *kCOSchemaName;

@interface COObject : NSObject
{
    @package
    COEditingContext *parentContext_; // weak
    COMutableItem *item_;
}

#pragma mark Access to the receivers attributes/values

- (COEditingContext *) editingContext;

- (COUUID *) UUID;

- (NSArray *) attributeNames;

- (COType *) typeForAttribute: (NSString *)anAttribute;

- (id) valueForAttribute: (NSString*)anAttribute;

- (NSString *) schemaName;
/**
 * Looks up -schemaName in our context's schema registry.
 */
- (COSchema *) schema;

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
