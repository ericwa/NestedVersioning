#import "COItem+Binary.h"

@implementation COItem (Binary)

- (NSData *) dataValue
{
    for (NSString *key in [self attributeNames])
    {
        COType *type = [self typeForAttribute: key];
        
    }
}

- (id) initWithData: (NSData *)aData
{
    
}

@end
