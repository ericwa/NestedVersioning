#import <Foundation/Foundation.h>
#import "COItemTree.h"

@class COUUID;
@class COItemTree;
@class COObject;
@class COItem;
@class COSchemaRegistry;
@class COSchema;
@class CORelationshipCache;


@interface COEditingContext : NSObject <COItemGraph, NSCopying>
{
    COUUID *rootObjectUUID_;
    NSMutableDictionary *objectsByUUID_;
    
    NSMutableSet *insertedObjects_;
    NSMutableSet *modifiedObjects_;
    
    COSchemaRegistry *schemaRegistry_;
    
    // relationship caches:
    
    CORelationshipCache *relationshipCache_;
}

#pragma mark Creation

+ (COEditingContext *) editingContext;

+ (COEditingContext *) editingContextWithSchemaRegistry: (COSchemaRegistry *)aRegistry;

#pragma mark Adding objects

- (COObject *) insertObject;

- (COObject *) insertObjectWithSchemaName: (NSString *)aSchemaName;

/**
 * Inserts an item tree into the context. The COObject representing the tree root is returned.
 * Normal relabeling rules are followed.
 */
- (COObject *) insertItemTree: (COItemTree *)aTree;

- (COObject *) deleteObject: (COObject *)anObject;

#pragma mark Schema

- (COSchemaRegistry *) schemaRegistry;

#pragma mark Accessing Object Tree

- (COObject *) objectForUUID: (COUUID *)uuid;

- (NSSet *) allObjectUUIDs;

- (COObject *) rootObject;
/**
 * @throws exception if anObject is not in this context
 */
- (void) setRootObject: (COObject *)anObject;

- (COObject *) cloneObject: (COObject *)anObject;

/**
 * @return If there exists an object which has a [COType embeddedObjectType] reference to
 * anObject, return that object. Otherwise return nil.
 */
- (COObject *) embeddedObjectParent: (COObject *)anObject;


/**
 * Returns a copy of the reciever, not including any change tracking
 * information.
 */
- (id) copyWithZone: (NSZone *)aZone;


- (COItemTree *) itemTree;

/**
 * Clears change tracking
 */
- (void) setItemTree: (COItemTree *)aTree;

#pragma mark change tracking

/**
 * Returns the set of objects inserted since change tracking was cleared
 */
- (NSSet *) insertedObjectUUIDs;
/**
 * Returns the set of objects deleted since change tracking was cleared
 */
- (NSSet *) deletedObjectUUIDs;
/**
 * Returns the set of objects modified since change tracking was cleared
 */
- (NSSet *) modifiedObjectUUIDs;

- (NSSet *) insertedOrModifiedObjectUUIDs;

- (void) clearChangeTracking;

#pragma mark store integration

- (NSArray *)commitWithMetadata: (NSDictionary *)metadata;

@end
