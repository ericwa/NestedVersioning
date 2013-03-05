#import <Foundation/Foundation.h>

@class COUUID;
@class COItemTree;
@class COObject;
@class COItem;

@interface COEditingContext : NSObject <NSCopying>
{
    COUUID *rootObjectUUID_;
    NSMutableDictionary *objectsByUUID_;
    
    NSMutableSet *insertedObjects_;
    NSMutableSet *deletedObjects_;
    NSMutableSet *modifiedObjects_;
}

- (NSSet *) allObjectUUIDs;

- (id) initWithItemTree: (COItemTree *)aTree;

- (COObject *) rootObject;

- (COObject *) objectForUUID: (COUUID *)uuid;

/**
 * Builds a COSubtree from a set of items and the UUID
 * of the root item. Throws an exception under any of these circumstances:
 *  - items does not contain an item with UUID aRootUUID
 *  - items contains more than one item with the same UUID
 */
+ (COEditingContext *) editingContextWithItemTree: (COItemTree *)aTree;

+ (COEditingContext *) editingContextWithItem: (COItem *)anItem;

+ (COEditingContext *) editingContext;

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

@end
