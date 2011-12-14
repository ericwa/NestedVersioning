#import <Cocoa/Cocoa.h>
#import "COItemTreeNode.h"

@interface COItemFactory : NSObject
{
}

+ (COItemFactory *)factory;

- (COItemTreeNode*) folder: (NSString*)aName;
- (COItemTreeNode*) item: (NSString*)aName;

@end
