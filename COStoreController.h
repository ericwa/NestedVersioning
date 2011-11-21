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
					  "tracking" : version-uuid 
					  "main-object" : embedded-object-uuid in the version we are tracking.
									  this is the embedded object that the persistent root is "wrapping" - 
									  this is the object you would export if you exported the current version, etc.
				  },
				  {
					  "type" : "branch"
					  "uuid" : "cdf68e39-8f4b-4afa-9f81-ba2f7cdf50e6"
					  "owning-root-uuid" : 0d7489b0-0a9d-11e1-be50-0800200c9a66 // the uuid of the enclosing root
					  "name" : "another branch"
					  "tracking" : version-uuid 
					 "main-object" : embedded-object-uuid in the version we are tracking.
									 this is the embedded object that the persistent root is "wrapping" - 
									 this is the object you would export if you exported the current version, etc.

				  },
			  )
}
 
how do we add undo/redo to this?
for branches/roots that track a specific version, they should also have 
a key/value called "tip". (terminology stolen from mercurial)
 
- every commit to that branch root should set both "tracking" and "tip"
  to the same value.

- to undo:
  a) look up the version that "tracking" points to
  b) get its parent (if it has none, can't undo)
  c) set "tracking" to the parent, without modifying tip
 
- to redo:
	X = "tip"
	if (X == "tracking") fail ("can't redo")
	while (1) {
      if (X.parent == "tracking") {
		"tracking" = X;
		finshed;
	  }
	  X = X.parent;
   }
 
**/

@interface COStoreController : NSObject
{
	COStore *store;
}
- (id)initWithStore: (COStore*)aStore;

/** @taskunit reading */

/**
 * converts a path to an "absolute path".
 
 a COPath can contain uuid's of roots that use any of the
 tracking types ("owned-branch" or "remote-root" or "remote-branch" or "version")
 
 however, roots with tracking types of "owned-branch" or "remote-root" or "remote-branch"
 are don't point directly to a version, but delegate that to another root/branch. this
 is analagous to a unix symlink.
 
 when committing or reading from the DB we want to convert a path which 
 may contain these "symlink" elements in it to a "real" path, i.e. one in which
 every path element is either a branch or a root with tracking type "version".
 that is an "absolute path"
 */
- (COPath *)absolutePathForPath: (COPath*)aPath;

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
 *
 * in the unix filesystem analogy this is like the "inode for path" method
 */
- (ETUUID*) currentVersionForPersistentRootAtPath: (COPath*)path;

/**
 * simple wrapper around -[COStore UUIDsAndPlistsForCommit:]
 */
- (id) storeItemForEmbeddedObject: (ETUUID*)embeddedObject
					 inCommit: (ETUUID*)aCommitUUID;

/**
 * simple wrapper around -currentVersionForPersistentRootAtPath:
 * and -plistForEmbeddedObject:inCommit:
 */
- (id) plistForEmbeddedObject: (ETUUID*)embeddedObject
				 atPath: (COPath*)aPath;

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
