#import <Foundation/Foundation.h>
#import <EtoileFoundation/ETUUID.h>
#import "COSQLiteStore.h"

NSString *kCOIsUndo;
NSString *kCOSelector;
NSString *kCOUndoSelector;


NSString *kCOPersistentRootUUID;
NSString *kCOBranchUUID;

NSString *kCONewMetadata;
NSString *kCOOldMetadata;

NSString *kCOOldBranch;
NSString *kCONewBranch;

NSString *kCOOldCurrentRev;
NSString *kCONewCurrentRev;
NSString *kCOOldHeadRev;
NSString *kCONewHeadRev;
NSString *kCOOldTailRev;
NSString *kCONewTailRev;



@interface COStoreStructureEdit : NSObject
//{
//    BOOL isUndo_;
//    SEL selector_;
//    SEL undoSelector_;
//    
//    COUUID *persistentRootUUID;
//    COUUID *branchUUID;
//    
//    NSDictionary *newMetadata;
//    NSDictionary *oldMetadata;
//    
//    COUUID *oldBranch;
//    COUUID *newBranch;
//    
//    CORevisionID *oldCurrentRev;
//    CORevisionID *newCurrentRev;
//    CORevisionID *oldHeadRev;
//    CORevisionID *newHeadRev;
//    CORevisionID *oldTailRev;
//    CORevisionID *newTailRev;
//    
//}
+ (COStoreStructureEdit *)undoCreatePersistentRoot: (ETUUID*)aUUID;

@end

@implementation COStoreStructureEdit

- (NSDictionary *) inverseFromMetadata: (NSDictionary *)metadata
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary: metadata];
    [dict setObject: [NSNumber numberWithBool: ![[metadata objectForKey: kCOIsUndo] boolValue]]
             forKey: kCOIsUndo];
    return dict;
}

- (void) performEditFromMetadata: (NSDictionary *)metadata
                           store: (COSQLiteStore *)aStore
{
    SEL selector = [[metadata objectForKey: kCOIsUndo] boolValue] ?
        NSSelectorFromString([metadata objectForKey: kCOUndoSelector]) :
        NSSelectorFromString([metadata objectForKey: kCOSelector]);
 
    [self performSelector: selector
               withObject: metadata
               withObject: aStore];
}

- (BOOL)setMainBranchFromMetadata: (NSDictionary *)metadata
                            store: (COSQLiteStore *)aStore
{
    return [aStore setMainBranch: [metadata objectForKey: kCONewBranch]
               forPersistentRoot: [metadata objectForKey: kCOPersistentRootUUID]];
}

- (BOOL)undoSetMainBranchFromMetadata: (NSDictionary *)metadata
                                store: (COSQLiteStore *)aStore
{
    return [aStore setMainBranch: [metadata objectForKey: kCOOldBranch]
               forPersistentRoot: [metadata objectForKey: kCOPersistentRootUUID]];
}

- (BOOL)setCurrentBranchFromMetadata: (NSDictionary *)metadata
                               store: (COSQLiteStore *)aStore
{
    return [aStore setCurrentBranch: [metadata objectForKey: kCONewBranch]
                  forPersistentRoot: [metadata objectForKey: kCOPersistentRootUUID]];
}

- (BOOL)undoSetCurrentBranchFromMetadata: (NSDictionary *)metadata
                                   store: (COSQLiteStore *)aStore
{
    return [aStore setCurrentBranch: [metadata objectForKey: kCOOldBranch]
                  forPersistentRoot: [metadata objectForKey: kCOPersistentRootUUID]];
}


- (BOOL)setRevisionsFromMetadata: (NSDictionary *)metadata
                           store: (COSQLiteStore *)aStore
{
    return [aStore setCurrentRevision: [metadata objectForKey: kCONewCurrentRev]
                         headRevision: [metadata objectForKey: kCONewHeadRev]
                         tailRevision: [metadata objectForKey: kCONewTailRev]
                            forBranch: [metadata objectForKey: kCOBranchUUID]
                     ofPersistentRoot: [metadata objectForKey: kCOPersistentRootUUID]];
}

- (BOOL)undoSetRevisionsFromMetadata: (NSDictionary *)metadata
                               store: (COSQLiteStore *)aStore
{
    return [aStore setCurrentRevision: [metadata objectForKey: kCOOldCurrentRev]
                         headRevision: [metadata objectForKey: kCOOldHeadRev]
                         tailRevision: [metadata objectForKey: kCOOldTailRev]
                            forBranch: [metadata objectForKey: kCOBranchUUID]
                     ofPersistentRoot: [metadata objectForKey: kCOPersistentRootUUID]];
}

- (BOOL)setPersistentRootMetadataFromMetadata: (NSDictionary *)metadata
                                        store: (COSQLiteStore *)aStore
{
    return [aStore setMetadata: [metadata objectForKey: kCONewMetadata]
             forPersistentRoot: [metadata objectForKey: kCOPersistentRootUUID]];
}

- (BOOL)undoSetPersistentRootMetadataFromMetadata: (NSDictionary *)metadata
                                            store: (COSQLiteStore *)aStore
{
    return [aStore setMetadata: [metadata objectForKey: kCOOldMetadata]
             forPersistentRoot: [metadata objectForKey: kCOPersistentRootUUID]];
}


- (BOOL)setBranchMetadataFromMetadata: (NSDictionary *)metadata
                                store: (COSQLiteStore *)aStore
{
    return [aStore setMetadata: [metadata objectForKey: kCONewMetadata]
                     forBranch: [metadata objectForKey: kCOBranchUUID]
              ofPersistentRoot: [metadata objectForKey: kCOPersistentRootUUID]];
}

- (BOOL)undoSetBranchMetadataFromMetadata: (NSDictionary *)metadata
                                    store: (COSQLiteStore *)aStore
{
    return [aStore setMetadata: [metadata objectForKey: kCOOldMetadata]
                     forBranch: [metadata objectForKey: kCOBranchUUID]
              ofPersistentRoot: [metadata objectForKey: kCOPersistentRootUUID]];
}

- (BOOL)deletePersistentRootFromMetadata: (NSDictionary *)metadata
                                   store: (COSQLiteStore *)aStore
{
    return [aStore deletePersistentRoot: [metadata objectForKey: kCOPersistentRootUUID]];
}

- (BOOL)undoDeletePersistentRootFromMetadata: (NSDictionary *)metadata
                                       store: (COSQLiteStore *)aStore
{
    return [aStore undeletePersistentRoot: [metadata objectForKey: kCOPersistentRootUUID]];
}

- (BOOL)deleteBranchFromMetadata: (NSDictionary *)metadata
                           store: (COSQLiteStore *)aStore
{
    return [aStore deleteBranch: [metadata objectForKey: kCOBranchUUID]
               ofPersistentRoot: [metadata objectForKey: kCOPersistentRootUUID]];
}

- (BOOL)undoDeleteBranchFromMetadata: (NSDictionary *)metadata
                               store: (COSQLiteStore *)aStore
{
    return [aStore undeleteBranch: [metadata objectForKey: kCOBranchUUID]
                 ofPersistentRoot: [metadata objectForKey: kCOPersistentRootUUID]];
}

@end

@interface COUndoController : NSObject

@end
