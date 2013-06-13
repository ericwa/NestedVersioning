#import <Foundation/Foundation.h>

#import "COEditingContext.h"
#import "COObject.h"

@class COObject;
@class COItemPath;

@interface  COEditingContext (Private)

- (void) updateRelationshipIntegrityWithOldValue: (id)oldVal
                                         oldType: (COType)oldType
                                        newValue: (id)newVal
                                         newType: (COType)newType
                                     forProperty: (NSString *)aProperty
                                        ofObject: (COUUID *)anObject;
@end

@interface COObject (Private)

- (id) initWithItem: (COItem *)anItem
      parentContext: (COEditingContext *)aContext;
- (void) setItem: (COItem *)anItem;
- (void) markAsRemovedFromContext;

@end