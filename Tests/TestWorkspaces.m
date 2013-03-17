#import "TestCommon.h"


@interface TestWorkspaces : NSObject <UKTest> {
	
}

@end


@implementation TestWorkspaces

- (void)testSchemaless
{
    COEditingContext *ctx = [COEditingContext editingContext];
    COObject *o1 = [ctx insertObject];
    COObject *o2 = [ctx insertObject];
    COObject *o3 = [ctx insertObject];
    COObject *o4 = [ctx insertObject];
    
    [o1 setValue: S(o2, o3) forAttribute: @"embeddedGroups" type: [[COType embeddedItemType] setType]];
    [o2 setValue: S(o4) forAttribute: @"contents" type: [[COType referenceType] setType]];
    [o3 setValue: S(o4) forAttribute: @"contents" type: [[COType referenceType] setType]];
    
    UKRaisesException([ctx itemTree]);
    
    [ctx setRootObject: o1];
    
    UKIntsEqual(4, [[[ctx itemTree] itemUUIDs] count]);
    
    // Try changing the root
    
    COObject *t1 = [ctx insertObject];
    [ctx setRootObject: t1];
    [t1 setValue: S(o1) forAttribute: @"embeddedGroups" type: [[COType embeddedItemType] setType]];

    UKIntsEqual(5, [[[ctx itemTree] itemUUIDs] count]);
}

- (COSchemaRegistry *) workspaceSchemaRegistry
{
    COSchemaRegistry *reg = [COSchemaRegistry registry];
    
    COSchemaTemplate *namedObjectSchema = [COSchemaTemplate schemaWithName: @"NamedObject"];
    [namedObjectSchema setType: [COType stringType] forProperty: @"name"];
    [reg addSchema: namedObjectSchema];
    
    COSchemaTemplate *groupSchema = [COSchemaTemplate schemaWithName: @"Group"];
    [groupSchema setParent: @"NamedObject"];
    [groupSchema setType: [[COType embeddedItemType] setType]
              schemaName: @"Group"
             forProperty: @"embeddedGroups"];
    [groupSchema setType: [[COType referenceType] setType]
             forProperty: @"contents"];
    [reg addSchema: groupSchema];

    return reg;
}

- (void)testWithSchema
{
    COSchemaRegistry *reg = [self workspaceSchemaRegistry];
    
    COEditingContext *ctx = [COEditingContext editingContextWithSchemaRegistry: reg];
    
    COObject *o1 = [ctx insertObjectWithSchemaName: @"Group"];
    COObject *o2 = [ctx insertObjectWithSchemaName: @"Group"];
    COObject *o3 = [ctx insertObjectWithSchemaName: @"Group"];
    COObject *o4 = [ctx insertObject];
    
    UKTrue([S(@"name", @"contents", @"embeddedGroups") isSubsetOfSet: [o1 attributeNames]]);
    
    [o1 setValue: S(o2, o3) forAttribute: @"embeddedGroups"];
    [o2 setValue: S(o4) forAttribute: @"contents"];
    [o3 setValue: S(o4) forAttribute: @"contents"];
    
    UKObjectsEqual(S(o4), [o2 valueForAttribute: @"contents"]);
    UKObjectsEqual(S(o4), [o3 valueForAttribute: @"contents"]);
    
    UKRaisesException([ctx itemTree]);
    
    [ctx setRootObject: o1];
    
    UKIntsEqual(4, [[[ctx itemTree] itemUUIDs] count]);
}

@end
