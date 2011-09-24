#import <Foundation/Foundation.h>

@interface LogIndent : NSObject
{
}

+ (NSString *) indent: (unsigned int)i;
/**
 * Logs a dictionary on one line, in a condensed format
 */
+ (NSString *) logDictionary: (NSDictionary*)dict;

@end
