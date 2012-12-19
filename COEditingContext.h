#import <Foundation/Foundation.h>

@class COUUID;
@class COObjectTree;
@class COObject;

@interface COEditingContext : NSObject <NSCopying>
{
    COUUID *rootUUID_;
    NSMutableDictionary *objectsByUUID_;
    
    NSMutableSet *dirtyObjects_;
}

- (NSSet *)allUUIDs;

- (id) initWithObjectTree: (COObjectTree *)aTree;

- (COObject *) rootObject;

- (COObject *)objectForUUID: (COUUID *)uuid;

- (COObjectTree *)objectTree;

+ (COEditingContext *)editingContextWithObjectTree: (COObjectTree *)aTree;

- (void) setObjectTree: (COObjectTree *)aTree;

- (NSArray *) dirtyObjectUUIDs;

@end
