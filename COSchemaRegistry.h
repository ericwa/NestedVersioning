#import <Foundation/Foundation.h>

@class COSchemaTemplate;
@class COSchema;

@interface COSchemaRegistry : NSObject
{
    NSMutableDictionary *schemas_;
}

+ (COSchemaRegistry *) registry;

- (void) addSchema: (COSchemaTemplate*)aSchema;

- (COSchema *) schemaForName: (NSString *)aName;

@end
