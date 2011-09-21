#import <Foundation/Foundation.h>
#import "Common.h"

/**
 * Basic storage object - no versioning built in.
 * Can be used on its own or wrapped in a VersionedObject to provide versioning
 */
@interface EmbeddedObject : BaseObject
{
    // parent (inherited from BaseObject) is an EmbeddedObject or HistoryNode
    NSArray *contents; // array of BaseObject's
    NSDictionary *metadata;
}

@property (readwrite, nonatomic, retain) NSArray *contents;
@property (readwrite, nonatomic, copy) NSDictionary *metadata;

- (id)copyWithZone:(NSZone *)zone;

+ (EmbeddedObject *) objectWithContents: (NSArray*)contents
                               metadata: (NSDictionary*)metadata;

@end
