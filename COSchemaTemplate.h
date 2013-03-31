#import <Foundation/Foundation.h>

#import "COType.h"

/*
 
 TODO: Maybe support primitive schemas
 
 So you can say a property
 
 shape : <data ...> has primitive schema org.etoile.bezier-path
 
 and define a value transformer for org.etoile.bezier-path <-> NSBezierPath
 
 Mixin (multiple inheritance) schema support for COObject?
 
 */
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

- (void) setType: (COType)aType
      schemaName: (NSString *)aSchema
     forProperty: (NSString *)aProperty;

- (void) setType: (COType)aType
     forProperty: (NSString *)aProperty;

@end
