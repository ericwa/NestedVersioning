#import <Foundation/Foundation.h>
#import "Common.h"

/**
 * Will be inside an UndoNode
 */
@interface NamedBranch : BaseObject
{
    
    NSString *name;

    NSUInteger currentHistoryNodeIndex;
}

@property (readwrite, nonatomic, copy) NSString *name;
@property (readwrite, nonatomic, assign) NSUInteger currentHistoryNodeIndex;

- (id) copyWithZone:(NSZone *)zone;
+ (NamedBranch*) namedBranchWithName: (NSString*)name
             currentHistoryNodeIndex: (NSUInteger)currentHistoryNodeIndex;

@end
