#include "EWTest.h"

static unsigned int passes, fails;

void EWTestEqualFunction(id expected, id actual, const char *filename, int line)
{
    if ((expected == nil && actual != nil) ||
        (expected != nil && ![expected isEqual: actual]))        
    {
        fails++;
        NSLog(@"%s:%d: EWTestEqual expected %@, got %@", filename, line, expected, actual);
    }
    else
        passes++;
}

void EWTestIntsEqualFunction(NSInteger expected, NSInteger actual, const char *filename, int line)
{
    if (expected != actual)   
    {
        fails++;
        NSLog(@"%s:%d: EWTestIntsEqual expected %d, got %d", filename, line, (int)expected, (int)actual);
    }
    else
        passes++;
}

void EWTestTrueFunction(BOOL flag, const char *filename, int line)
{
    if (!flag)   
    {
        fails++;
        NSLog(@"%s:%d: EWTestTrue expected YES got NO", filename, line);
    }
    else
        passes++;
}

void EWTestLog()
{
    NSLog(@"%u/%u passed", passes, passes + fails);
}