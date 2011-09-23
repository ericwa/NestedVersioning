#import <Foundation/Foundation.h>
#import "VersionedObject.h"

@implementation VersionedObject

@synthesize undoNodes;
@synthesize currentNodeIndex;

- (id) init
{
    self = [super init];
    if (self)
    {
    }    
    return self;
}

+ (VersionedObject *) objectWithUndoNodes: (NSArray*)undoNodes
                    currentNodeIndex: (NSUInteger)currentNodeIndex
{
    VersionedObject *obj = [[self alloc] init];
    obj.undoNodes = undoNodes;
    obj.currentNodeIndex = currentNodeIndex;
    
    // Check types and set parent pointers of objects in undoNodes
    for (UndoNode *node in obj.undoNodes)
    {
        if (![node isKindOfClass: [UndoNode class]])
        {
            [NSException raise: NSInvalidArgumentException
                        format: @"%@ not a UndoNode", node];
        }
        node.parent = obj;
    }
    
    return [obj autorelease];
}

- (id) copyWithZone:(NSZone *)zone;
{
    NSArray *newUndoNodes = [[undoNodes copyWithZone: zone] autorelease];
    return [[[self class] objectWithUndoNodes: newUndoNodes
                             currentNodeIndex: self.currentNodeIndex] retain];
}

+ (VersionedObject *) versionedObjectWrappingEmbeddedObject: (EmbeddedObject*)object
{
    return nil;
}

// manipulation

- (void)commitNewVersionOfEmbeddedObject: (EmbeddedObject*)object
                      withCommitMetadata: (NSDictionary*)metadata
{
    //??
}

- (void)_navigateToUndoNodeAtIndex: (NSUInteger)index
{
    self.currentNodeIndex = index;
}

- (void)navigateToUndoNode: (UndoNode*)node
{
    NSUInteger i = 0;
    for (UndoNode *n in undoNodes)
    {
        if (n == node)
        {
            [self _navigateToUndoNodeAtIndex: i];
        }
        i++;
    }
    [NSException raise: NSInvalidArgumentException
                format: @"-[%@ %@]: Node not found",
                        NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
}

// access

- (UndoNode *) currentUndoNode
{
    return [undoNodes objectAtIndex: currentNodeIndex];
}
- (HistoryNode *) currentHistoryNode
{
    return [[self currentUndoNode] currentHistoryNode];
}
- (BaseObject *) currentEmbeddedObject
{
    return [self currentHistoryNode].childEmbeddedObject;
}

@end
