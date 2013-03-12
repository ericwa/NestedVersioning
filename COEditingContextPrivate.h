#import <Foundation/Foundation.h>

#import "COEditingContext.h"
#import "COObject.h"

@class COObject;
@class COItemPath;

@interface  COEditingContext (Private)

- (void) recordInsertedObjectUUID: (COUUID *)aUUID;
- (void) recordDeletedObjectUUID: (COUUID *)aUUID;
- (void) recordModifiedObjectUUID: (COUUID *)aUUID;

- (void) removeUnreachableObjectAndChildren: (COUUID *)anObject;

- (COObject *) updateObject: (COUUID *)aUUID
             fromItemTree: (COItemTree *)aTree
                  setParent: (COObject *)parent;

@end

@interface COObject (Private)

- (id) initWithItem: (COItem *)anItem
      parentContext: (COEditingContext *)aContext;
- (void) setItem: (COItem *)anItem;
- (void) markAsRemovedFromContext;

@end