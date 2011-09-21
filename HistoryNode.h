#import <Foundation/Foundation.h>
#import "Common.h"

@class EmbeddedObject;

@interface HistoryNode : BaseObject 
{
    // parent (inherited from BaseObject) is a NamedBranch
    
    HistoryNode *parentHistoryNode; //weak
    NSArray *childHistoryNodes; //strong

    /**
     * commit log message, date, etc.
     */
    NSDictionary *historyNodeMetadata; 
    
    /**
     * actual contents
     */
    EmbeddedObject *childEmbeddedObject; // strong
}

@property (readwrite, nonatomic, assign) HistoryNode *parentHistoryNode;
@property (readwrite, nonatomic, retain) NSArray *childHistoryNodes;
@property (readwrite, nonatomic, copy) NSDictionary *historyNodeMetadata;
@property (readwrite, nonatomic, retain) EmbeddedObject *childEmbeddedObject;

- (id) copyWithZone:(NSZone *)zone;
+ (HistoryNode*) historyNodeWithParentHistoryNode: (HistoryNode*)parentHistoryNode
                                childHistoryNodes: (NSArray*)childHistoryNodes
                              historyNodeMetadata: (NSDictionary*)historyNodeMetadata
                              childEmbeddedObject: (EmbeddedObject*)childEmbeddedObject;

@end
