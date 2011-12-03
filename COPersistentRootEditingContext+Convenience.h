#import <Foundation/Foundation.h>
#import "COPersistentRootEditingContext.h"

@interface COPersistentRootEditingContext (Convenience)

- (void) insertValue: (id)aValue
	   primitiveType: (NSString*)aPrimitiveType
	  inSetAttribute: (NSString*)anAttribute
			ofObject: (ETUUID*)aDest;

@end
