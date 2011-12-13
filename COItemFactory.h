#import <Cocoa/Cocoa.h>
#import "COItemTreeNode.h"

@interface COItemFactory : NSObject
{
}

+ (COItemFactory *)factory;

- (COItemTreeNode*) newFolder: (NSString*)aName;
- (COItemTreeNode*) newItem: (NSString*)aName;

@end
