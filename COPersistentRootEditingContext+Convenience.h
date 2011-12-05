#import <Foundation/Foundation.h>
#import "COPersistentRootEditingContext.h"

@interface COPersistentRootEditingContext (Convenience)

- (void) insertValue: (id)aValue
	   primitiveType: (NSString*)aPrimitiveType
	  inSetAttribute: (NSString*)anAttribute
			ofObject: (ETUUID*)aDest;

- (ETUUID *) insertTree: (COStoreItemTree*)aTree
			inContainer: (ETUUID*)aContainer;

@end
