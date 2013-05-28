#import <Foundation/Foundation.h>

/**
 * A workspace is a set of "open" persistent roots,
 * for the purpose of resolving/disambiguating cross-persistent root links.
 */

/**
 
 
 Fundamental question
 ==================
 
 Can we track relationships that cross persistent root boundaries?
 seamlessly like within-persistent-root ones?
 
 Clearly embedded object relations (composites) can't cross.
 
 For relationships... we can, given the following:
 - the query results depend on a "working set" of editing contexts, like CO trunk's COEditingContext
 - the results may come from different persistent roots, so may have the same embdedded object UUID.
 
 TODO: Talk to quentin about this
 
 */
@interface COWorkspace : NSObject
{
    NSMutableDictionary *editingContextForUUID_;
}


@end
