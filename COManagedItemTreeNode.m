#import "COManagedItemTreeNode.h"
#import "COMacros.h"

@implementation COManagedItemTreeNode

- (id)initAsFaultWithUUID: (ETUUID*)aUUID
{
	NILARG_EXCEPTION_TEST(aUUID);
	SUPERINIT;
	ASSIGN(uuid, aUUID);
	valueForAttribute = nil;
	typeForAttribute = nil;
	return self;
}

@end
