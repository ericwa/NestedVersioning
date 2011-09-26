#import "NamedBranch.h"

@implementation NamedBranch

@synthesize name;
@synthesize currentHistoryNodeIndex;

- (id)init
{
    self = [super init];
    if (self)
    {
    }    
    return self;
}

- (id) copyWithZone:(NSZone *)zone
{
    return [[[self class] namedBranchWithName: self.name
                      currentHistoryNodeIndex: self.currentHistoryNodeIndex] retain];
}

+ (NamedBranch*) namedBranchWithName: (NSString*)name
             currentHistoryNodeIndex: (NSUInteger)currentHistoryNodeIndex
{
    NamedBranch *obj = [[self alloc] init];
    obj.name = name;
    obj.currentHistoryNodeIndex = currentHistoryNodeIndex;
    return [obj autorelease];
}

// debug

- (NSString *) logWithIndent: (unsigned int)i
{
    NSMutableString *res = [NSMutableString string];
    [res appendFormat: @"%@{branch addr=%p name='%@' historynodeindex=%d}", [LogIndent indent: i], self, self.name, (int)self.currentHistoryNodeIndex];
    return res;        
}

@end
