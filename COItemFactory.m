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

- (COItemTreeNode*) folder: (NSString*)aName
{
	NILARG_EXCEPTION_TEST(aName);
	
	COItemTreeNode *tree = [COItemTreeNode itemTree];
	[tree setValue: aName
	  forAttribute: @"name"
			  type: [COType stringType]];
	return tree;
}

- (COItemTreeNode*) item: (NSString*)aName
{
	return [self folder: aName];
}

@end
