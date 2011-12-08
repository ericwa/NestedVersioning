#import "COManagedItemTreeNode.h"
#import "Common.h"

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
