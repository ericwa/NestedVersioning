#import "ETUUID.h"
#import "COMacros.h"
#import "COSubtreeEdits.h"


#pragma mark base class

@implementation COSubtreeEdit

@synthesize UUID;
@synthesize attribute;
@synthesize sourceIdentifier;

- (id) initWithUUID: (ETUUID *)aUUID
		  attribute: (NSString *)anAttribute
   sourceIdentifier: (id)aSourceIdentifier
{
	NILARG_EXCEPTION_TEST(aUUID);
	NILARG_EXCEPTION_TEST(anAttribute);
	NILARG_EXCEPTION_TEST(aSourceIdentifier);	
	SUPERINIT;
	UUID = [aUUID copy];
	attribute = [anAttribute copy];
	sourceIdentifier = [aSourceIdentifier copy];
	return self;
}

- (id) copyWithZone: (NSZone *)aZone
{
	return [self retain];
}

- (void) dealloc
{
	[UUID release];
	[attribute release];
	[sourceIdentifier release];
	[super dealloc];
}

- (BOOL) isEqualIgnoringSourceIdentifier: (id)other
{
	return [other isKindOfClass: [self class]]
		&&	[UUID isEqual: ((COSubtreeEdit*)other).UUID]
		&&	[attribute isEqual: ((COSubtreeEdit*)other).attribute];
}

- (NSUInteger) hash
{
	return 17540461545992478206ULL ^ [UUID hash] ^ [attribute hash] ^ [sourceIdentifier hash];
}

- (BOOL) isEqual: (id)other
{
	return [self isEqualIgnoringSourceIdentifier: other]
		&& [sourceIdentifier isEqual: ((COSubtreeEdit*)other).sourceIdentifier];
}

@end


#pragma mark set, delete attribute

@implementation COSetAttribute

@synthesize type;
@synthesize value;

- (void)dealloc
{
	[value release];
	[type release];
	[super dealloc];
}

- (BOOL) isEqualIgnoringSourceIdentifier: (id)other
{
	return [super isEqualIgnoringSourceIdentifier: other]
	&&	[type isEqual: ((COSetAttribute*)other).type]
	&&	[value isEqual: ((COSetAttribute*)other).value];
}

- (NSUInteger) hash
{
	return 4265092495078449026ULL ^ [super hash] ^ [type hash] ^ [value hash];
}

- (id) initWithUUID: (ETUUID *)aUUID
		  attribute: (NSString *)anAttribute
   sourceIdentifier: (id)aSourceIdentifier
			   type: (COType *)aType
			  value: (id)aValue
{
	NILARG_EXCEPTION_TEST(aType);
	NILARG_EXCEPTION_TEST(aValue);
	self = [super initWithUUID: aUUID attribute: anAttribute sourceIdentifier: aSourceIdentifier];
	type = [aType copy];
	value = [aValue copy];
	return self;
}

@end


@implementation CODeleteAttribute

- (NSUInteger) hash
{
	return 10002940502939600064ULL;
}

@end


#pragma mark editing set multivalueds

@implementation COSetInsertion
@synthesize object;

- (id) initWithUUID: (ETUUID *)aUUID
		  attribute: (NSString *)anAttribute
   sourceIdentifier: (id)aSourceIdentifier
			 object: (id)anObject
{
	NILARG_EXCEPTION_TEST(anObject);
	self = [super initWithUUID: aUUID attribute: anAttribute sourceIdentifier: aSourceIdentifier];
	object = [anObject copy];
	return self;
}

- (void)dealloc
{
	[object release];
	[super dealloc];
}

- (BOOL) isEqualIgnoringSourceIdentifier: (id)other
{
	return [super isEqualIgnoringSourceIdentifier: other]
	&&	[object isEqual: ((COSetInsertion*)other).object];
}

- (NSUInteger) hash
{
	return 595258568559201742ULL ^ [super hash] ^ [object hash];
}

@end


@implementation COSetDeletion

- (NSUInteger) hash
{
	return 1310827214389984141ULL ^ [super hash];
}

@end


#pragma mark editing array multivalueds


@implementation COSequenceEdit
@synthesize range;

- (id) initWithUUID: (ETUUID *)aUUID
		  attribute: (NSString *)anAttribute
   sourceIdentifier: (id)aSourceIdentifier
			  range: (NSRange)aRange
{
	self = [super initWithUUID: aUUID attribute: anAttribute sourceIdentifier: aSourceIdentifier];
	range = aRange;
	return self;
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

- (BOOL) isEqualIgnoringSourceIdentifier:(id)other
{
	return [super isEqualIgnoringSourceIdentifier: other]
		&& NSEqualRanges(range, ((COSequenceEdit*)other).range);
}

- (NSUInteger) hash
{
	return 9723954873297612448ULL ^ [super hash] ^ range.location ^ range.length;
}

@end


@implementation COSequenceInsertion
@synthesize objects;

- (id) initWithUUID: (ETUUID *)aUUID
		  attribute: (NSString *)anAttribute
   sourceIdentifier: (id)aSourceIdentifier
		   location: (NSUInteger)aLocation
			objects: (NSArray *)anArray
{
	NILARG_EXCEPTION_TEST(anArray);
	self = [super initWithUUID: aUUID attribute: anAttribute sourceIdentifier: aSourceIdentifier range: NSMakeRange(aLocation, 0)];
	objects = [[NSArray alloc] initWithArray: anArray copyItems: YES];
	return self;
}

- (void)dealloc
{
	[objects release];
	[super dealloc];
}
					  
- (BOOL) isEqualIgnoringSourceIdentifier: (id)other
{
	return [super isEqualIgnoringSourceIdentifier: other]
	&&	[objects isEqual: ((COSequenceInsertion*)other).objects];
}
					  
- (NSUInteger) hash
{
	return 14584168390782580871ULL ^ [super hash] ^ [objects hash];
}

@end


@implementation COSequenceDeletion

- (NSUInteger) hash
{
	return 17441750424377234775ULL ^ [super hash];
}

@end


@implementation COSequenceModification

- (id) initWithUUID: (ETUUID *)aUUID
		  attribute: (NSString *)anAttribute
   sourceIdentifier: (id)aSourceIdentifier
			  range: (NSRange)aRange
			objects: (NSArray *)anArray
{
	NILARG_EXCEPTION_TEST(anArray);
	self = [super initWithUUID: aUUID attribute: anAttribute sourceIdentifier: aSourceIdentifier range: aRange];
	objects = [[NSArray alloc] initWithArray: anArray copyItems: YES];
	return self;
}

- (NSUInteger) hash
{
	return 11773746616539821587ULL ^ [super hash];
}

@end
