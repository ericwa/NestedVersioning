/**
	Copyright (C) 2012 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2012
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#define NSMapTable ETCFMapTable
#endif

@interface ETCFMapTable : NSObject
{
	@private
	CFMutableDictionaryRef dict;
}

/** @taskunit Initialization */

+ (id)mapTableWithWeakToStrongObjects;
+ (id)mapTableWithStrongToStrongObjects;

/** @taskunit Accessing and Mutating the Content */

- (id)objectForKey: (id)aKey;
- (void)setObject: (id)anObject forKey: (id)aKey;
- (void)removeObjectForKey: (id)aKey;

/** @taskunit Etoile Additions */

- (NSArray *)allKeys;
- (NSArray *)allValues;

@end
