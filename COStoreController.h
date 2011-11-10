#import <Foundation/Foundation.h>
#import "COStore.h"
#import "COPath.h"



/**
 * a store api one level higher than COStore..
 * probably this will become the real COStore api once we switch to sqlite again


detailed specification of persistent root plist object:

-note that a persistent root contains its branches.
-copying a persistent root copies the branches, and should probably
give the root and branches new uuid's.
-note that you can refer to the branch directly without the parent root's uuid.

{
	"type" : "root"
	"name" : "the object's name"
	"uuid" : 0d7489b0-0a9d-11e1-be50-0800200c9a66
	
	"tracking-type" : "owned-branch" or "remote-root" or "remote-branch" or "version"
	"tracking" : one of the following:
		a) the uuid of one of the branches we own,
		b) or a path to another persistent root,
		c) or a path to a branch owned by another persistent root,
		d) or a specific version.
	
	"branches" : (
				  {
					  "type" : "branch"
					  "uuid" : "8a099b84-09eb-4a3e-828d-9a897778e5e3"
					  "owning-root-uuid" : 0d7489b0-0a9d-11e1-be50-0800200c9a66 // the uuid of the enclosing root
					  "name" : "whatever you want to call it"
					  "version" : version-uuid 
				  },
				  {
					  "type" : "branch"
					  "uuid" : "cdf68e39-8f4b-4afa-9f81-ba2f7cdf50e6"
					  "owning-root-uuid" : 0d7489b0-0a9d-11e1-be50-0800200c9a66 // the uuid of the enclosing root
					  "name" : "another branch"
					  "version" : version-uuid 
				  },
			)
	}
**/

@interface COStoreController : NSObject
{
	COStore *store;
}
- (id)initWithStore: (COStore*)aStore;

/** @taskunit reading */

/**
 * this is the core/primitive method for navigating a path.
 *
 * it needs to know how to navigate through the embedded objects
 * which represent persistent roots/branches.
 *
 * It returns the uuid of the current version which the path
 * points to.
 *
 * note that the logic for parsing persistent roots should be refactored.
 *
 * note that it is recursive.
 */
- (ETUUID*) currentVersionForPersistentRootAtPath: (COPath*)path;

/**
 * simple wrapper around -[COStore UUIDsAndPlistsForCommit:]
 */
- (id) plistForEmbeddedObject: (ETUUID*)embeddedObject
					 inCommit: (ETUUID*)aCommitUUID;

/** @taskunit writing */

/**
 * this is the primitive method for writing changes to the store.
 * the objects parameter should contain _all_ objects in the persistent
 * root (not just modified ones).
 *
 * it handles updating the chain of persistent roots/branches in a path.
 *
 * note that is is recursive.
 *
 */
- (void) writeUUIDsAndPlists: (NSDictionary*)objects // ETUUID : plist
	forPersistentRootAtPath: (COPath*)path
			    metadata: (id)metadataPlist;

@end
