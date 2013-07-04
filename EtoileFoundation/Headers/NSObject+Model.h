/*
	NSObject+Model.h
	
	NSObject additions providing basic management of model objects.
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2007
 
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
#import <EtoileFoundation/ETPropertyValueCoding.h>

@class ETEntityDescription;

/** @group Model and Metamodel */
@interface NSObject (ETModelAdditions) <ETPropertyValueCoding>

+ (ETEntityDescription *) newEntityDescription;
+ (ETEntityDescription *) newBasicEntityDescription;

+ (id) objectWithObjectValue: (id)object;
+ (id) objectWithStringValue: (NSString *)string;

- (id) objectValue;
- (NSString *) stringValue;
- (NSString *) stringValueWithOptions: (NSDictionary *)outputOptions;

- (BOOL) isCommonObjectValue;
- (BOOL) isString;
- (BOOL) isNumber;

- (NSString *) typeForKey: (NSString *)key;

/** @taskunit Property Value Coding */

- (BOOL) requiresKeyValueCodingForAccessingProperties;
- (NSArray *) propertyNames;
- (id) valueForProperty: (NSString *)key;
- (BOOL) setValue: (id)value forProperty: (NSString *)key;

/** @taskunit Key Value Coding */

- (id) basicValueForKey: (NSString *)key;
- (void) setBasicValue: (id)value forKey: (NSString *)key;

/** @taskunit Basic Properties */

- (NSString *) displayName;
/* NSObject+EtoileUI offers also the following basic property
  - (NSImage *) icon; */

- (NSString *) primitiveDescription;
- (NSString *) descriptionWithOptions: (NSMutableDictionary *)options;

/** @taskunit KVO Syntactic Sugar (Unstable API) */

- (NSSet *) observableKeyPaths;
- (void) addObserver: (id)anObserver;
- (void) removeObserver: (id)anObserver;

/** @taskunit Collection & Mutability */

+ (Class) mutableClass;

- (BOOL) isMutable;
- (BOOL) isCollection;
- (BOOL) isMutableCollection;
- (BOOL) isGroup;

- (id) keyForCollection: (id)collection;

@end

/** An array of key paths to indicate the values -descriptionWithOptions: 
should report.

Default value is nil. */
extern NSString * const kETDescriptionOptionValuesForKeyPaths;
/** Key-Value-Coding key to indicate a value to be treated as a recursive  
collection. Each element will be sent -descriptionWithOptions: to report every 
descendant description.

Default value is nil.  */
extern NSString * const kETDescriptionOptionTraversalKey;
/** Integer number object to indicate the depth at which -descriptionWithOptions: 
should stop to traverse collections with kETDescriptionOptionTraversalKey.

Default value is 20. */
extern NSString * const kETDescriptionOptionMaxDepth;

/** Posts this notification to let other objects know about collection mutation   
in your model object. 

For example, EtoileUI uses this notification to reload the UI transparently. 
See -[ETLayoutItemGroup setRepresentedObject:]. */
extern NSString * const ETCollectionDidUpdateNotification;

/* Basic Common Value Classes */

/** @group Model and Metamodel */
@interface NSString (ETModelAdditions)
- (BOOL) isCommonObjectValue;
@end

/** @group Model and Metamodel */
@interface NSNumber (ETModelAdditions)
- (BOOL) isCommonObjectValue;
@end

/** @group Model and Metamodel */
@interface NSDate (ETModelAdditions)
- (BOOL) isCommonObjectValue;
@end
