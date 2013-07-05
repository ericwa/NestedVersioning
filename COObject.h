#import <Foundation/Foundation.h>
#import "COItem.h"

@class COObjectGraphContext;
@class COItemGraph;
@class COItemPath;
@class COSchema;

NSString *kCOSchemaName;

@interface COObject : NSObject
{
    @package
    COObjectGraphContext *parentContext_; // weak
    COMutableItem *item_;
}

#pragma mark Serialization / Deserialization

@property (nonatomic, copy, readwrite) COItem *seriailzedItem;

#pragma mark Access to the receivers attributes/values


- (COObjectGraphContext *) editingContext;

- (ETUUID *) UUID;

- (NSArray *) attributeNames;

- (COType) typeForAttribute: (NSString *)anAttribute;

- (id) valueForAttribute: (NSString*)anAttribute;

- (NSString *) schemaName;

- (COSchema *) schema;

#pragma mark Access to the tree stucture

- (COObject *) embeddedObjectParent;

- (BOOL) containsObject: (COObject *)anObject;

- (NSSet *) allObjectUUIDs;

- (NSSet *) allDescendentObjectUUIDs;

- (NSSet *) directDescendentObjectUUIDs;

- (NSSet *) directDescendentObjects;

- (NSSet *) embeddedOrReferencedObjects;

/**
 * Searches the receiver for the Object with the givent UUID.
 * Returns nil if not present
 */
- (COObject *) descendentObjectForUUID: (ETUUID *)aUUID;

- (COItemPath *) itemPathOfDescendentObjectWithUUID: (ETUUID *)aUUID;

#pragma mark Mutation

/**
 * Can only be used if we have a schema already set, or that attribute already had an
 * explicit type set.
 */
- (void) setValue: (id)aValue
	 forAttribute: (NSString*)anAttribute;

- (void) setValue: (id)aValue
	 forAttribute: (NSString*)anAttribute
			 type: (COType)aType;
@end
