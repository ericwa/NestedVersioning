#import <Cocoa/Cocoa.h>
#import <NestedVersioning/NestedVersioning.h>

@interface EWStoreDocument : NSDocument
{
    COStore *store_;
}

@property (nonatomic, retain, readonly) COStore *store;

@end
