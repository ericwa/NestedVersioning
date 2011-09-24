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
    
    // set parent pointer
    obj.childEmbeddedObject.parent = obj;
    return [obj autorelease];
}

@end
