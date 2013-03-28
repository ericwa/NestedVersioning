#import <Foundation/Foundation.h>

@class COUUID;
@class COItemTree;
@class COObject;
@class COItem;
@class COSchemaRegistry;
@class COSchema;
@class CORelationshipCache;

/**
 * Maintaining relationship caches within a persistent root:
 * ========================================================
 
 we want to do it with one operation:
 
    update( [set of modified items] )
 
 The cache state is:
 
    embedded-object-parents:
        uuid -> parent uuid
 
    relationship-parents:
        uuid -> ( reference sources )
 
 
 define update(items-before, items-after) as:
    for item in items-before:
        for embedded-item in item:
            embedded-object-parents[embedded-item.uuid] = nil
        for referenced-item in item:
            relationship-parents[referenced-item.uuid] -= item;
 
    for item in items-after:
        " update embedded objects parents cache "
        for embedded-item in item:
            embedded-object-parents[embedded-item.uuid] = item.uuid

        " update relationships cache "
        for referenced-item in item:
            relationship-parents[referenced-item.uuid] += item;
 
 This can trivially be given finer-grained change info ( key:val pairs before and after)
 to be more efficient.
 
 
 Besides updating the relationship cache, the only other "trigger"-like
 behaviour that happens when making an edit is:
  - when _adding_ an embedded object to a property, that embedded object
    is removed from its old parent.
 
 
Fundamental question
 ==================
 
 Can we track relationships that cross persistent root boundaries?
 seamlessly like within-persistent-root ones?
 
 Clearly embedded object relations (composites) can't cross.
 
 For relationships... we can, given the following:
    - the query results depend on a "working set" of editing contexts, like CO trunk's COEditingContext
    - the results may come from different persistent roots, so may have the same embdedded object UUID.
 
 TODO: Talk to quentin about this
 
 */
@interface COEditingContext : NSObject <NSCopying>
{
    COUUID *rootObjectUUID_;
    NSMutableDictionary *objectsByUUID_;
    
    NSMutableSet *insertedObjects_;
    NSMutableSet *deletedObjects_;
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
