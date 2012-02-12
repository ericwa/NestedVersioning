#import <EtoileFoundation/EtoileFoundation.h>
#import "COSequenceDiff.h"

@implementation COSequenceDiffOperation

@synthesize range;

- (NSComparisonResult) compare: (COSequenceDiffOperation*)other
{
	if ([other range].location > [self range].location)
	{
		return NSOrderedAscending;
	}
	if ([other range].location == [self range].location)
	{
		return NSOrderedSame;
	}
	else
	{
		return NSOrderedDescending;
	}
}

- (BOOL) overlaps: (COSequenceDiffOperation *)other
{
	NSRange r1 = [self range];
	NSRange r2 = [other range];
	return (r1.location >= r2.location && r1.location < (r2.location + r2.length) && r1.length > 0)
    || (r2.location >= r1.location && r2.location < (r1.location + r1.length) && r2.length > 0);
}

@end


@implementation COSequenceDiff

- (id) initWithOperations: (NSArray*)opers
{
	SUPERINIT;
	ops = [opers mutableCopy];
	return self;
}

- (NSArray *)operations
{
	return ops;
}

- (NSString*)description
{
	NSMutableString *output = [NSMutableString stringWithFormat: @"<%@ %p: ", NSStringFromClass([self class]), self];
	for (id op in [self operations])
	{
		[output appendFormat:@"\n\t%@,", op];
	}
	[output appendFormat:@"\n>"];  
	return output;
}

@end
