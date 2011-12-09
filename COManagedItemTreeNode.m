#import "COManagedItemTreeNode.h"
#import "COMacros.h"

@implementation COManagedItemTreeNode

- (id)initAsFaultWithUUID: (ETUUID*)aUUID
				  manager: (COItemTreeManager *)aManager
{
	NILARG_EXCEPTION_TEST(aUUID);
	SUPERINIT;
	ASSIGN(uuid, aUUID);
	valueForAttribute = nil;
	typeForAttribute = nil;
	manager = aManager; // Weak reference
	return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (BOOL) isFault
{
	return valueForAttribute == nil;
}

- (void) unfault
{
	DESTROY(valueForAttribute);
	DESTROY(typeForAttribute);
	
	valueForAttribute = [[NSMutableDictionary alloc] init];
	typeForAttribute = [[NSMutableDictionary alloc] init];
	
	
}

@end
