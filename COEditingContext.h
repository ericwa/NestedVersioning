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

- (id) initWithSchemaRegistry: (COSchemaRegistry *)aRegistry;

+ (COEditingContext *) editingContext;

+ (COEditingContext *) editingContextWithSchemaRegistry: (COSchemaRegistry *)aRegistry;

#pragma mark Schema

- (COSchemaRegistry *) schemaRegistry;

#pragma mark begin COItemGraph protocol

- (COUUID *) rootItemUUID;

/**
 * Returns immutable item
 */
- (COItem *) itemForUUID: (COUUID *)aUUID;
- (NSArray *) itemUUIDs;

/**
 * Insert or update an item.
 */
- (void) addItem: (COItem *)anItem;

#pragma mark end COItemGraph protocol

/**
 * Replaces the editing context.
 *
 * There are 3 kinds of change:
 *  - New objects are inserted
 *  - Removed objects are removed
 *  - Changed objects are updated. (sub-case: identical objects)
 */
- (void) setItemTree: (id <COItemGraph>)aTree;

/**
 * IDEA:
 * Though COEditingContext implements COItemGraph, this method returns
 * an independent snapshot of the editing context, suitable for passing
 * to a background thread
 */
- (id<COItemGraph>) itemGraphSnapshot;

- (COObject *) rootObject;
- (void) setRootObject: (COObject *)anObject;

#pragma mark change tracking

/**
 * Returns the set of objects inserted since change tracking was cleared
 */
- (NSSet *) insertedObjectUUIDs;
/**
 * Returns the set of objects modified since change tracking was cleared
 */
- (NSSet *) modifiedObjectUUIDs;
- (NSSet *) insertedOrModifiedObjectUUIDs;

- (void) clearChangeTracking;

- (COObject *) insertObjectWithSchemaName: (NSString *)aSchemaName;

- (COObject *) insertObject;

#pragma mark access

- (COObject *) objectForUUID: (COUUID *)aUUID;

/**
 * @return If there exists an object which has a [COType embeddedObjectType] reference to
 * anObject, return that object. Otherwise return nil.
 */
- (COObject *) embeddedObjectParent: (COObject *)anObject;
// FIXME: How should this api look?
- (NSSet *) referrersForUUID: (COUUID *)anObject;

@end
