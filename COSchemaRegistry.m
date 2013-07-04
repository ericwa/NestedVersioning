#import "COSchemaRegistry.h"

#import <EtoileFoundation/Macros.h>
#import "COSchemaTemplate.h"
#import "COSchema.h"

@implementation COSchemaRegistry

- (id) init
{
    SUPERINIT;
    schemas_ = [[NSMutableDictionary alloc] init];
    return self;
}

+ (COSchemaRegistry *) registry
{
    return [[[self alloc] init] autorelease];
}

- (void) dealloc
{
    [schemas_ release];
    [super dealloc];
}

- (void) addSchema: (COSchemaTemplate*)aSchemaTemplate
{
    COSchema *schema = [[[COSchema alloc] initWithSchemaTemplate: aSchemaTemplate
                                                        registry: self] autorelease];
    // TODO: Check for cycles
    
    [schemas_ setObject: schema
                 forKey: [aSchemaTemplate name]];
}

- (COSchemaTemplate *) schemaForName: (NSString *)aName
{
    return [schemas_ objectForKey: aName];
}

@end
