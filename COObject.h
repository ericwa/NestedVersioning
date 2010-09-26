#import <EtoileFoundation/EtoileFoundation.h>
#import "COObjectContext.h"
#import "COHistoryGraphNode.h"

@class COObjectContext;

/**
 * 'Working copy' of an object.
 * Owned by an Object Context.
 *
 * One UUID can only have one COObject in a given Object Context,
 * but multiple object contexts can exist in a process with their own
 * COObject for a particular UUID.
 *
 * COObjects can only exist in the context of a COObjectContext, becasue
 * they rely on the conxtext to resolve fault references to other COObjects.
 *
 * You should use ETUUID's to refer to objects outside of the context
 * of a COObjectContext.
 */
@interface COObject : NSObject
{
@private
  ETEntityDescription *_description;
  NSMutableDictionary *_data;
  COObjectContext *_ctx;
  ETUUID *_uuid;
}

// Public

/**
 * Creates a new object (generates a new UUID) in the given context.
 */
- (id) initWithContext: (COObjectContext*)ctx;

- (BOOL) isEqual: (id)otherObject;

- (ETUUID*) uuid;
- (COObjectContext*) objectContext;

- (BOOL) isFault;

/**
 * Does nothing, overried in subclasses. Do not call.
 * Called by the framework when a COObject instance is changed by the
 * framework.
 */
- (void) didAwaken;
- (void) didTurnIntoFault;

- (NSArray *)properties;
- (id) valueForProperty:(NSString *)key;
- (void) setValue:(id)value forProperty:(NSString*)key;


@end


@interface COObject (Private)

- (id) initFaultedObjectWithContext: (COObjectContext*)ctx uuid: (ETUUID*)uuid;
- (id) initWithContext: (COObjectContext*)ctx uuid: (ETUUID*)uuid data: (NSDictionary *)data;
- (NSData*)sha1Hash;
- (void)loadIfNeeded;
- (id)_mutableValueForProperty: (NSString*)key;
- (void) setModified;

@end


// FIXME: these are a bit of a mess
@interface COObject (PropertyListImportExport)

+ (NSArray*) arrayPropertyListForArray: (NSArray *)array;
- (NSDictionary*) propertyList;
- (NSDictionary*) referencePropertyList;

- (NSObject *)parsePropertyList: (NSObject*)plist;
/**
 * This takes a data dictionary from the store and replaces object references
 * with actual (faulted) COObject instances
 */
- (void)setData: (NSDictionary*)data;

@end
