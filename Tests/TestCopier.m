#import "TestCommon.h"

@interface TestCopier : NSObject <UKTest>
{
    COItemGraph *initialGraph;
    COCopier *copier;
}
@end


@implementation TestCopier

static ETUUID *drawing;
static ETUUID *group1;
static ETUUID *shape1;
static ETUUID *style1;

static ETUUID *drawing2;

+ (void) initialize
{
    if (self == [TestCopier class])
    {
        drawing = [[ETUUID alloc] init];
        group1 = [[ETUUID alloc] init];
        shape1 = [[ETUUID alloc] init];
        style1 = [[ETUUID alloc] init];
        
        drawing2 = [[ETUUID alloc] init];
    }
}

- (id) init
{
    SUPERINIT;
    copier = [[COCopier alloc] init];
    
    COItem *drawingItem = [COMutableItem itemWithUUID: drawing];
    [drawingItem setValue: A(group1) forAttribute: @"contents" type: kCOArrayType | kCOCompositeReferenceType];
    
    COItem *group1Item = [COMutableItem itemWithUUID: group1];
    [group1Item setValue: A(shape1) forAttribute: @"contents" type: kCOArrayType | kCOCompositeReferenceType];
    
    COItem *shape1Item = [COMutableItem itemWithUUID: shape1];
    [shape1Item setValue: A(style1) forAttribute: @"styles" type: kCOArrayType | kCOReferenceType];
    
    COItem *style1Item = [COMutableItem itemWithUUID: style1];
    
    initialGraph = [[COItemGraph alloc] initWithItems: A(drawingItem, group1Item, shape1Item, style1Item)
                                        rootItemUUID: drawing];
    return self;
}

/**
 * ==> composite ref
 * --> ref
 *
 * before copy:
 *
 *     drawing ==> group1 ==> shape1 --> style1
 *
 * after copy:
 *
 *     drawing ==> group1 ==> shape1 --> style1 <-.
 *                                                |
 *              group1copy ==> shape1copy --------'
 *
 *
 * Ensures that when copying into the same context, objects referred to by non-composite references
 * are aliased, not copied.
 */
- (void) testCopyWithinContext
{
    UKIntsEqual(4, [[initialGraph itemUUIDs] count]);
    
    ETUUID *group1Copy = [copier copyItemWithUUID: group1
                                        fromGraph: initialGraph
                                          toGraph: initialGraph];
    
    UKIntsEqual(6, [[initialGraph itemUUIDs] count]);
    
    ETUUID *shape1Copy = [[[initialGraph itemForUUID: group1Copy] valueForAttribute: @"contents"] objectAtIndex: 0];
    ETUUID *shape1CopyStyle = [[[initialGraph itemForUUID: shape1Copy] valueForAttribute: @"styles"] objectAtIndex: 0];
    
    UKObjectsEqual(style1, shape1CopyStyle);
}

/**
 * ==> composite ref
 * --> ref
 *
 * before copy (source context):
 *
 *     drawing ==> group1 ==> shape1 --> style1
 *
 * before copy (dest. context):
 *
 *     drawing2 --> style1
 *
 * after copy (dest. context):
 *
 *     drawing2 --> style1 <-------.
 *                                 |
 *     group1copy ==> shape1copy --'
 *
 *
 * Ensures that copying into another context renames (assigns new UUIDs) the copied objects, even when 
 * not strictly needed. 
 */
- (void) testCopyToDifferentContext
{
    COItem *drawing2Item = [COMutableItem itemWithUUID: drawing2];
    [drawing2Item setValue: A(style1) forAttribute: @"styles" type: kCOArrayType | kCOReferenceType];
    COItem *style1Item = [COMutableItem itemWithUUID: style1];
    
    COItemGraph *drawing2Graph = [[COItemGraph alloc] initWithItems: A(drawing2Item, style1Item)
                                                     rootItemUUID: drawing2];
    
    UKIntsEqual(2, [[drawing2Graph itemUUIDs] count]);
    
    ETUUID *group1Copy = [copier copyItemWithUUID: group1
                                        fromGraph: initialGraph
                                          toGraph: drawing2Graph];
    
    UKIntsEqual(4, [[drawing2Graph itemUUIDs] count]);
    
    ETUUID *shape1Copy = [[[drawing2Graph itemForUUID: group1Copy] valueForAttribute: @"contents"] objectAtIndex: 0];
    ETUUID *shape1CopyStyle1 = [[[drawing2Graph itemForUUID: shape1Copy] valueForAttribute: @"styles"] objectAtIndex: 0];
    
    UKNotNil(shape1Copy);
    UKNotNil(shape1CopyStyle1);
    UKObjectsNotEqual(group1, group1Copy);
    UKObjectsNotEqual(shape1, shape1Copy);
    UKObjectsEqual(style1, shape1CopyStyle1);
}

@end
