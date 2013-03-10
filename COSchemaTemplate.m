#import "COSchemaTemplate.h"
#import "COType.h"
#import "COMacros.h"

@implementation COSchemaTemplate

@synthesize name = name_;
@synthesize parent = parent_;
@synthesize typeForAttribute = typeForAttribute_;
@synthesize schemaNameForAttribute = schemaNameForAttribute_;

- (id) initWithName: (NSString *)aName
{
    SUPERINIT;
    ASSIGN(name_, aName);
    typeForAttribute_ = [[NSMutableDictionary alloc] init];
    schemaNameForAttribute_ = [[NSMutableDictionary alloc] init];
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

+ (COSchemaTemplate *) schemaWithName: (NSString *) aName
{
    return [[[self alloc] initWithName: aName] autorelease];
}

- (void) setType: (COType *)aType
      schemaName: (NSString *)aSchema
     forProperty: (NSString *)aProperty
{
    NSParameterAssert(([[aType primitiveType] isEqual: [COType embeddedItemType]]
                       || [[aType primitiveType] isEqual: [COType referenceType]]));
    [typeForAttribute_ setObject: aType forKey: aProperty];
    [schemaNameForAttribute_ setObject: [NSString stringWithString: aSchema] forKey: aProperty];
}

- (void) setType: (COType *)aType
     forProperty: (NSString *)aProperty
{
    [typeForAttribute_ setObject: aType forKey: aProperty];    
}

@end
