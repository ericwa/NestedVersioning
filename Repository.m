#import "Repository.h"

@implementation Repository

@synthesize rootObject;

- (id)init
{
    self = [super init];
    if (self)
    {
    }
    return self;
}

+ (Repository*) repositoryWithVersionedObject: (VersionedObject*)obj
{
    Repository *repository = [[self alloc] init];
    repository.rootObject = obj;
    return [repository autorelease];
}

// debug

- (void)checkSanity
{
    [rootObject checkSanityWithOwner: nil];
}

@end
