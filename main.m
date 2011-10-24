#import <Foundation/Foundation.h>
#import "EWTest.h"

int main (int argc, const char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    EWTestLog();
    
    [pool drain];
    return 0;
}

