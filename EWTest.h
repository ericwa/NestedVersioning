#import <Foundation/Foundation.h>

// Private

void EWTestEqualFunction(id expected, id actual, const char *filename, int line);
void EWTestIntsEqualFunction(NSInteger expected, NSInteger actual, const char *filename, int line);
void EWTestTrueFunction(BOOL flag, const char *filename, int line);

// Public

void EWTestLog();

#define EWTestEqual(expected, actual) EWTestEqualFunction(expected, actual, __FILE__, __LINE__)
#define EWTestIntsEqual(expected, actual) EWTestIntsEqualFunction(expected, actual, __FILE__, __LINE__)
#define EWTestTrue(flag) EWTestTrueFunction(flag, __FILE__, __LINE__)
