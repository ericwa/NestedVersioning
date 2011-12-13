#import <Foundation/Foundation.h>
#import "COPersistentRootEditingContext.h"

@interface COPersistentRootEditingContext (Convenience)

- (void) insertValue: (id)aValue
	   primitiveType: (COType *)aPrimitiveType
	  inSetAttribute: (NSString*)anAttribute
			ofObject: (ETUUID*)aDest;

- (ETUUID *) insertTree: (COItemTreeNode*)aTree
			inContainer: (ETUUID*)aContainer;

@end
