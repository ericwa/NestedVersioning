#import <Cocoa/Cocoa.h>

@class COSubtree;

@interface EWBezierPath : NSObject
{
}

+ (COSubtree *) subtreeFromBezierPath: (NSBezierPath *)path;
+ (NSBezierPath *) bezierPathFromSubtree: (COSubtree *)subtree;

@end
