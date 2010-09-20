#import <EtoileFoundation/ETUUID.h>
#import "COHistoryGraphNode.h"
#import "COObjectGraphDiff.h"
#import "COStoreBackend.h"


@protocol COStoreDelegate

@optional
- (void) store: (COStoreCoordinator*)store willCommitChangeset: (COChangeset*)cs;
- (void) store: (COStoreCoordinator*)store didCommitChangeset: (COChangeset*)cs;

@end


@interface COStore : NSObject
{
  COStoreBackend *_backend;
  id<COStoreDelegate> _delegate;
}

+ (COStore*)storeWithURL: (NSURL*)url;

- (id<COStoreDelegate>)delegate;
- (void)setDelegate: (id<COStoreDelegate>)aDelegate;



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
