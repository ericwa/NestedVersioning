#import <EtoileFoundation/NSData+Hash.h>
#import "COItem+JSON.h"
#import "COPath.h"

@implementation COItem (JSON)

static id plistValueForPrimitiveValue(id aValue, COType aType)
{    
    switch (COPrimitiveType(aType))
    {
        case kCOInt64Type: return aValue;
        case kCODoubleType: return aValue;
        case kCOStringType: return aValue;
        case kCOBlobType: return [aValue base64String];
        case kCOReferenceType:
        case kCOCompositeReferenceType:
            return [(ETUUID *)aValue stringValue];
        case kCOPathType: return [(COPath *)aValue stringValue];
        case kCOAttachmentType: return aValue;
        default:
            [NSException raise: NSInvalidArgumentException format: @"unknown type %d", aType];
            return nil;
    }
}

static id plistValueForValue(id aValue, COType aType)
{
    if (COTypeIsPrimitive(aType))
    {
        return plistValueForPrimitiveValue(aValue, aType);
    }
    else
    {
        NSMutableArray *collection = [NSMutableArray array];
        for (id obj in aValue)
        {
            [collection addObject: plistValueForPrimitiveValue(obj, aType)];
        }
        return collection;
    }
}

static id valueForPrimitivePlistValue(id aValue, COType aType)
{
    switch (COPrimitiveType(aType))
    {
        case kCOInt64Type: return aValue;
        case kCODoubleType: return aValue;
        case kCOStringType: return aValue;
        case kCOBlobType: return [aValue base64DecodedData];
        case kCOReferenceType:
        case kCOCompositeReferenceType:
            return [ETUUID UUIDWithString: aValue];
        case kCOPathType: return [COPath pathWithString: aValue];
        case kCOAttachmentType: return aValue;
        default:
            [NSException raise: NSInvalidArgumentException format: @"unknown type %d", aType];
            return nil;
    }
}

static id valueForPlistValue(id aValue, COType aType)
{
    if (COTypeIsPrimitive(aType))
    {
        return valueForPrimitivePlistValue(aValue, aType);
    }
    else
    {
        id collection;
        if (COTypeIsOrdered(aType))
        {
            collection = [NSMutableArray array];
        }
        else
        {
            collection = [NSMutableSet set];
        }
        
        for (id obj in aValue)
        {
            [collection addObject: valueForPrimitivePlistValue(obj, aType)];
        }
        return collection;
    }
}

static id exportToPlist(id aValue, COType aType)
{
	NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity: 2];
	[result setObject: [NSNumber numberWithInt: aType] forKey: @"type"];
	[result setObject: plistValueForValue(aValue, aType) forKey: @"value"];
	return result;
}

static COType importTypeFromPlist(id aPlist)
{
    return [[aPlist objectForKey: @"type"] intValue];
}

static id importValueFromPlist(id aPlist)
{
    return valueForPlistValue([aPlist objectForKey: @"value"],
                              [[aPlist objectForKey: @"type"] intValue]);
}

- (id) JSONPlist
{
	NSMutableDictionary *plistValues = [NSMutableDictionary dictionaryWithCapacity: [values count]];
	
	for (NSString *key in values)
	{
		id plistValue = exportToPlist([values objectForKey: key], [[types objectForKey: key] intValue]);
		[plistValues setObject: plistValue
						forKey: key];
	}
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 plistValues, @"values",
                                 [uuid stringValue], @"uuid",
                                 nil];
    
    if (self.schemaName != nil) {
        [dict setObject: self.schemaName forKey: @"schema"];
    }
    
    return dict;
}

- (id) initWithJSONPlist: (id)aPlist
{
	ETUUID *aUUID = [ETUUID UUIDWithString: [aPlist objectForKey: @"uuid"]];
    
	NSMutableDictionary *importedValues = [NSMutableDictionary dictionary];
	NSMutableDictionary *importedTypes = [NSMutableDictionary dictionary];
	for (NSString *key in [aPlist objectForKey: @"values"])
	{
		id objPlist = [[aPlist objectForKey: @"values"] objectForKey: key];
		
		[importedValues setObject: importValueFromPlist(objPlist)
						   forKey: key];
		
		[importedTypes setObject: [NSNumber numberWithInt: importTypeFromPlist(objPlist)]
						  forKey: key];
	}
	
	self = [self initWithUUID: aUUID
		   typesForAttributes: importedTypes
		  valuesForAttributes: importedValues];
    
    self.schemaName = [aPlist objectForKey: @"schema"];
    
    return self;
}

- (NSData *) JSONData
{
    id plist = [self JSONPlist];
    return [NSJSONSerialization dataWithJSONObject: plist options: 0 error: NULL];
}

- (id) initWithJSONData: (NSData *)data
{
    id plist = [NSJSONSerialization JSONObjectWithData: data options:0 error: NULL];
    return [self initWithJSONPlist: plist];
}

@end
