#import "EmbeddedObject.h"

@implementation EmbeddedObject

@synthesize contents;
@synthesize metadata;

- (id)init
{
    self = [super init];
    if (self)
    {
    }    
    return self;
}

+ (EmbeddedObject *) objectWithContents: (NSArray*)contents
                               metadata: (NSDictionary*)metadata
{
    EmbeddedObject *obj = [[self alloc] init];
    obj.contents = contents;
    obj.metadata = metadata;
    
    // Check types and set parent pointers of objects in contents
    for (BaseObject *subObject in obj.contents)
    {
        if (![subObject isKindOfClass: [BaseObject class]])
        {
            [NSException raise: NSInvalidArgumentException
                        format: @"%@ not a BaseObject", subObject];
        }
        subObject.parent = obj;
    }
    
    return [obj autorelease];
}

- (id)copyWithZone:(NSZone *)zone;
{
    NSArray *newContents = [[contents copyWithZone: zone] autorelease];
    return [[EmbeddedObject objectWithContents: newContents // will update parent pointer of copied contents
                                      metadata: self.metadata] retain];
}

@end
