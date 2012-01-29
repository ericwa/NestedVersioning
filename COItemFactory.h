#import <Cocoa/Cocoa.h>
#import "COSubtree.h"

@interface COItemFactory : NSObject
{
}

+ (COItemFactory *)factory;

- (COSubtree*) folder: (NSString*)aName;
- (COSubtree*) item: (NSString*)aName;

@end
