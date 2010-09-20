#import <EtoileFoundation/EtoileFoundation.h>
#import "COHistoryGraphNode.h"
#import "COObjectGraphDiff.h"
#import "COStoreBackend.h"

@class COHistoryGraphNode;
@class COObjectGraphDiff;
@class COObjectContext;

@protocol COStoreDelegate

@optional
- (void) store: (COStoreCoordinator*)store didCommitChangeset: (COHistoryGraphNode*)node;

@end



/**
 * High-level interface to the storage layer. Creates and manages HistoryGraphNodes.
 */
@interface COStoreCoordinator : NSObject
{
  COStoreBackend *_store;
  NSMutableDictionary *_historyGraphNodes;
  id<COStoreDelegate> _delegate;
}

- (id<COStoreDelegate>)delegate;
- (void)setDelegate: (id<COStoreDelegate>)aDelegate;

- (id)initWithURL: (NSURL*)url;


- (void)permanentlyDeleteObjectsWithUUIDs: (NSArray*)objects;

- (NSDictionary*) propertyListForObjectWithUUID: (ETUUID*)uuid atHistoryGraphNode: (COHistoryGraphNode *)node;


@end

@interface COStoreCoordinator (History)

// URL here is the path at which the object is serialized.

- (ETUUID *) UUIDForURL: (NSURL *)url; // read it in the info.plist of the bundle
- (NSURL *) URLForUUID: (ETUUID *)uuid; // lookup in the db
- (void) setURL: (NSURL *)url forUUID: (ETUUID *)uuid;
- (void) setURL: (NSURL *)url forUUID: (ETUUID *)uuid
	withObjectVersion: (int)objectVersion 
	             type: (NSString *)objectType 
	          isGroup: (BOOL)isGroup
	        timestamp: (NSDate *)recordTimestamp
	    inContextUUID: (ETUUID *)contextUUID;
- (void) removeURLForUUID: (ETUUID *)uuid;
- (void) updateUUID: (ETUUID *)uuid 
    toObjectVersion: (int)objectVersion
          timestamp: (NSDate *)recordTimestamp;
- (int) objectVersionForUUID: (ETUUID *)anUUID;
- (NSDictionary *) faultDescriptionForUUID: (ETUUID *)aUUID;

- (NSURL *) storeURL;
- (NSMutableDictionary *) configurationDictionary;
// TODO: Should we support exporting the metadata DB as a plist?
//- (NSDictionary *) propertyList;

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



/**
 * Interface used in the implementation of COObject/COObjectContext
 */
@interface COStoreCoordinator (Private)


- (COHistoryGraphNode *) historyGraphNodeForUUID: (ETUUID*)uuid;
- (void) commitHistoryGraphNode: (COHistoryGraphNode *)node;

@end