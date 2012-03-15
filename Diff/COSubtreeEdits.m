#import "ETUUID.h"
#import "COMacros.h"
#import "COSubtreeEdits.h"



@implementation COSubtreeEdit

@synthesize UUID;
@synthesize attribute;
@synthesize sourceIdentifier;

- (void) dealloc
{
	[UUID release];
	[attribute release];
	[sourceIdentifier release];
	[super dealloc];
}

- (void) applyTo: (COMutableItem *)anItem
{
	[NSException raise: NSGenericException format: @"subclass should have overridden"];
}

@end


@implementation COStoreItemDiffOperationSetAttribute

- (id) initWithType: (COType*)aType
			  value: (id)aValue
{
	SUPERINIT;
	ASSIGN(value, aValue);
	ASSIGN(type, aType);
	return self;
}

- (id) copyWithZone: (NSZone *)aZone
{
	COStoreItemDiffOperationSetAttribute *result = [[[self class] alloc] initWithType: type value: value];
	return result;
}

- (void)dealloc
{
	[value release];
	[type release];
	[super dealloc];
}

- (void) applyTo: (COMutableItem *)anItem attribute: (NSString *)anAttribute
{
	[anItem setValue: value
		forAttribute: anAttribute
				type: type];
}

@end


@implementation COStoreItemDiffOperationDeleteAttribute

- (void) applyTo: (COMutableItem *)anItem attribute: (NSString *)anAttribute
{
	if (nil == [anItem valueForAttribute: anAttribute])
	{
		[NSException raise: NSInternalInconsistencyException
					format: @"expeted attribute %@ to be already set", anAttribute];
	}
	[anItem removeValueForAttribute: anAttribute];
}

@end


@implementation COSetDiff

@end



@implementation COSequenceEdit

@synthesize range;
@synthesize sourceIdentifier;

- (void) dealloc
{
	[sourceIdentifier release];
	[super dealloc];
}

- (NSComparisonResult) compare: (COSequenceEdit*)other
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

- (BOOL) isEqualIgnoringSourceIdentifier:(id)object
{
	[NSException raise: NSGenericException
				format: @"-[%@ %@] unimplemented", [self class], NSStringFromSelector(_cmd)];
	return NO;
}

- (id)copyWithZone:(NSZone *)zone
{
	return [self retain];
}

@end


@implementation COSequenceInsertion

@synthesize insertedObject;

+ (COSequenceInsertion*)insertionWithLocation: (NSUInteger)aLocation
							   insertedObject: (id)anObject
							 sourceIdentifier: (id)aSource
{
	COSequenceInsertion *result = [[COSequenceInsertion alloc] init];
	result->range = NSMakeRange(aLocation, 0);
	ASSIGN(result->insertedObject, anObject);
	ASSIGN(result->sourceIdentifier, aSource);
	return [result autorelease];
}

- (void) dealloc
{
	[insertedObject release];
	[super dealloc];
}

- (BOOL) isEqualIgnoringSourceIdentifier:(id)object
{
	return [object isKindOfClass: [self class]] && 
	[insertedObject isEqual: [object insertedObject]] &&
	NSEqualRanges(range, [object range]);
}

- (BOOL) isEqual:(id)object
{
	return [self isEqualIgnoringSourceIdentifier: object]
	&& [sourceIdentifier isEqual: [object sourceIdentifier]];
}

- (NSUInteger) hash
{
	return 16354992415397012214ULL ^ [insertedObject hash] ^ range.location ^ range.length ^ [sourceIdentifier hash];
}

@end



@implementation COSequenceDeletion

+ (COSequenceDeletion*)deletionWithRange: (NSRange)aRange
						sourceIdentifier: (id)aSource
{
	COSequenceDeletion *result = [[COSequenceDeletion alloc] init];
	result->range = aRange;
	ASSIGN(result->sourceIdentifier, aSource);
	return [result autorelease];
}

- (BOOL) isEqualIgnoringSourceIdentifier:(id)object
{
	return [object isKindOfClass: [self class]] && 
	NSEqualRanges(range, [object range]);
}

- (BOOL) isEqual:(id)object
{
	return [self isEqualIgnoringSourceIdentifier: object]
	&& [sourceIdentifier isEqual: [object sourceIdentifier]];
}

- (NSUInteger) hash
{
	return 15546910606417742031ULL ^ range.location ^ range.length ^ [sourceIdentifier hash];
}

@end




@implementation COSequenceModification

@synthesize insertedObject;

+ (COSequenceModification*)modificationWithRange: (NSRange)aRange
								  insertedObject: (id)anObject
								sourceIdentifier: (id)aSource
{
	COSequenceModification *result = [[COSequenceModification alloc] init];
	result->range = aRange;
	ASSIGN(result->insertedObject, anObject);
	ASSIGN(result->sourceIdentifier, aSource);
	return [result autorelease];
}

- (void) dealloc
{
	[insertedObject release];
	[super dealloc];
}

- (BOOL) isEqualIgnoringSourceIdentifier:(id)object
{
	return [object isKindOfClass: [self class]]
	&& [insertedObject isEqual: [object insertedObject]]
	&& NSEqualRanges(range, [object range]);
}

- (BOOL) isEqual:(id)object
{
	return [self isEqualIgnoringSourceIdentifier: object]
	&& [sourceIdentifier isEqual: [object sourceIdentifier]];
}

- (NSUInteger) hash
{
	return 13045144732696269143ULL ^ [insertedObject hash] ^ range.location ^ range.length ^ [sourceIdentifier hash];
}

@end
