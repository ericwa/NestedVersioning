#import "COItemFactory.h"
#import "COMacros.h"

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

- (COSubtree*) folder: (NSString*)aName
{
	NILARG_EXCEPTION_TEST(aName);
	
	COSubtree *tree = [COSubtree subtree];
	[tree setPrimitiveValue: aName
	  forAttribute: @"name"
			  type: [COType stringType]];
	return tree;
}

- (COSubtree*) item: (NSString*)aName
{
	return [self folder: aName];
}

@end
