#import <Foundation/Foundation.h>
#import "COPath.h"
#import "COStoreItem.h"
#import "COStore.h"
#import "COItemPath.h"
#import "COEditingContext.h"

@interface COSimpleContext : NSObject <COEditingContext, NSCopying>
{
	COStore *store;
	
	/**
	 * this is the commit we load our data from.
	 */
	ETUUID *baseCommit;
	
	// -- in-memory mutable state which is "overlaid" on the 
	// persistent state represented by baseCommit
	
	NSMutableDictionary *insertedOrUpdatedItems;
	ETUUID *rootItemUUID;
}



@end
