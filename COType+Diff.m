#import "COType+Diff.h"
#import "COType+String.h"
#import "COTypePrivate.h"
#import "ETUUID.h"
#import "COPath.h"
#import "COArrayDiff.h"
#import "COSetDiff.h"
#import "COMacros.h"

@interface COPrimitiveValueDiff : NSObject <COValueDiff>
{
	id newValue;
}
+ (COPrimitiveValueDiff *) diffBySettingValue: (id)newValue;
@end

@implementation COPrimitiveValueDiff

+ (COPrimitiveValueDiff *) diffBySettingValue: (id)newValue
{
	COPrimitiveValueDiff *diff = [[self alloc] init];
	ASSIGN(diff->newValue, newValue);
	return diff;
}

- (void) dealloc
{
	[newValue release];
	[super dealloc];
}

- (id) valueWithDiffAppliedToValue: (id)aValue
{
	return newValue;
}

@end





@interface COPrimitiveType (Diff)
@end

@interface COMultivaluedType (Diff)
@end


@implementation COPrimitiveType (Diff)

- (id <COValueDiff>) diffValue: (id)valueA withValue: (id)valueB
{
	// Primitive types are treated atomically
	return [COPrimitiveValueDiff diffBySettingValue: valueB];
}

@end


@implementation COMultivaluedType (Diff)

- (id <COValueDiff>) diffValue: (id)valueA withValue: (id)valueB
{
	// FIXME :Source identifier?
	if ([self isOrdered])
	{
		return [[[COArrayDiff alloc] initWithFirstArray: valueA
											secondArray: valueB
									   sourceIdentifier: @"FIXME: x"] autorelease];
	}
	else
	{
		return [[[COSetDiff alloc] initWithFirstSet: valueA
										  secondSet: valueB
								   sourceIdentifier: @"FIXME: y"] autorelease];
	}
}

@end