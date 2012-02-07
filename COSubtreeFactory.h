#import <Cocoa/Cocoa.h>
#import "COSubtree.h"

@interface COSubtreeFactory : NSObject
{
}

+ (COSubtreeFactory *)factory;

- (COSubtree*) folder: (NSString*)aName;
- (COSubtree*) item: (NSString*)aName;

@end
