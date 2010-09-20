#import <EtoileFoundation/ETUUID.h>

// TODO: rewrite to delta-compress data.
@interface COStoreBackend : NSObject
{
  NSURL *_url;
  
}
- (id) initWithURL: (NSURL *)url;
+ (COStore *)storeWithURL: (NSURL *)url;

- (id)propertyListForKey: (NSString *)key;
- (BOOL)setPropertyList: (id)object forKey: (NSString *)key;
- (void)removePropertyListForKey: (NSString *)key;

@end