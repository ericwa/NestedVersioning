#import "LogIndent.h"

@implementation LogIndent

+ (NSString *) indent: (unsigned int)i
{
    unichar c[4*i];
    for (unsigned j=0; j<(4*i); j++)
    {
        c[j] = ' ';
    }
    return [[[NSString alloc] initWithCharacters: c length: (4*i)] autorelease];
}

+ (NSString *) logDictionary: (NSDictionary*)dict;
{
    NSMutableString *res = [NSMutableString string];
    [res appendFormat: @"{"];
    
    NSArray *keys = [dict allKeys];
    for (NSUInteger i=0; i<[keys count]; i++)
    {
        [res appendFormat: @"%@='%@'", [keys objectAtIndex:i],
            [dict objectForKey: [keys objectAtIndex:i]]];
        
        if (i < [keys count] - 1)
        {
            [res appendFormat: @", "];
        }
    }
    [res appendFormat: @"}"];    
    return res;   
}

+ (NSString *) logIndexSet: (NSIndexSet*)set
{
    NSMutableString *res = [NSMutableString string];
    [res appendFormat: @"<"];
    BOOL needsComma = NO;
    for (NSUInteger index = [set firstIndex]; index != NSNotFound; index = [set indexGreaterThanIndex: index])
    {
        if (needsComma)
            [res appendFormat: @","]; 
        [res appendFormat: @"%d", (int)index]; 
        needsComma = YES;
    }
    [res appendFormat: @">"];    
    return res;   
}

@end
