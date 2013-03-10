#import <Foundation/Foundation.h>

@class COType;
@class COSchemaRegistry;
@class COSchemaTemplate;

@interface COSchema : NSObject
{
    COSchemaRegistry *parentRegistry_;
    NSString *name_;
    NSString *parent_;
    NSDictionary *typeForAttribute_;
    NSDictionary *schemaNameForAttribute_;
}

@property (readonly, nonatomic) NSString *name;

- (id) initWithSchemaTemplate: (COSchemaTemplate *)aTemplate
                     registry: (COSchemaRegistry *)aRegistry;

- (COSchema *) parent;
- (NSSet *) propertyNames;
- (COType *) typeForProperty: (NSString *)aProperty;
- (NSString *) schemaForProperty: (NSString *)aProperty;

@end
