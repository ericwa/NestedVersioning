#import <Foundation/Foundation.h>
#import "COItem.h"

@class COEditingContext;

/**
 * General behaviour:
 When setting values, you can pass another COObject.
 
 If you do,
 1. if it's from the same context, you must ensure it's not the receiver or a parent of the receiver.
    The argument will be removed from its parent and placed in its destination.
 
 2. if it's from another context, it will be copied. If any UUIDs overlap any UUIDs in our context,
    they will be renamed.
 
*/
@interface COObject : NSObject
{
    COEditingContext *parentContext_; // weak
    
    COObject *parent_; // weak
    COMutableItem *item;
}

- (COObject *)parent;

- (COEditingContext *)editingContext;

@end
