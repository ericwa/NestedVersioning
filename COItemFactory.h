#import <Cocoa/Cocoa.h>
#import "COStoreItemTree.h"

@interface COItemFactory : NSObject
{
}

+ (COItemFactory *)factory;

- (COStoreItemTree*) newFolder: (NSString*)aName;
- (COStoreItemTree*) newItem: (NSString*)aName;

@end
