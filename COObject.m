#import <EtoileFoundation/EtoileFoundation.h>
#import "COObject.h"
#import "NSData+sha1.h"

@implementation COObject

- (id) initWithContext: (COObjectContext*)ctx
{
  SUPERINIT;
  _ctx = [ctx retain];
  _uuid = [[ETUUID alloc] init];
  _data = nil;
  [_ctx recordObject: self forUUID: [self uuid]];
  return self;
}

- (void) dealloc
{
  DESTROY(_ctx);
  DESTROY(_uuid);
  DESTROY(_data);
  [super dealloc];
}

- (ETUUID*) uuid
{
  return _uuid;
}
- (COObjectContext*) objectContext
{
  return _ctx;
}

- (BOOL) isFault
{
  return _data == NULL;
}

- (void) didAwaken
{
  // FIXME: remove
  NSLog(@"COObject %@ awoke. uuid: %@ data: %@", self, _uuid, _data);
}

- (NSArray *)properties
{
  [self loadIfNeeded];
  return [_data allKeys];
}

/**
 * If the returned value is an array/set, if it is modified, the context
 * must be notified.
 */
- (id)_mutableValueForProperty: (NSString*)key
{
  [self loadIfNeeded];
  return [_data valueForKey: key];
}

- (id) valueForProperty:(NSString *)key
{
  id obj = [self _mutableValueForProperty: key];
  
  // Make sure we return an immutable collection
  if ([obj isKindOfClass: [NSArray class]])
  {
    return [NSArray arrayWithArray: obj];
  }
  if ([obj isKindOfClass: [NSSet class]])
  {
    return [NSSet setWithSet: obj];
  }
  else
  {
    return obj;
  }
}

+ (BOOL) isPrimitiveCoreObjectValue: (id)value
{
  return [value isKindOfClass: [NSNumber class]] ||
    [value isKindOfClass: [NSValue class]] ||
    [value isKindOfClass: [NSDate class]] ||
    [value isKindOfClass: [NSData class]] ||
    [value isKindOfClass: [NSString class]] ||
    [value isKindOfClass: [COObject class]];
}

+ (BOOL) isCoreObjectValue: (id)value
{
  if ([value isKindOfClass: [NSArray class]] ||
      [value isKindOfClass: [NSSet class]])
  {
    for (id subvalue in value)
    {
      if (![COObject isPrimitiveCoreObjectValue: subvalue])
      {
        return NO;
      }
    }
    return YES;
  }
  else 
  {
    return [COObject isPrimitiveCoreObjectValue: value];
  }
}

- (void) setValue:(id)value forProperty:(NSString*)key
{
  [self loadIfNeeded];
  
  if (value == nil)
  {
    [_data removeObjectForKey: key];
  }
  else
  {
    if ([COObject isCoreObjectValue: value])
    {
      if ([value isKindOfClass: [NSArray class]]
          || [value isKindOfClass: [NSSet class]])
      {
        // Collections must be mutable
        value = [[value mutableCopy] autorelease];
      }
      
      [_data setValue: value
               forKey: key];
    }
    else
    {
      [NSException raise: NSInvalidArgumentException format: @"Invalid property type"];
    }
  }

  [self setModified];
}

- (NSString*)description
{
  if ([self isFault])
  {
    return [NSString stringWithFormat: @"<Faulted COObject %p UUID=%@>", self, _uuid];  
  }
  else
  {
    return [NSString stringWithFormat: @"<COObject %p UUID=%@ data=%@>", self, _uuid, _data];  
  }
}

@end


@implementation COObject (Private)

- (id) initWithContext: (COObjectContext*)ctx uuid: (ETUUID*)uuid data: (NSDictionary *)data
{
  SUPERINIT;
  _ctx = [ctx retain];
  _uuid = [uuid retain];
  [self setData: data];
  //NSLog(@"Initialized with data: %@", data);
  return self;
}

- (id) initFaultedObjectWithContext: (COObjectContext*)ctx uuid: (ETUUID*)uuid
{
  SUPERINIT;
  _ctx = [ctx retain];
  _uuid = [uuid retain];
  //NSLog(@"Initialized Faulted");
  return self;
}

- (void) loadIfNeeded
{
  if (nil == _data)
  {
    [self setData: [[_ctx storeCoordinator] dataForObjectWithUUID: _uuid
                                           atHistoryGraphNode: [_ctx baseHistoryGraphNode]]];
  }
}

- (void) unload
{
  [_data release];
  _data = nil;
}

/**
 * Returns sha1(sha1(key1), sha1(val1), sha1(key2), sha1(val2), ...)
 */
- (NSData*)sha1Hash
{
  [self loadIfNeeded];
  
  NSMutableData *result = [NSMutableData data];
  for (NSString *key in [_data allKeys])
  {
    [result appendData: [key sha1Hash]];
    
    NSData *valHash;
    if ([[_data valueForKey: key] isKindOfClass: [COObject class]])
    {
      valHash = [[[[_data valueForKey: key] uuid] stringValue] sha1Hash];
    }
    else
    {
      valHash = [[_data valueForKey: key] sha1Hash];
    }
    [result appendData: valHash];
  }
  return [result sha1Hash];
}

- (void) setModified
{
  [[self objectContext] markObjectUUIDChanged: [self uuid]];
}

@end



@implementation COObject (PropertyListImportExport)

+ (NSArray*) arrayPropertyListForArray: (NSArray *)array
{
  NSMutableArray *newArray = [NSMutableArray arrayWithCapacity: [array count]];
  for (id value in array)
  {
    if ([value isKindOfClass: [COObject class]])
    {
      value = [(COObject*)value referencePropertyList];
    }
    [newArray addObject: value];
  }
  return newArray;
}

- (NSDictionary*) propertyList
{
  [self loadIfNeeded];
  
  // Create a copy of _data with COObject instances replaced with the
  // result of calling -referencePropertyList
  NSMutableDictionary *keysAndValues = [NSMutableDictionary dictionaryWithCapacity: [_data count]];
  for (id key in [_data allKeys])
  {
    id value = [_data valueForKey: key];
    if ([value isKindOfClass: [COObject class]])
    {
      value = [value referencePropertyList];
    }
    else if ([value isKindOfClass: [NSArray class]])
    {
      value = [COObject arrayPropertyListForArray: value];
    }
    else if ([value isKindOfClass: [NSSet class]])
    {
      value = [NSDictionary dictionaryWithObjectsAndKeys:
        @"unorderedCollection", @"type",
        [COObject arrayPropertyListForArray: [value allObjects]], @"objects",
        nil];
    }
    [keysAndValues setValue: value forKey: key];
  }

  return [NSDictionary dictionaryWithObjectsAndKeys:
    @"object-data", @"type",
    [_uuid stringValue], @"uuid",
    keysAndValues, @"keysAndValues",
    nil];
}

- (NSDictionary*) referencePropertyList
{
  return [NSDictionary dictionaryWithObjectsAndKeys:
    @"object-ref", @"type",
    [_uuid stringValue], @"uuid",
    nil];
}

- (NSObject *)parsePropertyList: (NSObject*)plist
{
  if ([plist isKindOfClass: [NSDictionary class]])
  {
    if ([[plist valueForKey: @"type"] isEqualToString: @"object-ref"])
    {
      ETUUID *uuid = [ETUUID UUIDWithString: [(NSDictionary*)plist objectForKey: @"uuid"]];
      return [[self objectContext] objectForUUID: uuid];
    }
    else if ([[plist valueForKey: @"type"] isEqualToString: @"unorderedCollection"])
    {
      NSArray *objects = [plist valueForKey: @"objects"];
      NSMutableSet *set = [NSMutableSet setWithCapacity: [objects count]];
      for (int i=0; i<[objects count]; i++)
      {
        [set addObject: [self parsePropertyList: [objects objectAtIndex:i]]];
      }
      return set;
    }
  }
  else if ([plist isKindOfClass: [NSArray class]])
  {
    NSUInteger count = [(NSArray*)plist count];
    id mapped[count];
    for (int i=0; i<count; i++)
    {
      mapped[i] = [self parsePropertyList: [(NSArray*)plist objectAtIndex:i]];
    }
    return [NSArray arrayWithObjects: mapped count: count];
  }
  return plist;
}

/**
 * This takes a data dictionary from the store and replaces object references
 * with actual (faulted) COObject instances
 */
- (void)setData: (NSDictionary*)data
{
  ASSIGN(_data, [NSMutableDictionary dictionaryWithDictionary: [data valueForKey: @"keysAndValues"]]);
  
  for (NSString *key in [_data allKeys])
  {
    [_data setValue: [self parsePropertyList: [_data objectForKey: key]]
            forKey: key];
  }
  
  [self didAwaken];
}

@end