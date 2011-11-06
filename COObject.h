#import <Foundation/Foundation.h>


@interface COObject : NSObject

/**
 things to ditch from om4:
 - anything that can be layered on top, in an external library.
   - the metamodel stuff.. insertObjectWithEntityName: etc. creating objects from a template can be
     handled in an external library.
   - support for subclassing COObject. if we can get away with getting rid of that.
     
 
 - relationship consistency" code will go because we store (versioned) only one side of relationships now.

 - we should minimize what this library needs to know about the structure
   of embedded objects.. may not be possible, but we should try.
 

*/

@end
