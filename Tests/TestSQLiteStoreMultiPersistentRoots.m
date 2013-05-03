#import "TestCommon.h"

@interface TestSQLiteStoreMultiPersistentRoots : COSQLiteStoreTestCase <UKTest>
{
    COPersistentRootState *docProot;
    COPersistentRootState *tagProot;
}
@end

@implementation TestSQLiteStoreMultiPersistentRoots

static COUUID *docUUID;
static COUUID *tagUUID;

+ (void) initialize
{
    if (self == [TestSQLiteStoreMultiPersistentRoots class])
    {
        docUUID = [[COUUID alloc] init];
        tagUUID = [[COUUID alloc] init];
    }
}

- (COItemTree *) tagItemTreeWithDocProoUUID: (COUUID*)aUUID
{
    COMutableItem *rootItem = [[[COMutableItem alloc] initWithUUID: tagUUID] autorelease];
    [rootItem setValue: @"favourites" forAttribute: @"name" type: kCOStringType];
    [rootItem setValue: S([COPath pathWithPersistentRoot: aUUID])
          forAttribute: @"taggedDocuments"
                  type: kCOPathType | kCOSetType];

    return [COItemTree treeWithItemsRootFirst: A(rootItem)];
}

- (COItemTree *) docItemTree
{
    COMutableItem *rootItem = [[[COMutableItem alloc] initWithUUID: tagUUID] autorelease];
    [rootItem setValue: @"my document" forAttribute: @"name" type: kCOStringType];
    
    return [COItemTree treeWithItemsRootFirst: A(rootItem)];
}

- (id) init
{
    SUPERINIT;
    
    ASSIGN(docProot, [store createPersistentRootWithInitialContents: [self docItemTree]
                                                         metadata: nil]);
    ASSIGN(tagProot, [store createPersistentRootWithInitialContents: [self tagItemTreeWithDocProoUUID: [docProot UUID]]
                                                         metadata: nil]);
    return self;
}

- (void) dealloc
{
    [tagProot release];
    [docProot release];
    [super dealloc];
}

- (void) testSearch
{
    NSArray *results = [store referencesToPersistentRoot: [docProot UUID]];
    
    COSearchResult *result = [results objectAtIndex: 0];
    UKObjectsEqual([[tagProot currentBranchState] currentRevisionID], [result revision]);
    UKObjectsEqual(tagUUID, [result embeddedObjectUUID]);
}

@end
