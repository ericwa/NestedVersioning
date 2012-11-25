#import "TestCommon.h"

COSQLiteStore *setupStore()
{
	[[NSFileManager defaultManager] removeItemAtPath: STOREPATH error: NULL];
	return [[COSQLiteStore alloc] initWithURL: [NSURL fileURLWithPath: STOREPATH]];
}