/**	
	<abstract>NSObject basic reflection additions.</abstract>
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2007
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>

@class ETUTI;

/** @group Reflection

This category extends NSObject reflection API in a minimal way.

The true Etoile reflection API is declared in ETReflection.h. */
@interface NSObject (Etoile)

+ (NSArray *) allSubclasses;
+ (NSArray *) directSubclasses;

- (ETUTI *) UTI;
- (NSString *) typeName;
+ (NSString *) typePrefix;

#if TARGET_OS_IPHONE
- (NSString *) className;
#endif

@end

