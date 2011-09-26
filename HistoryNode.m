#import "HistoryNode.h"

@implementation HistoryNode

@synthesize parentHistoryNode;
@synthesize childHistoryNodes;
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
    NSArray *newChildHistoryNodes = [[self.childHistoryNodes copyWithZone: zone] autorelease];
    EmbeddedObject *newChildEmbeddedObject = [[self.childEmbeddedObject copyWithZone: zone] autorelease];
    return [[[self class] historyNodeWithParentHistoryNode: self.parentHistoryNode
                                          childHistoryNodes: newChildHistoryNodes
                                        historyNodeMetadata: self.historyNodeMetadata
                                        childEmbeddedObject: newChildEmbeddedObject] retain];
}

+ (HistoryNode*) historyNodeWithParentHistoryNode: (HistoryNode*)parentHistoryNode
                                childHistoryNodes: (NSArray*)childHistoryNodes
                              historyNodeMetadata: (NSDictionary*)historyNodeMetadata
                              childEmbeddedObject: (BaseObject*)childEmbeddedObject
{
    HistoryNode *obj = [[self alloc] init];
    obj.parentHistoryNode = parentHistoryNode;
    obj.childHistoryNodes = [NSMutableArray arrayWithArray: childHistoryNodes];
    obj.historyNodeMetadata = historyNodeMetadata;
    obj.childEmbeddedObject = childEmbeddedObject;
    
    return [obj autorelease];
}

// debug

- (NSString *) logWithIndent: (unsigned int)i
{
    NSMutableString *res = [NSMutableString string];
    [res appendFormat: @"%@{historynode=%p parent=%p children=(", [LogIndent indent: i], self, parentHistoryNode];
    
    // print the children (connections in the history node graph)
    
    for (NSUInteger j=0; j<[self.childHistoryNodes count]; j++)        
    {
        [res appendFormat: @"%p", [self.childHistoryNodes objectAtIndex: j]];
        if (j < [self.childHistoryNodes count] - 1)
            [res appendFormat: @", "];
    }
    
    [res appendFormat: @") metadata: %@\n",
        [LogIndent logDictionary: historyNodeMetadata]];
    
    [res appendFormat: @"%@\n", [childEmbeddedObject logWithIndent: i + 1]];
    
    [res appendFormat: @"%@}", [LogIndent indent: i]];
    return res;        
}

@end
