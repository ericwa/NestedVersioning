#import "COUndoContext.h"

#import "COMacros.h"
#import "COStore.h"
#import "COUUID.h"

@implementation COUndoContext

- (id) initWithPersistentRootUUIDs: (NSArray *)persistentRootUUIDs
{
    SUPERINIT;
    persistentRootUUIDs_ = [[NSArray alloc] initWithArray: persistentRootUUIDs];
    return self;
}

- (BOOL) canUndo
{
    return [self undoPersistentRootUUID] != nil;
}
- (BOOL) canRedo
{
    return [self redoPersistentRootUUID] != nil;
}

- (COUUID *) undoPersistentRootUUID
{
    COUUID *latestUUID = nil;
    NSDate *latestDate = nil;
    
    for (COUUID *uuid in persistentRootUUIDs_)
    {
        if (![store_ canUndoForPersistentRootWithUUID: uuid])
        {
            continue;
        }
        NSDate *date = [store_ undoActionDateForPersistentRootWithUUID: uuid];
        
        if (latestDate == nil || [date compare: latestDate] == NSOrderedDescending)
        {
            latestDate = date;
            latestUUID = uuid;
        }
    }
    return latestUUID;
}
- (COUUID *) redoPersistentRootUUID
{
    COUUID *latestUUID = nil;
    NSDate *latestDate = nil;
    
    for (COUUID *uuid in persistentRootUUIDs_)
    {
        if (![store_ canRedoForPersistentRootWithUUID: uuid])
        {
            continue;
        }
        NSDate *date = [store_ redoActionDateForPersistentRootWithUUID: uuid];
        
        if (latestDate == nil || [date compare: latestDate] == NSOrderedDescending)
        {
            latestDate = date;
            latestUUID = uuid;
        }
    }
    return latestUUID;
}

- (NSString *) undoMenuItemTitle
{
    return [store_ undoMenuItemTitleForPersistentRootWithUUID: [self undoPersistentRootUUID]];
}
- (NSString *) redoMenuItemTitle
{
    return [store_ redoMenuItemTitleForPersistentRootWithUUID: [self redoPersistentRootUUID]];
}

- (BOOL) undo
{
    return [store_ redoForPersistentRootWithUUID: [self redoPersistentRootUUID]];
}

- (BOOL) redo
{
    return [store_ redoForPersistentRootWithUUID: [self redoPersistentRootUUID]];
}

@end
