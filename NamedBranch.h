#import <Foundation/Foundation.h>
#import "Common.h"

@interface NamedBranch : BaseObject
{
    // parent (inherited from BaseObject) is an UndoNode
    
    NSString *name;

    NSUInteger currentHistoryNodeIndex;
}

@property (readwrite, nonatomic, copy) NSString *name;
@property (readwrite, nonatomic, assign) NSUInteger currentHistoryNodeIndex;

- (id) copyWithZone:(NSZone *)zone;
+ (NamedBranch*) namedBranchWithName: (NSString*)name
             currentHistoryNodeIndex: (NSUInteger)currentHistoryNodeIndex;

@end
