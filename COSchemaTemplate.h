#import <Foundation/Foundation.h>

@class COType;

@interface COSchemaTemplate : NSObject
{
    NSString *name_;
    NSString *parent_;
    NSMutableDictionary *typeForAttribute_;
    NSMutableDictionary *schemaNameForAttribute_;
}

@property (readonly, nonatomic) NSString *name;
@property (readwrite, retain, nonatomic) NSString *parent;
@property (readonly, nonatomic) NSDictionary *typeForAttribute;
@property (readonly, nonatomic) NSDictionary *schemaNameForAttribute;

+ (COSchemaTemplate *) schemaWithName: (NSString *) aName;

- (void) setType: (COType *)aType
      schemaName: (NSString *)aSchema
     forProperty: (NSString *)aProperty;

- (void) setType: (COType *)aType
     forProperty: (NSString *)aProperty;

@end
