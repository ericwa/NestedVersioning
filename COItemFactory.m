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

- (COItemTreeNode*) newFolder: (NSString*)aName
{
	NILARG_EXCEPTION_TEST(aName);
	
	COItemTreeNode *tree = [COItemTreeNode itemTree];
	[tree setValue: aName
	  forAttribute: @"name"
			  type: [COType stringType]];
	return tree;
}

- (COItemTreeNode*) newItem: (NSString*)aName
{
	return [self newFolder: aName];
}

@end
