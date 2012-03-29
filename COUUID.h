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

When an COUUID is instantiated, the underlying UUID is generated with the 
version 4 (aka random) generation scheme.<br /> 
Take note the random scheme used on Linux and BSD platforms is based on a 
strong random number, unlike other platforms where a simpler random scheme is 
used. Which means collisions can occur on these platforms if you try to 
generate COUUID in a tight loop.

You can use -isEqual: to check the equality between two COUUID instances.

COUUID does not have a designated initializer. */
@interface COUUID : NSObject <NSCopying>
{
	@private
	unsigned char uuid[16];
}

/** @taskunit Initialization */

/**
 * Returns a new autoreleased UUID object initialized with a random 128-bit 
 * binary value.
 */
+ (COUUID *) UUID;
/**
 * Returns an autoreleased UUID object for the given UUID string representation. 
 */
+ (COUUID *) UUIDWithString: (NSString *)aString;

/**
 * Initializes the UUID object with a 128-bit binary value.
 */
- (id) initWithBytes: (const unsigned char *)aUUID;
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
- (const unsigned char *) bytes;

/** @taskunit Comparison */

- (BOOL) isEqual: (id)anObject;

@end
