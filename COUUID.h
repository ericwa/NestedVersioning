/*
   Copyright (C) 2007 Yen-Ju Chen <yjchenx gmail>
   Copyright (C) 2012 Eric Wasylishen <ewasylishen gmail>
 
   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

/**
 * An implementation of the <a href="http://en.wikipedia.org/wiki/Universally_unique_identifier">
 * Universally Unique Identifier</a> standard. 
 * 
 * When a COUUID is instantiated, the underlying UUID is generated with the 
 * version 4 (aka random) generation scheme.
 * 
 * Two random number generators are supported:
 * 
 * - the BSD function arc4random() is used if HAVE_ARC4RANDOM is defined.
 * - otherwise, the OpenSSL function RAND_pseudo_bytes is used. Note that
 *   this code assumes the OpenSSL RNG has seeded itself, which the OpenSSL
 *   documentation specifically warns against doing. However, in practice,
 *   it should handle seeding itself on Windows and Linux. It's beyond the
 *   scope of this code to try to seed the RNG.
 * 
 * You can use -isEqual: to check equality of two COUUID instances.
 * 
 * COUUID does not have a designated initializer.
 */
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
