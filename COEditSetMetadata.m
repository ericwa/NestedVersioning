#import "COEditSetMetadata.h"
#import "COMacros.h"

@implementation COEditSetMetadata : COEdit

static NSString *kCOOldMetadata = @"COOldMetadata";
static NSString *kCONewMetadata = @"CONewMetadata";

- (id) initWithOldMetadata: (NSDictionary *)oldMeta
               newMetadata: (NSDictionary *)newMeta
                      UUID: (COUUID*)aUUID
                      date: (NSDate*)aDate
               displayName: (NSString*)aName
         operationMetadata: (NSDictionary *)opMetadata
{
    NILARG_EXCEPTION_TEST(newMeta);
    
    self = [super initWithUUID: aUUID date: aDate displayName: aName operationMetadata: opMetadata];
    ASSIGN(old_, [NSDictionary dictionaryWithDictionary: oldMeta]);
    ASSIGN(new_, [NSDictionary dictionaryWithDictionary: newMeta]);
    return self;
}


- (id) initWithPlist: (id)plist
{
    self = [super initWithPlist: plist];
    
    ASSIGN(old_, [plist objectForKey: kCOOldMetadata]);
    ASSIGN(new_, [plist objectForKey: kCONewMetadata]);
    
    return self;
}

- (id)plist
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [result addEntriesFromDictionary: [super plist]];
    [result setObject: old_ forKey: kCOOldMetadata];
    [result setObject: new_ forKey: kCONewMetadata];
    [result setObject: kCOEditSetMetadata forKey: kCOUndoAction];
    return result;
}

- (COEdit *) inverseForApplicationTo: (COPersistentRootState *)aProot
{
    return [[[[self class] alloc] initWithOldMetadata: new_
                                          newMetadata: old_
                                                 UUID: uuid_
                                                 date: date_
                                          displayName: displayName_
                                    operationMetadata: operationMetadata_] autorelease];
}

- (void) applyToPersistentRoot: (COPersistentRootState *)aProot
{
    [aProot setMetadata: new_];
}

+ (BOOL) isUndoable
{
    return YES;
}

@end
