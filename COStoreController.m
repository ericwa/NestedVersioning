#import "COStoreController.h"
#import "Common.h"

@implementation COStoreController

- (id)initWithStore:(COStore *)aStore
{
	SUPERINIT;
	ASSIGN(store, aStore);
	return self;
}

@end
