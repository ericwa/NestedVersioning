#import <Foundation/Foundation.h>
#include <string.h>
#include "glibc_hack_unistd.h"

NSDictionary *ETGetOptionsDictionary(char *optString, int argc, char **argv)
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	NSNumber *True = [NSNumber numberWithBool: YES];
	NSNumber *False = [NSNumber numberWithBool: NO];

	for (char *opts = optString ; '\0' != *opts ; opts++)
	{
		// Initialise options to False.
		if ((*opts != ':') && (*(opts + 1) != ':' ))
		{
			unichar opt = (unichar)*opts;
			NSString *key = [NSString stringWithCharacters: &opt length: 1];
			[dict setObject: False
			         forKey: key];
		}
	}

	int ch;
	while ((ch = getopt(argc, argv, optString)) != -1)
	{
		if (ch == '?')
		{
			[NSException raise: @"InvalidOption"
			            format: @"Illegal argument %c", optopt];
		}
		unichar optchar = ch;
		NSString *key = [NSString stringWithCharacters: &optchar length: 1];
		char *opt = strchr(optString, (char)ch);
		if (*(opt+1) == ':')
		{
			id old = [dict objectForKey: key];
			if (nil != old)
			{
				if ([old isKindOfClass: [NSMutableArray class]])
				{
					[old addObject: [NSString stringWithUTF8String: optarg]];
				}
				else
				{
					old = [NSMutableArray arrayWithObjects: old, [NSString stringWithUTF8String: optarg], nil];
				}
				[dict setObject: old
				         forKey: key];
			}
			else
			{
				[dict setObject: [NSString stringWithUTF8String: optarg]
				         forKey: key];
			}
		}
		else
		{
			[dict setObject: True
			         forKey: key];
		}
	}

    NSMutableArray *nonOptionArgs = [NSMutableArray array];
    for (int i = optind; i < argc; i++)
    {
        [nonOptionArgs addObject: [NSString stringWithUTF8String: argv[i]]];
    }
    [dict setObject: [NSArray arrayWithArray: nonOptionArgs]
             forKey: @""];

	return dict;
}
