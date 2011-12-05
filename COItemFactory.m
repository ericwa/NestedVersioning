#import "COItemFactory.h"
#import "Common.h"

@implementation COItemFactory

+ (COItemFactory *)factory
{
	static COItemFactory *factory;
	if (factory == nil)
	{
		factory = [[COItemFactory alloc] init];
	}
	return factory;
}

- (COStoreItemTree*) newFolder: (NSString*)aName
{
	NILARG_EXCEPTION_TEST(aName);
	
	COStoreItemTree *tree = [COStoreItemTree itemTree];
	[tree setValue: aName
	  forAttribute: @"name"
			  type: COPrimitiveType(kCOPrimitiveTypeString)];
	return tree;
}

- (COStoreItemTree*) newItem: (NSString*)aName
{
	return [self newFolder: aName];
}

@end
