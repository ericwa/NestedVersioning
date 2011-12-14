#import "COStoreItemProvider.h"
#import "COMacros.h"
#import "COStorePrivate.h"

@implementation COStoreItemProvider

- (id) initWithStore: (COStore*)aStore
			  commit: (ETUUID*)aCommit
{
	NILARG_EXCEPTION_TEST(aStore);
	NILARG_EXCEPTION_TEST(aCommit);
	
	SUPERINIT;
	ASSIGN(store, aStore);
	ASSIGN(commit, aCommit);
	return self;
}

+ (COStoreItemProvider *) itemProviderWithStore: (COStore*)aStore
										 commit: (ETUUID*)aCommit
{
	return [[[self alloc] initWithStore: aStore commit: aCommit] autorelease];
}

- (COItem*) itemForUUID: (ETUUID *)aUUID
{
	return [store storeItemForEmbeddedObject: aUUID
									inCommit: commit];
}

@end
