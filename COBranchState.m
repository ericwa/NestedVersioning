#import "COBranchState.h"
#import "COMacros.h"

NSString *kCOBranchUUID= @"COBranchUUID";
NSString *kCOBranchHeadRevisionId= @"COBranchHeadRevisionId";
NSString *kCOBranchTailRevisionId= @"COBranchTailRevisionId";
NSString *kCOBranchCurrentState= @"COBranchCurrentState";
NSString *kCOBranchMetadata= @"COBranchMetadata";

@implementation COBranchState

@synthesize UUID = uuid_;
@synthesize headRevisionID = headRevisionId_;
@synthesize tailRevisionID = tailRevisionId_;
@synthesize currentRevisionID = currentState_;
@synthesize deleted = deleted_;

- (NSDictionary *)metadata
{
    return metadata_;
}

- (void) setMetadata:(NSDictionary *)metadata
{
    ASSIGN(metadata_, metadata);
}

- (id) initWithUUID: (COUUID *)aUUID
     headRevisionId: (CORevisionID *)head
     tailRevisionId: (CORevisionID *)tail
       currentState: (CORevisionID *)state
           metadata: (NSDictionary *)metadata
{
    NSParameterAssert([aUUID isKindOfClass: [COUUID class]]);
    
    SUPERINIT;
    
    uuid_ = [aUUID copy];
    [self setHeadRevisionID: head];
    [self setTailRevisionID: tail];
    [self setCurrentRevisionID: state];
    [self setMetadata: metadata];
    
    return self;
}

- (id) initWithBranchPlist: (COBranchState *)aPlist
{
    return [self initWithUUID: aPlist->uuid_
               headRevisionId: aPlist->headRevisionId_
               tailRevisionId: aPlist->tailRevisionId_
                 currentState: aPlist->currentState_
                     metadata: aPlist->metadata_];
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[COBranchState alloc] initWithBranchPlist: self];
}

- (void) dealloc
{
    [uuid_ release];
    [headRevisionId_ release];
    [tailRevisionId_ release];
    [currentState_ release];
    [metadata_ release];
    [super dealloc];
}

// Plist import/export

- (id) initWithPlist: (id)aPlist
{
    return [self initWithUUID: [COUUID UUIDWithString: [aPlist objectForKey: kCOBranchUUID]]
               headRevisionId: [CORevisionID revisionIDWithPlist: [aPlist objectForKey: kCOBranchHeadRevisionId]]
               tailRevisionId: [CORevisionID revisionIDWithPlist: [aPlist objectForKey: kCOBranchTailRevisionId]]
                 currentState: [CORevisionID revisionIDWithPlist: [aPlist objectForKey: kCOBranchCurrentState]]
                     metadata: [aPlist objectForKey: kCOBranchMetadata]];
}

- (id) plist
{
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    [results setObject: [uuid_ stringValue] forKey: kCOBranchUUID];
    [results setObject: [headRevisionId_ plist] forKey: kCOBranchHeadRevisionId];
    [results setObject: [tailRevisionId_ plist] forKey: kCOBranchTailRevisionId];
    [results setObject: [currentState_ plist] forKey: kCOBranchCurrentState];
    if (metadata_ != nil)
    {
        [results setObject: metadata_  forKey: kCOBranchMetadata];
    }
    return results;
}

- (BOOL) isEqual:(id)object
{
    if ([object isKindOfClass: [self class]])
    {
        COBranchState *other = (COBranchState *)object;
        return [uuid_ isEqual: other->uuid_]
        && [headRevisionId_ isEqual: other->headRevisionId_]
        && [tailRevisionId_ isEqual: other->tailRevisionId_]
        && [currentState_ isEqual: other->currentState_]
        && ([metadata_ isEqual: other->metadata_]
            || (metadata_ == nil && other->metadata_ == nil));
    }
    return NO;
}

- (NSUInteger) hash
{
    return [uuid_ hash];
}

- (NSString *) description
{
    return [[self plist] description];
}

@end
