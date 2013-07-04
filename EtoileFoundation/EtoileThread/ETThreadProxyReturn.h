/*
	ETThreadProxyReturn.h

	Copyright (C) 2007 David Chisnall

	Author:  David Chisnall <csdavec@swan.ac.uk>
	Date:  January 2007

	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice,
	  this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice,
	  this list of conditions and the following disclaimer in the documentation
	  and/or other materials provided with the distribution.
	* Neither the name of the Etoile project nor the names of its contributors
	  may be used to endorse or promote products derived from this software
	  without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
	THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>
#include <pthread.h>

/**
 * The ETThreadProxyReturn class is used to implement futures.  It is returned
 * from a threaded object.
 */
@interface ETThreadProxyReturn : NSProxy
{
	id object;
	NSException *exception;
	pthread_cond_t conditionVariable;
	pthread_mutex_t mutex;
}
/**
 * Sets the object represented by the proxy.  Should only be called by
 * ETThreadedObject.
 */
- (void) setProxyObject: (id)anObject;

/**
 * Sets an exception that might be caused by executing a method on the other
 * thread. Should only be called by ETThreadedObject.
 */
- (void) setProxyException: (NSException*)anException;

/**
 * Returns the value represented by the object.
 */
- (id) value;
/**
 * Returns YES if the caller is a future, no otherwise.
 */
- (BOOL) isFuture;
@end
