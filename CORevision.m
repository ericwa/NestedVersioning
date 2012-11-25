#import "CORevision.h"
#import "COMacros.h"

@implementation CORevision

NSString *kCORevisionID = @"CORevisionID";
NSString *kCORevisionParentID = @"CORevisionParentID";
NSString *kCORevisionMetadata = @"CORevisionMetadata";

- (id) initWithRevisionId: (CORevisionID *)revisionId
         parentRevisionId: (CORevisionID *)parentRevisionId
                 metadata: (NSDictionary *)metadata
{
    NSParameterAssert(revisionId != nil);
    
    SUPERINIT;
    ASSIGN(revisionId_, revisionId);
    ASSIGN(parentRevisionId_, parentRevisionId);
    ASSIGN(metadata_, metadata);
    return self;
}

- (void) dealloc
{
    [revisionId_ release];
    [parentRevisionId_ release];
    [metadata_ release];
    [super dealloc];
}

- (CORevisionID *)revisionId
{
    return revisionId_;
}
- (CORevisionID *)parentRevisionId
{
    return parentRevisionId_;
}
- (NSDictionary *)metadata
{
    return metadata_;
}

- (BOOL) isEqual:(id)object
{
    if ([object isKindOfClass: [CORevision class]])
    {
        return [((CORevision *)object)->revisionId_ isEqual: revisionId_]
            && [((CORevision *)object)->parentRevisionId_ isEqual: parentRevisionId_];
    }
    return NO;
}

- (NSUInteger) hash
{
    return [revisionId_ hash] ^ 15497645834521126867ULL;
}

- (id) plist
{
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    [d setObject: [revisionId_ plist] forKey: kCORevisionID];
    if (parentRevisionId_ != nil)
    {
        [d setObject: [parentRevisionId_ plist] forKey: kCORevisionParentID];
    }
    if (metadata_ != nil)
    {
        [d setObject: metadata_ forKey: kCORevisionMetadata];
    }
    return d;
}
+ (CORevision *) revisionWithPlist: (id)plist
{
    return [[[self alloc] initWithRevisionId: [plist objectForKey:kCORevisionID]
                            parentRevisionId: [plist objectForKey: kCORevisionParentID]
                                    metadata: [plist objectForKey: kCORevisionMetadata]] autorelease];
}

- (id) copyWithZone:(NSZone *)zone
{
    return [self retain];
}

- (NSString *)description
{
    if (parentRevisionId_ != nil)
    {
        return [NSString stringWithFormat: @"(Revision %@, Parent %@)", revisionId_, parentRevisionId_];
    }
    return [NSString stringWithFormat: @"(Revision %@)", revisionId_];
}


@end
