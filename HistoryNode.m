#import "HistoryNode.h"

@implementation HistoryNode

@synthesize parentHistoryNodeIndices;
@synthesize historyNodeMetadata;
@synthesize childEmbeddedObject;

- (id)init
{
    self = [super init];
    if (self)
    {
    }    
    return self;
}

- (id) copyWithZone:(NSZone *)zone
{
    EmbeddedObject *newChildEmbeddedObject = [[self.childEmbeddedObject copyWithZone: zone] autorelease];
    return [[[self class] historyNodeWithParentHistoryNodeIndices: self.parentHistoryNodeIndices
                                              historyNodeMetadata: self.historyNodeMetadata
                                              childEmbeddedObject: newChildEmbeddedObject] retain];
}

+ (HistoryNode*) historyNodeWithParentHistoryNodeIndices: (NSIndexSet*)parentHistoryNodeIndices
                                     historyNodeMetadata: (NSDictionary*)historyNodeMetadata
                                     childEmbeddedObject: (EmbeddedObject*)childEmbeddedObject
{
    HistoryNode *obj = [[self alloc] init];
    obj.parentHistoryNodeIndices = [[[NSMutableIndexSet alloc] initWithIndexSet: parentHistoryNodeIndices] autorelease];;
    obj.historyNodeMetadata = historyNodeMetadata;
    obj.childEmbeddedObject = childEmbeddedObject;
    
    return [obj autorelease];
}

// debug

- (NSString *) logWithIndent: (unsigned int)i
{
    NSMutableString *res = [NSMutableString string];
    [res appendFormat: @"%@{historynode=%p parents=%@ metadata: %@\n", [LogIndent indent: i], self, 
        [LogIndent logIndexSet: parentHistoryNodeIndices],
        [LogIndent logDictionary: historyNodeMetadata]];
    
    [res appendFormat: @"%@\n", [childEmbeddedObject logWithIndent: i + 1]];
    
    [res appendFormat: @"%@}", [LogIndent indent: i]];
    return res;        
}

- (void) checkSanityWithOwner: (BaseObject*)owner
{
    for (NSUInteger index = [parentHistoryNodeIndices firstIndex]; index != NSNotFound; index = [parentHistoryNodeIndices indexGreaterThanIndex: index])
    {
        if (index >= [((UndoNode*)owner).historyNodes count])
        {
            [NSException raise: NSInternalInconsistencyException
                        format: @"index in parentHistoryNodeIndices out of bounds"];
        }
    }
    
    if (![childEmbeddedObject isKindOfClass: [EmbeddedObject class]])
    {
        [NSException raise: NSInternalInconsistencyException
                    format: @"childEmbeddedObject must be EmbeddedObject"];
    }
    
    [childEmbeddedObject checkSanityWithOwner: self];
}

@end
