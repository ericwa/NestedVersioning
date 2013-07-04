#import <Foundation/Foundation.h>

#import "COObjectGraphContext.h"
#import "COObject.h"

@class COObject;
@class COItemPath;

@interface  COObjectGraphContext (Private)

- (void) updateRelationshipIntegrityWithOldValue: (id)oldVal
                                         oldType: (COType)oldType
                                        newValue: (id)newVal
                                         newType: (COType)newType
                                     forProperty: (NSString *)aProperty
                                        ofObject: (ETUUID *)anObject;
@end

@interface COObject (Private)

- (id) initWithItem: (COItem *)anItem
      parentContext: (COObjectGraphContext *)aContext;
- (void) setItem: (COItem *)anItem;
- (void) markAsRemovedFromContext;

@end