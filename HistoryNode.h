#import <Foundation/Foundation.h>
#import "Common.h"

@class EmbeddedObject;

/**
 * Will be inside a NamedBranch
 */
@interface HistoryNode : BaseObject 
{
    NSMutableIndexSet *parentHistoryNodeIndices;

    /**
     * commit log message, date, etc.
     */
    NSDictionary *historyNodeMetadata; 
    
    /**
     * actual contents
     */
    EmbeddedObject *childEmbeddedObject; // strong
}

@property (readwrite, nonatomic, retain) NSMutableIndexSet *parentHistoryNodeIndices;
@property (readwrite, nonatomic, copy) NSDictionary *historyNodeMetadata;
@property (readwrite, nonatomic, retain) EmbeddedObject *childEmbeddedObject;

- (id) copyWithZone:(NSZone *)zone;
+ (HistoryNode*) historyNodeWithParentHistoryNodeIndices: (NSIndexSet*)parentHistoryNodeIndices
                                     historyNodeMetadata: (NSDictionary*)historyNodeMetadata
                                     childEmbeddedObject: (BaseObject*)childEmbeddedObject;

@end
