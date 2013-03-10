#import "COSchema.h"
#import "COSchemaRegistry.h"
#import "COSchemaTemplate.h"
#import "COType.h"
#import "COMacros.h"

@implementation COSchema

@synthesize name = name_;

- (id) initWithSchemaTemplate: (COSchemaTemplate *)aTemplate
                     registry: (COSchemaRegistry *)aRegistry
{
    SUPERINIT;
    name_ = [[aTemplate name] copy];
    parent_ = [[aTemplate parent] copy];
    typeForAttribute_ = [[NSMutableDictionary alloc] initWithDictionary: [aTemplate typeForAttribute]];
    schemaNameForAttribute_ = [[NSMutableDictionary alloc] initWithDictionary: [aTemplate schemaNameForAttribute]];
    parentRegistry_ = aRegistry;
    return self;
}
- (void) dealloc
{
    [name_ release];
    [parent_ release];
    [typeForAttribute_ release];
    [schemaNameForAttribute_ release];
    [super dealloc];
}
- (COSchema *) parent
{
    return [parentRegistry_ schemaForName: parent_];
}
- (NSSet *) propertyNames
{
    NSMutableSet *result;
    if (parent_ == nil)
    {
        result = [NSMutableSet set];
    }
    else
    {
        result = [NSMutableSet setWithSet: [[self parent] propertyNames]];
    }
    [result addObjectsFromArray: [typeForAttribute_ allKeys]];
    return [NSSet setWithSet: result];
}
- (COType *) typeForProperty: (NSString *)aProperty
{
    return [typeForAttribute_ objectForKey: aProperty];
}
- (COSchema *) schemaForProperty: (NSString *)aProperty
{
    return [parentRegistry_ schemaForName: [schemaNameForAttribute_ objectForKey: aProperty]];
}

@end
