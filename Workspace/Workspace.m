#import "Workspace.h"

@implementation Workspace

@synthesize name;

-(id)init
{
    self = [super init];
    NSLog(@"Created Workspace");
    self.name = @"Example name";
    return self;
}

@end
