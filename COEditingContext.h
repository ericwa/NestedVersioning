#import <Foundation/Foundation.h>

@class COUUID;
@class COObjectTree;
@class COObject;


/*


*/
@interface COEditingContext : NSObject <NSCopying>
{
    COUUID *rootUUID_;
    NSMutableDictionary *objectsByUUID_;
    
    NSMutableSet *dirtyObjects_;
}

- (COObject *) rootObject;

- (NSSet *)allUUIDs;

- (COObjectTree *)objectTree;
- (COEditingContext *)editingContextWithObjectTree: (COObjectTree *)aTree;

- (void) setObjectTree: (COObjectTree *)aTree;

- (COObject *)objectForUUID: (COUUID *)uuid;



@end
