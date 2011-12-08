#import <Foundation/Foundation.h>

#import "ETUUID.h"

@interface COItemTreeNode : NSObject
{
	ETUUID *uuid;
	NSMutableDictionary *valueForAttribute; // string -> (COItemTreeNode, NString, ETUUID, NSNumber, NSData) or set/array
	NSMutableDictionary *typeForAttribute; // string-> COType
}

@end
