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
    obj.contents = [NSMutableArray arrayWithArray: contents];
    obj.metadata = metadata;
    
    // Check types and set parent pointers of objects in contents
    for (BaseObject *subObject in obj.contents)
    {
        if (![subObject isKindOfClass: [BaseObject class]])
        {
            [NSException raise: NSInvalidArgumentException
                        format: @"%@ not a BaseObject", subObject];
        }
    }
    
    return [obj autorelease];
}

- (id)copyWithZone:(NSZone *)zone;
{
    NSArray *newContents = [[contents copyWithZone: zone] autorelease];
    return [[EmbeddedObject objectWithContents: newContents // will update parent pointer of copied contents
                                      metadata: self.metadata] retain];
}

- (NSString *) logWithIndent: (unsigned int)i
{
    NSMutableString *res = [NSMutableString string];
    [res appendFormat: @"%@{embedded addr=%p metadata=%@\n", [LogIndent indent: i], self, [LogIndent logDictionary: self.metadata]];
    for (BaseObject *obj in self.contents)
    {
        [res appendFormat: @"%@\n", [obj logWithIndent: i+1]];
    }
    [res appendFormat: @"%@}", [LogIndent indent: i]];
    return res;        
}

- (void) checkSanityWithOwner: (BaseObject*)owner
{
    for (BaseObject *obj in contents)
    {
        [obj checkSanityWithOwner: self];
    }
}

@end
