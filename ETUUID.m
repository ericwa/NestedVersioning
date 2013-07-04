/*
   Copyright (C) 2007 Yen-Ju Chen <yjchenx gmail>
   Copyright (C) 2012 Eric Wasylishen <ewasylishen gmail>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import <Foundation/Foundation.h>
#import "COMacros.h"
#import "ETUUID.h"
#include <objc/runtime.h>

// FIXME: these macros violate the C aliasing rules
#define TIME_LOW(uuid) (*(uint32_t*)(uuid))
#define TIME_MID(uuid) (*(uint16_t*)(&(uuid)[4]))
#define TIME_HI_AND_VERSION(uuid) (*(uint16_t*)(&(uuid)[6]))
#define CLOCK_SEQ_HI_AND_RESERVED(uuid) (*(&(uuid)[8]))
#define CLOCK_SEQ_LOW(uuid) (*(&(uuid)[9]))
#define NODE(uuid) ((char*)(&(uuid)[10]))


static void COUUIDGet16RandomBytes(unsigned char bytes[16])
{
    static int64_t ctr = 0;
    int64_t val = OSAtomicIncrement64(&ctr);
    memset(bytes, 0, 16);
    memcpy(bytes, &val, 8);
}

#if 0
#ifdef HAVE_ARC4RANDOM
static void COUUIDGet16RandomBytes(unsigned char bytes[16])
{
	uint32_t w1 = arc4random();
	uint32_t w2 = arc4random();
	uint32_t w3 = arc4random();
	uint32_t w4 = arc4random();
	
	memcpy(bytes, &w1, 4);
	memcpy(bytes+4, &w2, 4);
	memcpy(bytes+8, &w3, 4);
	memcpy(bytes+12, &w4, 4);
}
#else
#include <openssl/rand.h>
static void COUUIDGet16RandomBytes(unsigned char bytes[16])
{
	if (1 != RAND_pseudo_bytes(bytes, 16))
	{
		[NSException raise: NSGenericException
					format: @"libcrypto can't automatically seed its random numer generator on your OS"];
	}
}
#endif
#endif

@implementation ETUUID

static Class COUUIDClass;

+ (void) initialize
{
    if (self == [ETUUID class])
    {
        COUUIDClass = self;
    }
}

+ (ETUUID *) UUID
{
	return [[[self alloc] init] autorelease];
}

+ (ETUUID *) UUIDWithString: (NSString *)aString
{
	return [[[self alloc] initWithString: aString] autorelease];
}

+ (ETUUID *) UUIDWithData: (NSData *)aData
{
    NSParameterAssert([aData length] == 16);
    return [[[self alloc] initWithBytes: [aData bytes]] autorelease];
}

- (id) init
{
    SUPERINIT;
    
	COUUIDGet16RandomBytes(uuid);
	
	// Clear bits 6 and 7
	CLOCK_SEQ_HI_AND_RESERVED(uuid) &= (unsigned char)63;
	// Set bit 6
	CLOCK_SEQ_HI_AND_RESERVED(uuid) |= (unsigned char)64;
	// Clear the top 4 bits
	TIME_HI_AND_VERSION(uuid) &= 4095;
	// Set the top 4 bits to the version
	TIME_HI_AND_VERSION(uuid) |= 16384;
	
	return self;
}

- (id) initWithBytes: (const unsigned char *)aUUID
{
    SUPERINIT;

	memcpy(&uuid, aUUID, 16);

	return self;
}

- (id) initWithString: (NSString *)aString
{
	NILARG_EXCEPTION_TEST(aString);
	
	if ([aString length] != 36)
	{
		[NSException raise: NSInvalidArgumentException
					format: @"%@ not 36 characters in length", aString];
	}
	
    SUPERINIT;

	const char *data = [aString UTF8String];
	int scanned = sscanf(data, "%x-%hx-%hx-%2hhx%2hhx-%2hhx%2hhx%2hhx%2hhx%2hhx%2hhx", 
	   &TIME_LOW(uuid), 
	   &TIME_MID(uuid),
	   &TIME_HI_AND_VERSION(uuid),
	   &CLOCK_SEQ_HI_AND_RESERVED(uuid),
	   &CLOCK_SEQ_LOW(uuid),
	   &NODE(uuid)[0],
	   &NODE(uuid)[1],
	   &NODE(uuid)[2],
	   &NODE(uuid)[3],
	   &NODE(uuid)[4],
	   &NODE(uuid)[5]);

	if (scanned != 11)
	{
		[self release];
		[NSException raise: NSInvalidArgumentException
					format: @"%@ not a well formed UUID", aString];
	}
	
	return self;
}

- (id) copyWithZone: (NSZone *)zone
{
	return [self retain];
}

- (NSUInteger) hash
{
	return *((NSUInteger *)uuid);
}

- (BOOL) isEqual: (id)anObject
{
	if (anObject == self)
	{
		return YES;
	}
	else if (object_getClass(anObject) == COUUIDClass)
	{
		return (0 == memcmp(uuid, ((ETUUID *)anObject)->uuid, 16));
	}
    else if ([anObject isKindOfClass: [self class]])
    {
        return (0 == memcmp(uuid, [(ETUUID *)anObject UUIDValue], 16));
    }
	return NO;
}

- (NSString *) stringValue
{
	return [NSString stringWithFormat:
		@"%0.8x-%0.4hx-%0.4hx-%0.2hhx%0.2hhx-%0.2hhx%0.2hhx%0.2hhx%0.2hhx%0.2hhx%0.2hhx", 
		   TIME_LOW(uuid), 
		   TIME_MID(uuid),
		   TIME_HI_AND_VERSION(uuid),
		   CLOCK_SEQ_HI_AND_RESERVED(uuid),
		   CLOCK_SEQ_LOW(uuid),
		   NODE(uuid)[0],
		   NODE(uuid)[1],
		   NODE(uuid)[2],
		   NODE(uuid)[3],
		   NODE(uuid)[4],
		   NODE(uuid)[5]];
}

- (const unsigned char *) UUIDValue
{
	return uuid;
}

- (NSData *) dataValue
{
    return [NSData dataWithBytes: uuid length: 16];
}

- (NSString*) description
{
	return [self stringValue];
}

@end
