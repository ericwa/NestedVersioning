#import <Foundation/Foundation.h>
#import "Common.h"

@class EmbeddedObject;

/**
 * Will be inside a NamedBranch
 */
@interface HistoryNode : BaseObject 
{
    HistoryNode *parentHistoryNode; //weak
    NSMutableArray *childHistoryNodes; //strong

    /**
     * commit log message, date, etc.
     */
    NSDictionary *historyNodeMetadata; 
    
    /**
     * actual contents
     */
    BaseObject *childEmbeddedObject; // strong
}

@property (readwrite, nonatomic, assign) HistoryNode *parentHistoryNode;
@property (readwrite, nonatomic, retain) NSMutableArray *childHistoryNodes;
@property (readwrite, nonatomic, copy) NSDictionary *historyNodeMetadata;
@property (readwrite, nonatomic, retain) BaseObject *childEmbeddedObject;

- (id) copyWithZone:(NSZone *)zone;
+ (HistoryNode*) historyNodeWithParentHistoryNode: (HistoryNode*)parentHistoryNode
                                childHistoryNodes: (NSArray*)childHistoryNodes
                              historyNodeMetadata: (NSDictionary*)historyNodeMetadata
                              childEmbeddedObject: (BaseObject*)childEmbeddedObject;

@end
