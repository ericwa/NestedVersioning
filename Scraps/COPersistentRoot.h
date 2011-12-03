#import <Foundation/Foundation.h>

/**
 detailed specification of persistent root plist object:
 
 -note that a persistent root contains its branches.
 -copying a persistent root copies the branches, and should probably
  give the root and branches new uuid's.
 -note that you can refer to the branch directly without the parent root's uuid.
 
 {
 "type" : "root"
 "name" : "the object's name"
 "uuid" : 0d7489b0-0a9d-11e1-be50-0800200c9a66
 
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
 

 */
 
 
@interface COPersistentRoot : NSObject

@end
