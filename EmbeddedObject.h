#import <Foundation/Foundation.h>
#import "Common.h"

/**
 * Basic storage object - no versioning built in.
 * Can be used on its own or wrapped in a VersionedObject to provide versioning
 *
 * will be inside an EmbeddedObject or a HistoryNode
 */
@interface EmbeddedObject : BaseObject
{
    NSMutableArray *contents; // array of BaseObject's - should do a deep copy.
    NSDictionary *metadata;
}

@property (readwrite, nonatomic, retain) NSMutableArray *contents;
@property (readwrite, nonatomic, copy) NSDictionary *metadata;

- (id)copyWithZone:(NSZone *)zone;

+ (EmbeddedObject *) objectWithContents: (NSArray*)contents
                               metadata: (NSDictionary*)metadata;

@end
