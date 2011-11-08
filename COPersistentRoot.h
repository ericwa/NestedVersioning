#import <Foundation/Foundation.h>

/**
 detailed specification of persistent root plist object:
 
 "type" : "root" - 
        : "branch" - determines how it is treated by the UI.
 
 "parent-root" : "uuid-path" - if we are a branch, this is the proot
                          we belong to. (we were copied from).
 
 "version" : version-uuid ?
  
 "tracking-dest" : uuid-path ?  - if we are a branch, we should have a version.
								if we are a normal proot, we can either point directly to a version, 
								or give a uuid path to another proot (which can
								either be a branch or a root type of proot)
 
 */
 
 
@interface COPersistentRoot : NSObject

@end
