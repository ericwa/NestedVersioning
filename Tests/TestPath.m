#import "TestCommon.h"

@interface TestPath : NSObject <UKTest> {
	
}

@end

@implementation  TestPath

- (void) testPath
{
	COUUID *u1 = [COUUID UUIDWithString: @"cdf68e39-8f4b-4afa-9f81-ba2f7cdf50e6"];
	COUUID *u2 = [COUUID UUIDWithString: @"8a099b84-09eb-4a3e-828d-9a897778e5e3"];
	COUUID *u3 = [COUUID UUIDWithString: @"5764ce91-3061-4289-b7d8-7e9f4c1cd975"];
	
	NSString *pathStr = [NSString stringWithFormat: @"%@/%@", u1, u2];
	
	COPath *path = [[[COPath path]
					 pathByAppendingPathComponent: u1]
					pathByAppendingPathComponent:u2];
	
	UKStringsEqual(pathStr, [path stringValue]);
	
	UKObjectsEqual([COPath path], [COPath path]);
	UKStringsEqual(@"", [[COPath path] stringValue]);
	UKObjectsEqual([COPath path], [COPath pathWithString: @""]);
	
	UKObjectsEqual([[[COPath path]
					 pathByAppendingPathComponent: u1]
					pathByAppendingPathComponent:u2], path);
	
	UKObjectsEqual(u2, [path lastPathComponent]);
	UKObjectsEqual(u1, [[path pathByDeletingLastPathComponent] lastPathComponent]);
	UKNil([[[path pathByDeletingLastPathComponent] pathByDeletingLastPathComponent] lastPathComponent]);
	UKObjectsEqual([COPath path], [[path pathByDeletingLastPathComponent] pathByDeletingLastPathComponent]);
	
	UKObjectsEqual(path, [COPath pathWithString: pathStr]);
	
	// test pathToParent
	
	COPath *path2 = [[COPath path] pathByAppendingPathToParent];
	COPath *path3a = [path2 pathByAppendingPath: path2];
	COPath *path3b = [[[COPath path] pathByAppendingPathToParent] pathByAppendingPathToParent];
	COPath *path4 = [[[[COPath path] pathByAppendingPathToParent] pathByAppendingPathToParent] pathByAppendingPathComponent: u3];
	COPath *path5 = [[[COPath path] pathByAppendingPathToParent] pathByAppendingPathComponent: u3];
	
	UKObjectsEqual(path3b, path3a);
	
	UKTrue([path2 hasLeadingPathsToParent]);
	UKFalse([path2 isEmpty]);
	UKFalse([path2 hasComponents]);
	
	UKObjectsEqual([[COPath path] pathByAppendingPathComponent: u1], [path pathByAppendingPath: path2]);
	UKObjectsEqual([COPath path], [path pathByAppendingPath: path3a]);
	UKObjectsEqual([COPath path], [path pathByAppendingPath: path3b]);
	UKObjectsEqual([COPath pathWithPathComponent: u3], [path pathByAppendingPath: path4]);
	UKObjectsEqual([[COPath pathWithPathComponent: u1] pathByAppendingPathComponent: u3], [path pathByAppendingPath: path5]);	
}

@end
