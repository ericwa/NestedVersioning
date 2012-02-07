/*
   Copyright (C) 2007 Yen-Ju Chen <yjchenx gmail>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

/** @group UUID

An implementation of the <uref url="http://en.wikipedia.org/wiki/Universally_unique_identifier">
Universally Unique Identifier</uref> standard. 

When an ETUUID is instantiated, the underlying UUID is generated with the 
version 4 (aka random) generation scheme.<br /> 
Take note the random scheme used on Linux and BSD platforms is based on a 
strong random number, unlike other platforms where a simpler random scheme is 
used. Which means collisions can occur on these platforms if you try to 
generate ETUUID in a tight loop.

You can use -isEqual: to check the equality between two ETUUID instances.

ETUUID does not have a designated initializer. */
@interface ETUUID : NSObject <NSCopying>
{
	@private
	unsigned char uuid[16];
}

/** @taskunit Initialization */

/**
 * Returns a new autoreleased UUID object initialized with a random 128-bit 
 * binary value.
 */
+ (id) UUID;
/**
 * Returns an autoreleased UUID object for the given UUID string representation. 
 */
+ (id) UUIDWithString: (NSString *)aString;

/**
 * Initializes the UUID object with a 128-bit binary value.
 */
- (id) initWithUUIDBytes: (const unsigned char *)aUUID;
/**
 * Initializes the UUID object from a string representation.
 */
- (id) initWithString: (NSString *)aString;
/** 
 * Initializes a UUID object by generating a random 128-bit binary value. 
 */
- (id) init;

/** @taskunit Alternative Representations */

/** 
 * Returns a string representation of the receiver.
 */
- (NSString *) stringValue;
/**
 * Returns a 128-bit binary value representation of the receiver.
 */
- (const unsigned char *) UUIDValue;

/** @taskunit Comparison */

- (BOOL) isEqual: (id)anObject;

@end
