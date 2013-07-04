/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  December 2007
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/NSKeyValueObserving.h>
#import "NSObject+Model.h"
#import "Macros.h"
#import "NSObject+Etoile.h"
#import "ETCollection.h"
#import "ETEntityDescription.h"
#import "ETModelDescriptionRepository.h"
#import "EtoileCompatibility.h"
#ifndef GNUSTEP
#import <objc/runtime.h>
#endif
//#define DEBUG_PVC 1


@implementation NSObject (ETModelAdditions)

/** <override-dummy />
Returns a new self-description (aka metamodel).

You must never use this method to retrieve an entity description, but only 
retrieves it through a ETModelDescriptionRepository instance.

This method can be invoked at runtime by a repository to automatically collect 
the entity descriptions and make them available in this repository.

You can implement this method to describe your subclasses more precisely than 
-basicNewEntityDescription.<br />
You must never call [super newEntityDescription] in the implementation.<br />
You must not return an autoreleased object.

For example:

<example>
ETEntityDescription *desc = [self newBasicEntityDescription];

// For subclasses that don't override -newEntityDescription, we must not add the 
// property descriptions that we will inherit through the parent (the 
// 'MyClassName' entity description).
if ([[desc name] isEqual: [MyClass className]] == NO) return desc;

ETPropertyDescription *city = [ETPropertyDescription descriptionWithName: @"city" type: (id)@"NSString"];
ETPropertyDescription *country = [ETPropertyDescription descriptionWithName: @"country" type: (id)@"NSString"];

[desc setPropertyDescriptions: A(city, country)];

[desc setAbstract: YES];

return desc;
</example>

If you want set the parent explicitly, replace -newBasicEntityDescription with:

<example>
ETEntityDescription *desc = [ETEntityDescription descriptionWithName: [self className]];

// Will be resolved when the entity description is put in the repository
[desc setParent: NSStringFromClass([self superclass])];
</example>
 */
+ (ETEntityDescription *) newEntityDescription
{
	return [self newBasicEntityDescription];
}

/** <override-never />
Returns a new minimal self-description without any property descriptions.

This entity description uses the class name as its name and the parent is set 
to the superclass name.<br />
The parent will be resolved once when the description is added to the repository.

You must never use this method to retrieve an entity description, but only a 
ETModelDescriptionRepository instance to do so.

The returned object is not autoreleased.

See also -newEntityDescription. */
+ (ETEntityDescription *) newBasicEntityDescription
{
	ETEntityDescription *desc = [[ETEntityDescription alloc] initWithName: [self className]];

	if ([self superclass] != nil)
	{
		[desc setParent: (id)[[self superclass] className]];
	}
	return desc;
}

#ifndef GNUSTEP
- (BOOL) isClass
{
	return class_isMetaClass([self class]);
}
#endif

+ (id) objectWithObjectValue: (id)object
{
	if ([object isString])
	{
		return [self objectWithStringValue: object];
	}
	else if ([object isCommonObjectValue])
	{
		return object;
	}
	else if ([object isKindOfClass: [NSValue class]])
	{
		return nil;
	}
	
	return nil;
}

+ (id) objectWithStringValue: (NSString *)string
{
	id object = nil;
	Class class = NSClassFromString(string);
	
	if (class != nil)
		object = AUTORELEASE([[class alloc] init]);
		
	return object;
}

	// returning the value
	// as is if it is declared as a common object value or
- (id) objectValue
{
	if ([self isCommonObjectValue])
	{
		return self;
	}
	else
	{
		return [self stringValue];
	}
}

/** <override-dummy />
Returns the description of the receiver by default.

Subclasses can override this method to return a string representation that 
encodes some basic infos about the receiver. This string representation can 
then be edited, validated by -validateValue:forKey:error: and used to 
instantiate another object by passing it to +objectWithStringValue:. */
- (NSString *) stringValue
{
	return [self description];
}

/** Returns -stringValue by default.

Subclasses can override this method to return a custom string representation  
based on the given rendering options. Like -stringValue, it should encode some 
basic infos about the receiver but the method is typically used to introduce 
variations in the output format. For example to handle pretty printing and 
special formatting rules. 

Not all output options have to be handled, you can safely ignore options which 
you aren't interested in.

The resulting string representation must remain editable, validatable by 
-validateValue:forKey:error: and usable to instantiate another object by 
passing it to +objectWithStringValue:. */
- (NSString *) stringValueWithOptions: (NSDictionary *)outputOptions
{
	return [self stringValue];
}

/** Returns YES if the receiver is an NSString instance, otherwise returns NO. */
- (BOOL) isString
{
	return [self isKindOfClass: [NSString class]];
}

/** Returns YES if the receiver is an NSNumber instance, otherwise returns NO. */
- (BOOL) isNumber
{
	return [self isKindOfClass: [NSNumber class]];
}

/** Returns a mutable counterpart class or Nil if such a class does not exist. */
+ (Class) mutableClass
{
	return Nil;
}

/** <override-dummy />
Returns YES if the receiver is declared as a group, otherwise returns NO. 

This method returns NO by default. You can override it to return YES if you 
want to declare your subclass instances as groups. 

A group is specialized model object which is a composite and can behave like a 
mutable collection. A basic collection object (like NSMutableArray, 
NSMutableDictionary, NSMutableSet) must never be declared as a group.<br />
COGroup in CoreObject or ETLayoutItemGroup in EtoileUI are typical examples.

A group should conform to ETCollectionMutation protocol. */
- (BOOL) isGroup
{
	return NO;
}

/** <override-dummy />
Returns YES if the receiver is declared as mutable, otherwise returns NO. 

This method returns NO by default. You can override it to return YES if you 
want to declare your subclass instances as mutable objects (which are 
collections most of time).

If you adopts ETCollectionMutation in a subclass, you don't need to override 
this method to declare your collection objects as mutable. */
- (BOOL) isMutable
{
	if ([self conformsToProtocol: @protocol(ETCollectionMutation)])
		return YES;

	return NO;
}

/** <override-never />
Returns YES if the receiver is declared as a collection by conforming to 
ETCollection protocol, otherwise returns NO.

You must never override this method in your collection classes, you only need 
to adopt ETCollection protocol. */
- (BOOL) isCollection
{
	return [self conformsToProtocol: @protocol(ETCollection)];
}

/** <override-never />
Returns YES if the receiver is declared as a collection by conforming to 
ETCollectionMutation protocol, otherwise returns NO. 

You must never override this method in your collection classes, you only need 
to adopt ETCollectionMutation protocol. */
- (BOOL) isMutableCollection
{
	return [self conformsToProtocol: @protocol(ETCollectionMutation)];
}

- (BOOL) validateValue: (id *)value forKey: (NSString *)key error: (NSError **)err
{
	id val = *value;
	BOOL validated = YES;
	
	if ([val isCommonObjectValue])
		return YES;
	
	/* Validate non common value objects */
		
	//NSString *type = [self typeForKey: key];
	
	return validated;
}

- (NSString *) typeForKey: (NSString *)key
{
/*	NSMethodSignature *sig = [self methodSignatureForSelector: NSSelectorFromString(key)];
	
	if (sig == nil)
		sig [self methodSignatureForSelector: NSSelectorFromString()];
		
	[*/
	return nil;
}

/* Property Value Coding */

/** Returns NO.

See -[ETPropertyValueCoding requiresKeyValueCodingForAccessingProperties]. */
- (BOOL) requiresKeyValueCodingForAccessingProperties
{
	return NO;
}

/** <override-dummy />
Returns the property names accessible through Property Value Coding but
not declared in the metamodel (e.g. NSObject or subclass entity description). 
 
For example, this includes properties such as <em>icon</em> or <em>isMutable</em>.
 
Can be overriden to include additional properties not declared in the metamodel, 
but must call the superclass implementation.

See -propertyNames. */
- (NSArray *) basicPropertyNames
{
	return [NSArray arrayWithObjects: @"icon", @"displayName", @"className",
		@"class", @"superclass", @"hash", @"self", @"isProxy", @"stringValue",
		@"objectValue", @"isCollection", @"isGroup",@"isMutable",
		@"isMutableCollection", @"isCommonObjectValue", @"isNumber", @"isString",
		@"isClass", @"description", @"primitiveDescription", nil];
}

/** Returns both the property names bound to the object entity description and 
the basic property names.
 
+ETModelDescriptionRepository mainRepository] is used to look up the entity 
description.

To be exposed through Property Value Coding, the receiver properties must be 
listed among the returned properties.
 
Can be overriden to return property names bound to entity descriptions that 
don't belong to the main repository, or filter some properties out. In the 
overriden method, you should usually return -basicPropertyNames along the 
property description names.
 
For a NSObject subclass not bound to an entity description, the property names 
related to the closest superclass bound to an entity description are returned 
through a recursive lookup in -entityDescriptionForClass:.
 
See -basicPropertyNames, -valueForProperty: and -setValue:forProperty:.
See also -[ETPropertyValueCoding propertyNames]. */
- (NSArray *) propertyNames
{
	ETEntityDescription *description =
		[[ETModelDescriptionRepository mainRepository] entityDescriptionForClass: [self class]];
	ETAssert(description != nil);
	NSArray *properties = [description allPropertyDescriptionNames];
	ETAssert(properties != nil);
	return [[self basicPropertyNames] arrayByAddingObjectsFromArray: properties];
}

/** See -[ETPropertyValueCoding valueForProperty:]. */
- (id) valueForProperty: (NSString *)key
{
	id value = nil;
	
	if ([[self propertyNames] containsObject: key])
	{
		value = [self basicValueForKey: key];
	}
	else
	{
		// TODO: Turn into an ETDebugLog which takes an object (or a class) to
		// to limit the logging to a particular object or set of instances.
		#ifdef DEBUG_PVC
		ETLog(@"WARNING: Found no value for property %@ in %@", key, self);
		#endif
	}
	
	return value;
}

/** See -[ETPropertyValueCoding setValue:forProperty:]. */
- (BOOL) setValue: (id)value forProperty: (NSString *)key
{
	BOOL result = NO;
	
	if ([[self propertyNames] containsObject: key])
	{
		[self setBasicValue: value forKey: key];
		result = YES;
	}
	else
	{
		// TODO: Turn into an ETDebugLog which takes an object (or a class) to
		// to limit the logging to a particular object or set of instances.
		#ifdef DEBUG_PVC
		ETLog(@"WARNING: Trying to set value %@ for property %@ missing in "
			@"immutable property collection of %@", value, key, self);
		#endif
	}
	
	return result;
}

/* Key Value Coding */

static id (*valueForKeyIMP)(id, SEL, NSString *) = NULL;
static void (*setValueForKeyIMP)(id, SEL, id, NSString *) = NULL;

/** Returns the value identified by key as NSObject does, even if -valueForKey:
    is overriden.
    This method allows to use basic KVC access (through ivars and accessors) 
    from -valueForProperty: or other methods in subclasses, when a custom KVC 
    strategy is implemented in subclasses for -valueForKey:. */
- (id) basicValueForKey: (NSString *)key
{
	valueForKeyIMP = (id (*)(id, SEL, NSString *))[[NSObject class] 
		instanceMethodForSelector: @selector(valueForKey:)];
	return valueForKeyIMP(self, @selector(valueForKey:), key);
}

/** Sets the value identified by key as NSObject does, even if -setValue:forKey:
    is overriden.
    This method allows to use basic KVC access (through ivars and accessors) 
    from -setValue:forProperty: or other methods in subclasses, when a custom 
    KVC strategy is implemented in subclasses for -setValue:forKey:. */
- (void) setBasicValue: (id)value forKey: (NSString *)key
{
	setValueForKeyIMP = (void (*)(id, SEL, id, NSString *))[[NSObject class] 
		instanceMethodForSelector: @selector(setValue:forKey:)];
	setValueForKeyIMP(self, @selector(setValue:forKey:), value, key);
}

/* Basic Properties */

/** Returns the receiver description.
	Subclasses can override this method to return a more appropriate display
	name. */
- (NSString *) displayName
{
	return [self description];
}

/** Returns YES when the receiver is an object which can be passed to 
	-setObjectValue: or returned by -objectValue. Some common object values
	like string and number can be displayed and edited transparently (in an 
	NSCell instance to take an example). If you define additional common object
	values, you usually have to write related formatters.
	Returns NO by default.
	Subclasses can override this method to specify an object can be accepted
	and used a common object value. */
- (BOOL) isCommonObjectValue
{
	return NO;
}

/** <override-never />
	Returns the description as NSObject would. 
	This method returns the same value as -description if the latter method 
	isn't overriden in your subclasses, otherwise it returns the value that
	-description would return if you haven't overriden it.
	Useful to get consistent short descriptions on all instances and can be
	used to provide custom description built with other short descriptions. */
- (NSString *) primitiveDescription
{
	// return [super primitiveDescription]; doesn't compile because super 
	// is keyword and not a pseudovar like self
	NSString * (*descIMP)(id, SEL, id) = NULL;
	
	descIMP = (NSString * (*)(id, SEL, id))[[NSObject class] 
		instanceMethodForSelector: @selector(description)];
	return descIMP(self, @selector(description), nil);
}

/** Returns a description generated based on the given options.

Might describe a tree or graph structure if a traversal key is provided to 
recursively invoke -descriptionsWithOptions: on each object node. To do so, 
put ETDescriptionOptionTraversalKey with a valid KVC key in the options. 
You can also set a max depth with ETDescriptionOptionMaxDepth to limit the 
description size or end a graph traversal.

You can collect key path values on each object node by specifying an array of 
key paths with ETDescriptionOptionValuesForKeyPaths.

The description format is roughly:
depth based indentation + object class and address + keyPath1: value1, keyPath2: value2 etc.

Here is an example based on EtoileUI that dumps an item tree structure:

<example>
// ObjC code
ETLog(@"\n%@\n", [browserItem descriptionWithOptions: [NSMutableDictionary dictionaryWithObjectsAndKeys: 
	A(@"frame", @"autoresizingMask"), kETDescriptionOptionValuesForKeyPaths,
	@"items", kETDescriptionOptionTraversalKey, nil]]);

// Console Output
&lt;ETLayoutItemGroup: 0x9e7b268&gt; frame: {x = 0; y = 0; width = 600; height = 300}, autoresizingMask: 18
	&lt;ETLayoutItemGroup: 0x9fbea48&gt; frame: {x = 0; y = 0; width = 1150; height = 53}, autoresizingMask: 2
		&lt;ETLayoutItem: 0x9f29240&gt; frame: {x = 12; y = 12; width = 100; height = 22}, autoresizingMask: 0
		&lt;ETLayoutItem: 0x9e6fcf0&gt; frame: {x = 124; y = 12; width = 100; height = 24}, autoresizingMask: 0
	&lt;ETLayoutItemGroup: 0x9fac170&gt; frame: {x = 0; y = 0; width = 1150; height = 482}, autoresizingMask: 18
		&lt;ETLayoutItemGroup: 0x9fb2870&gt; frame: {x = 0; y = 0; width = 50; height = 50}, autoresizingMask: 0
</example>

options must not be nil, otherwise raises an NSInvalidArgumentException.

You can override this method in subclasses, although it is not advised to. 
The options dictionary can be changed arbitrarily in a new implementation. */
- (NSString *) descriptionWithOptions: (NSMutableDictionary *)options
{
	NILARG_EXCEPTION_TEST(options);

	NSMutableString *desc = [NSMutableString string];
	NSArray *keyPaths = [options objectForKey: kETDescriptionOptionValuesForKeyPaths];
	NSString *indent = [options objectForKey: @"kETDescriptionOptionCurrentIndent"];
	if (nil == indent) indent = @"";
	NSString *newIndent = [indent stringByAppendingString: @"\t"];
	NSNumber *depthObject = [options objectForKey: @"kETDescriptionOptionCurrentDepth"];
	NSNumber *maxDepthObject = [options objectForKey: kETDescriptionOptionMaxDepth];

	if (nil == depthObject)
	{
		depthObject =  [NSNumber numberWithInteger: 0]; 
		[options setObject: depthObject forKey: @"ETDescriptionOptionCurrentDepth"];
	}
	if (nil == maxDepthObject)
	{
		maxDepthObject = [NSNumber numberWithInteger: 20];
		[options setObject: maxDepthObject forKey: kETDescriptionOptionMaxDepth];
	}

	[desc appendString: @"\n"];
	[desc appendString: indent];
	[desc appendString: [self primitiveDescription]];
	[desc appendString: @" "];

	/* Print Properties */

	FOREACH(keyPaths, keyPath, NSString *)
	{
		[desc appendString: keyPath];
		[desc appendString: @": "];
		NSString *value = [[self valueForKeyPath: keyPath] stringValue];
		[desc appendString: (value != nil ? value : @"nil")];
		[desc appendString: @", "];
	}
	[desc deleteCharactersInRange: NSMakeRange([desc length] - 2, 2)];	

	/* Print Children */

	NSInteger depth = [depthObject integerValue];
	NSInteger maxDepth = [maxDepthObject integerValue];
	NSString *traversalKey = [options objectForKey: kETDescriptionOptionTraversalKey];

	if (depth < maxDepth && nil != traversalKey)
	{
		[options setObject: newIndent forKey: @"kETDescriptionOptionCurrentIndent"];
		[options setObject: [NSNumber numberWithInteger: depth + 1] 
		            forKey: @"kETDescriptionOptionCurrentDepth"];

		FOREACHI([self valueForKey: traversalKey], obj)
		{
			[desc appendString: [obj descriptionWithOptions: options]];
		}

		[options setObject: indent forKey: @"kETDescriptionOptionCurrentIndent"];
		[options setObject: [NSNumber numberWithInteger: depth] 
		            forKey: @"kETDescriptionOptionCurrentDepth"];
	}

	if (0 == depth)
	{
		[desc appendString: @"\n"];
	}

	return desc;
}

/* KVO Syntactic Sugar */

/** <override-dummy />
Returns an empty set.<br />
Overrides to return the receiver key paths to be observed when an observer is 
set up with -addObserver:.<br />

The returned set content must not change during the whole object lifetime, 
otherwise -removeObserver: will crash randomly. */
- (NSSet *) observableKeyPaths
{
	return [NSSet set];
}

/** Sets up the given object to observe each receiver key paths returned by 
-observableKeyPaths. 

The observer will receive NSKeyValueObservingOptionOld and 
NSKeyValueObservingOptionNew in the change dictionary. */
- (void) addObserver: (id)anObserver
{
	FOREACH([self observableKeyPaths], keyPath, NSString *)
	{
		[self addObserver: anObserver
		       forKeyPath: keyPath
		          options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
		          context: NULL];
	}
}

/** Removes the observer that was observing the receiver key paths returned 
by -observableKeyPaths. */
- (void) removeObserver: (id)anObserver
{
	FOREACH([self observableKeyPaths], keyPath, NSString *)
	{
		[self removeObserver: anObserver forKeyPath: keyPath];
	}
}

/* Collection */

/** <override-dummy /> 
Returns a key which can be used on inserting the receiver into a keyed 
collection like a dictionary.

This key is retrieved by a collection in reply to -addObject: of 
ETCollectionMutation protocol. You can return different keys depending on the 
type of collection. This parameter is usually the mutated collection itself. */
- (id) keyForCollection: (id)collection
{
	return nil;
}

@end

NSString * const kETDescriptionOptionValuesForKeyPaths = @"kETDescriptionOptionValuesForKeyPaths";;
NSString * const kETDescriptionOptionTraversalKey = @"kETDescriptionOptionTraversalKey";
NSString * const kETDescriptionOptionMaxDepth = @"kETDescriptionOptionMaxDepth";

NSString * const ETCollectionDidUpdateNotification = @"ETCollectionDidUpdateNotification";

/* Basic Common Value Classes */

@implementation NSString (ETModelAdditions)
/** Returns YES. */
- (BOOL) isCommonObjectValue { return YES; }
@end

@implementation NSNumber (ETModelAdditions)
/** Returns YES. */
- (BOOL) isCommonObjectValue { return YES; }
@end

@implementation NSDate (ETModelAdditions)
/** Returns YES. */
- (BOOL) isCommonObjectValue { return YES; }
@end
