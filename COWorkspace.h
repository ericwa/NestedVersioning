#import <Foundation/Foundation.h>

/**
 * A workspace is a set of "open" persistent roots,
 * for the purpose of resolving/disambiguating cross-persistent root links.
 */
@interface COWorkspace : NSObject
{
    NSMutableDictionary *editingContextForUUID_;
}


@end
