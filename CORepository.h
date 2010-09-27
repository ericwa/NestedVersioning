#import <Cocoa/Cocoa.h>

@protocol CORepositoryDelegate

@optional
- (void) store: (CORepository*)store willCommitChangeset: (COChangeset*)cs;
- (void) store: (CORepository*)store didCommitChangeset: (COChangeset*)cs;

@end


@interface CORepository : NSObject
{
  COStoreBackend *_backend;
  id<CORepositoryDelegate> _delegate;
}

+ (CORepository*)storeWithURL: (NSURL*)url;

- (id<CORepositoryDelegate>)delegate;
- (void)setDelegate: (id<CORepositoryDelegate>)aDelegate;



- (void)permanentlyDeleteObjectsWithUUIDs: (NSArray*)objects;

- (NSDictionary*) propertyListForObjectWithUUID: (ETUUID*)uuid atHistoryGraphNode: (COHistoryGraphNode *)node;


@end

@interface COStoreCoordinator (History)

- (ETUUID*) createChangesetWithParentChangesetIdentifiers:
                      objectUUIDToHashMappings: 
                              metadataPropertyList:
                              date:;
- (id)metadataForChangesetIdentifier:;
- (NSArray*)parentChangesetIdentifers:
- (NSArray*)childChangesetIdentifers:;
- (NSArray*)changesetsModifyingObjectsInSet:
              beforeDate:
              afterDate:;

@end