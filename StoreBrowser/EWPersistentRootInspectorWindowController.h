#import <Cocoa/Cocoa.h>
#import <NestedVersioning/NestedVersioning.h>

@interface EWPersistentRootInspectorWindowController : NSWindowController
{
    COPersistentRoot *root_;
}

@property (nonatomic, readonly) COPersistentRoot *persistentRoot;

- (id)initWithPersistentRoot: (COPersistentRoot *)aRoot;

@end
