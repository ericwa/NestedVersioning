#import <Foundation/Foundation.h>

@class COUUID;
@class COObjectTree;
@class COObject;

@interface COEditingContext : NSObject <NSCopying>
{
    COUUID *rootUUID_;
    NSMutableDictionary *objectsByUUID_;
    
    NSMutableSet *insertedObjects_;
    NSMutableSet *deletedObjects_;
    NSMutableSet *modifiedObjects_;
}

- (NSSet *)allUUIDs;

- (id) initWithObjectTree: (COObjectTree *)aTree;

- (COObject *) rootObject;

- (COObject *)objectForUUID: (COUUID *)uuid;

- (COObjectTree *)objectTree;

/**
 * Builds a COSubtree from a set of items and the UUID
 * of the root item. Throws an exception under any of these circumstances:
 *  - items does not contain an item with UUID aRootUUID
 *  - items contains more than one item with the same UUID
 */
+ (COEditingContext *)editingContextWithObjectTree: (COObjectTree *)aTree;

/**
 * Returns a copy of the reciever, not including any change tracking
 * information.
 */
- (id) copyWithZone: (NSZone *)aZone;

/**
 * Clears change tracking
 */
- (void) setObjectTree: (COObjectTree *)aTree;

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

- (void) clearChangeTracking;

@end
