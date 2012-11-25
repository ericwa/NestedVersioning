#import <Foundation/Foundation.h>

#import "COEditingContext.h"
#import "COObject.h"

@class COObject;
@class COItemPath;

@interface  COEditingContext (Private)

- (void) recordDirtyObject: (COObject *)anObject;

- (void) removeUnreachableObjectAndChildren: (COUUID *)anObject;

- (COObject *) createObjectWithDescendents: (COUUID *)aUUID
                            fromObjectTree: (COObjectTree *)aTree
                                    parent: (COObject *)parent;

@end

@interface COObject (Private)

- (id) initWithItem: (COItem *)anItem parentContext: (COEditingContext *)aContext parent: (COObject *)aParent;
- (void) markAsRemovedFromContext;

@end