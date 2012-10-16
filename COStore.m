#import "COStore.h"
#import "COMacros.h"
#import "COSubtree.h"

#import "COBranch.h"
#import "COPersistentRoot.h"
#import "COPersistentRootState.h"
#import "COPersistentRootStateDelta.h"
#import "COPersistentRootStateToken.h"

#import "COUndoAction.h"
#import "COUndoActionDeleteBranch.h"
#import "COUndoActionSetCurrentBranch.h"
#import "COUndoActionSetCurrentVersionForBranch.h"


NSString * const COStorePersistentRootMetadataDidChangeNotification = @"COStorePersistentRootMetadataDidChangeNotification";
NSString * const COStoreNotificationUUID = @"COStoreNotificationUUID";

static NSString *kCOStoreMetadataPlistPath = @"metadata.plist";

static NSString *kCOUndoActions = @"COUndoActions";
static NSString *kCORedoActions = @"CORedoActions";
static NSString *kCOPersistentRoot = @"COPersistentRoot";

@implementation COStore

- (id)initWithURL: (NSURL*)aURL
{
	self = [super init];
	url = [aURL retain];
	
	BOOL isDirectory;
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath: [url path]
													   isDirectory: &isDirectory];
	
	if (!exists)
	{
		if (![[NSFileManager defaultManager] createDirectoryAtPath: [url path]
									  withIntermediateDirectories: YES
													   attributes: nil
															error: NULL])
		{
			[self release];
			[NSException raise: NSGenericException
						format: @"Error creating store at %@", [url path]];
			return nil;
		}    
	}
	// assume it is a valid store if it exists... (may not be of course)
	
	return self;
}

- (void)dealloc
{
	[url release];
	[super dealloc];
}

- (NSURL*)URL
{
	return url;
}

/** @taskunit persistent roots */

- (COPersistentRootState *) _fullStateForPath: (NSString *)aPath
{
    NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile: aPath];
    return [[[COPersistentRootState alloc] initWithPlist: plist] autorelease];
}

- (NSString *) _fullStateDirForUUID: (COUUID *)aUUID
{
   return [[url path] stringByAppendingPathComponent:
            [[aUUID stringValue] stringByAppendingString: @".persistentRootStorage"]];
}

- (NSString *) _fullStatePathForToken: (COPersistentRootStateToken *)aToken
{
    NSString *fileName = [NSString stringWithFormat: @"%lld.plist", (long long int)[aToken _index]];
    
    NSString *path = [[self _fullStateDirForUUID: [aToken _prootCache]]
                      stringByAppendingPathComponent: fileName];
    
    return path;
}

- (COPersistentRootState *) fullStateForToken: (COPersistentRootStateToken *)aToken
{
    return [self _fullStateForPath: [self _fullStatePathForToken: aToken]];
}

- (COPersistentRootStateDelta *) deltaStateForToken: (COPersistentRootStateToken *)aToken
                                            basedOn: (COPersistentRootStateToken **)outBasedOn
{
    assert(0);
    return nil;
}

/** @taskunit persistent roots */

/**
 * This is the path to the mutable part of the store
 */
- (NSString *) storeMetadataPlistPath
{
    return [[url path] stringByAppendingPathComponent: kCOStoreMetadataPlistPath];
}

/*
 
 store metadata plist structure:
 
 {
 uuid : 
     {
     kCOUndoActions : [ .. ]
     kCORedoActions : [ .. ]
     kCOPersistentRoot : plist
     }
 
 */

- (NSMutableDictionary *) readStoreMetadataPlist
{
    return [NSMutableDictionary dictionaryWithContentsOfFile: [self storeMetadataPlistPath]];
}

- (BOOL) writeStoreMetadataPlist: (NSDictionary *)aPlist
{
    return [aPlist writeToFile: [self storeMetadataPlistPath] atomically: YES];
}

/** @taskunit reading persistent roots */

//
// we could have a bunch of methods for querying the state of a persistent root,
// but it's faster to just read the entire state in one go.
//

- (COPersistentRoot *) persistentRootWithUUID: (COUUID *)aUUID
{
    assert(aUUID != nil);
    NSDictionary *md = [self readStoreMetadataPlist];
    NSDictionary *container = [md objectForKey: [aUUID stringValue]];
    NSDictionary *plist = [container objectForKey: kCOPersistentRoot];
    
    return [[[COPersistentRoot alloc] initWithPlist: plist] autorelease];
}

- (NSArray *) allPersistentRootUUIDs
{
    NSArray *strings = [[self readStoreMetadataPlist] allKeys];
    NSMutableArray *result = [NSMutableArray array];
    for (NSString *string in strings)
    {
        [result addObject: [COUUID UUIDWithString: string]];
    }
    
    return result;
}

/** @taskunit writing */

- (BOOL) _writePersistentRoot: (COPersistentRoot *)aProot
                  undoActions: (NSArray *)undoActions
                  redoActions: (NSArray *)redoActions
{
    NSMutableArray *undoPlists = [NSMutableArray array];
    for (COUndoAction *undoAction in undoActions)
    {
        [undoPlists addObject: [undoAction plist]];
    }
    
    NSMutableArray *redoPlists = [NSMutableArray array];
    for (COUndoAction *redoAction in redoActions)
    {
        [redoPlists addObject: [redoAction plist]];
    }
    
    NSDictionary *prootContainer = D(undoPlists, kCOUndoActions,
                                     redoPlists, kCORedoActions,
                                     [aProot plist], kCOPersistentRoot);
    
    NSMutableDictionary *md = [NSMutableDictionary dictionaryWithDictionary: [self readStoreMetadataPlist]];
    [md setObject: prootContainer
           forKey: [[aProot UUID] stringValue]];
    
    BOOL ok = [self writeStoreMetadataPlist: md];
    
    // Post notification
    
    NSDictionary *info = [NSDictionary dictionaryWithObject: [aProot UUID]
                                                     forKey: COStoreNotificationUUID];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: COStorePersistentRootMetadataDidChangeNotification
                                                        object: self
                                                      userInfo: info];
    
    return ok;    
}

/**
 * aKey is kCOUndoActions or kCORedoActions
 */
- (NSMutableArray *) _undoActionsForKey: (NSString *)aKey proot: (COUUID *)aProot
{
    NSMutableArray *result = [NSMutableArray array];
    for (id plist in [[[self readStoreMetadataPlist] objectForKey: [aProot stringValue]] objectForKey: aKey])
    {
        [result addObject: [COUndoAction undoActionWithPlist: plist]];
    }
    return result;
}

- (BOOL) _writePersistentRoot: (COPersistentRoot *)aRoot
             andAddUndoAction: (COUndoAction *)action
{
    NSMutableArray *undoActions = [self _undoActionsForKey: kCOUndoActions proot: [aRoot UUID]];
    NSMutableArray *redoActions = [self _undoActionsForKey: kCORedoActions proot: [aRoot UUID]];
    
    if ([redoActions count] > 0)
    {
        NSLog(@"N.B. writing with a nonempty redo stack so it is getting cleared");
        [redoActions removeAllObjects];
    }
    
    if (action != nil)
    {
        [undoActions addObject: action];
    }
    else
    {
        NSLog(@"Warning, updating proot metadata without inserting undo action");
    }
    
    // Write the actual data
    return [self _writePersistentRoot: aRoot undoActions: undoActions redoActions: redoActions];
}

/**
 * create a fresh new cache directory
 */
- (BOOL) _createCache: (COUUID *)name
{
    return [[NSFileManager defaultManager] createDirectoryAtPath: [self _fullStateDirForUUID: name]
                                     withIntermediateDirectories: YES
                                                      attributes: nil
                                                           error: NULL];
}

- (COPersistentRootStateToken *) _unusedTokenForCache: (COUUID *)name
{
    NSArray *files = [[NSFileManager defaultManager] directoryContentsAtPath: [self _fullStateDirForUUID: name]];
    
    int64_t max = -1;
    for (NSString *file in files)
    {
        int64_t num = (int64_t)[file longLongValue];
        if (num > max) max = num;
    }

    return [[COPersistentRootStateToken alloc] initWithProotCache: name index: max + 1];
}

- (BOOL) _writeFullState: (COPersistentRootState *)aState
                  toPath: (NSString *)aPath
{
    return [[aState plist] writeToFile: aPath atomically: YES];
}


- (BOOL) _writeFullState: (COPersistentRootState *)aState
                  forToken: (COPersistentRootStateToken *)aToken
{
    return [self _writeFullState: aState
                          toPath: [self _fullStatePathForToken: aToken]];
}

//
// Each of these mutates a SINGLE PERSISTENT ROOT.
//
// Atomicity: any changes made within a persistent root are atomic.
//

- (COPersistentRoot *) createPersistentRootWithInitialContents: (COPersistentRootState *)contents
{
    COUUID *newUUID = [COUUID UUID];
    [self _createCache: newUUID];
    
    COPersistentRootStateToken *newToken = [self _unusedTokenForCache: newUUID];
    BOOL ok =[self _writeFullState: contents
                          forToken: newToken];
    assert(ok);
    
    COUUID *branchUUID = [COUUID UUID];
    
    COBranch *branch = [[[COBranch alloc] initWithUUID: branchUUID
                                                  name: @"my branch"
                                          initialState:newToken metadata:nil] autorelease];
    
    COPersistentRoot *result = [[[COPersistentRoot alloc] initWithUUID: newUUID
                                                              branches: [NSArray arrayWithObject: branch]
                                                         currentBranch: [branch UUID]
                                                              metadata: nil] autorelease];
    ok = [self _writePersistentRoot: result
                   andAddUndoAction: nil];
    assert(ok);
    
    return result;
}




- (COPersistentRoot *) createCopyOfPersistentRoot: (COUUID *)aRoot
{
    COPersistentRoot *newRoot = [[self persistentRootWithUUID: aRoot] persistentRootWithNewName];
    [self _writePersistentRoot: newRoot
              andAddUndoAction: nil];
    return newRoot;
}

- (COPersistentRoot *)createPersistentRootByCopyingBranch: (COUUID *)aBranch
                                         ofPersistentRoot: (COUUID *)aRoot
{
    COPersistentRoot *newRoot = [[self persistentRootWithUUID: aRoot] persistentRootCopyingBranch: aBranch];
    [self _writePersistentRoot: newRoot
              andAddUndoAction: nil];
    return newRoot;
}

- (BOOL) deletePersistentRoot: (COUUID *)aRoot
{
    NSMutableDictionary *prootDict = [NSMutableDictionary dictionaryWithDictionary: [self readStoreMetadataPlist]];
    [prootDict removeObjectForKey: [aRoot stringValue]];
    return [self writeStoreMetadataPlist: prootDict];
}

// branches

- (BOOL) deleteBranch: (COUUID *)aBranch
     ofPersistentRoot: (COUUID *)aRoot
{
    COPersistentRoot *newRoot = [self persistentRootWithUUID: aRoot];
    
    COBranch *branch = [newRoot branchForUUID: aBranch];
    [newRoot deleteBranch: aRoot];
    
    COUndoAction *action = [[[COUndoActionDeleteBranch alloc] initWithBranch:branch
                                                           isUndoingCreation:NO
                                                                        UUID:aRoot
                                                                        date:[NSDate date]
                                                                 displayName:[NSString stringWithFormat: @"Delete Branch %@",
                                                                              [branch name]]] autorelease];
    
    return [self _writePersistentRoot: newRoot
                     andAddUndoAction: action];
}

- (BOOL) setCurrentBranch: (COUUID *)aBranch
		forPersistentRoot: (COUUID *)aRoot
{
    COPersistentRoot *newRoot = [self persistentRootWithUUID: aRoot];
    COBranch *newBranch = [newRoot branchForUUID: aBranch];
    
    COUndoAction *action = [[[COUndoActionSetCurrentBranch alloc] initWithOldBranchUUID:[[newRoot currentBranch] UUID]
                                                                          newBranchUUID:aBranch
                                                                                   UUID:aRoot
                                                                                   date:[NSDate date]
                                                                            displayName:[NSString stringWithFormat: @"Switch to Branch %@",
                                                                                         [newBranch name]]] autorelease];

    [newRoot setCurrentBranch: aRoot];
                            
    return [self _writePersistentRoot: newRoot
                     andAddUndoAction: action];
}

- (COUUID *) createCopyOfBranch: (COUUID *)aBranch
			   ofPersistentRoot: (COUUID *)aRoot
{
    COPersistentRoot *newRoot = [self persistentRootWithUUID: aRoot];
    COBranch *oldBranch = [newRoot branchForUUID: aBranch];
    COBranch *newBranch = [newRoot _makeCopyOfBranch: aBranch];

    COUndoAction *action = [[[COUndoActionDeleteBranch alloc] initWithBranch:newBranch
                                                           isUndoingCreation:YES
                                                                        UUID:aRoot
                                                                        date:[NSDate date]
                                                                 displayName:[NSString stringWithFormat: @"Copy Branch %@",
                                                                              [oldBranch name]]] autorelease];

    [self _writePersistentRoot: newRoot
              andAddUndoAction: action];
    return [newBranch UUID];
}

// adding state

- (COPersistentRootStateToken *) addStateAsDelta: (COPersistentRootStateDelta *)aDelta
                                     parentState: (COPersistentRootStateToken *)parent
{
    assert(0); // deltas not supported yet
}

- (COPersistentRootStateToken *) addState: (COPersistentRootState *)aFullSnapshot
                              parentState: (COPersistentRootStateToken *)parent
{
    COUUID *cacheUuid;
    if (parent == nil)
    {
        cacheUuid = [COUUID UUID];
        [self _createCache: cacheUuid];
    }
    else
    {
        cacheUuid = [parent _prootCache];
    }
    
    [aFullSnapshot setParentStateToken: parent];
    
    COPersistentRootStateToken *newToken = [self _unusedTokenForCache: cacheUuid];
    
    BOOL ok =[self _writeFullState: aFullSnapshot
                          forToken: newToken];
    assert(ok);
    
    return newToken;
}

- (BOOL) setCurrentVersion: (COPersistentRootStateToken*)aVersion
                 forBranch: (COUUID *)aBranch
          ofPersistentRoot: (COUUID *)aRoot
{
    COPersistentRoot *newRoot = [self persistentRootWithUUID: aRoot];

    
    COUndoAction *action = [[[COUndoActionSetCurrentVersionForBranch alloc]
                                initWithBranch: aBranch
                                oldToken: [[newRoot branchForUUID: aBranch] currentState]
                             newToken: aVersion
                             UUID: aRoot
                             date: [NSDate date]
                             displayName: @"Apply Change"] autorelease];
    
    [[newRoot branchForUUID: aBranch] _addCommit: aVersion];
    [[newRoot branchForUUID: aBranch] _setCurrentState: aVersion];
 
    return [self _writePersistentRoot: newRoot
                     andAddUndoAction: action];
}

/** @taskunit syntax sugar */

- (COPersistentRootState *) fullStateForPersistentRootWithUUID: (COUUID *)aUUID
{
    return [self fullStateForToken:
            [[[self persistentRootWithUUID: aUUID] currentBranch] currentState]];
}

- (COPersistentRootState *) fullStateForPersistentRootWithUUID: (COUUID *)aUUID
                                                    branchUUID: (COUUID *)aBranch
{
    return [self fullStateForToken:
            [[[self persistentRootWithUUID: aUUID] branchForUUID: aBranch] currentState]];
}

- (COPersistentRootStateToken *) parentForStateToken: (COPersistentRootStateToken *)aToken
{
    COPersistentRootState *state = [self fullStateForToken: aToken];
    assert(state != nil);
    return [state parentStateToken];
}

/** @taskunit script-based undo/redo log */

// api

- (BOOL) canUndoForPersistentRootWithUUID: (COUUID *)aUUID
{
    return [[self _undoActionsForKey: kCOUndoActions proot: aUUID] count] > 0;
}
- (BOOL) canRedoForPersistentRootWithUUID: (COUUID *)aUUID
{
    return [[self _undoActionsForKey: kCORedoActions proot: aUUID] count] > 0;
}

- (NSString *) undoMenuItemTitleForPersistentRootWithUUID: (COUUID *)aUUID
{
    NSArray *arr = [self _undoActionsForKey: kCOUndoActions proot: aUUID];
    if ([arr count] == 0)
    {
        return @"Undo";
    }
    else
    {
        return [NSString stringWithFormat: @"Undo %@", [[arr objectAtIndex: 0] menuTitle]];
    }
}
- (NSString *) redoMenuItemTitleForPersistentRootWithUUID: (COUUID *)aUUID
{
    NSArray *arr = [self _undoActionsForKey: kCORedoActions proot: aUUID];
    if ([arr count] == 0)
    {
        return @"Redo";
    }
    else
    {
        return [NSString stringWithFormat: @"Redo %@", [[arr objectAtIndex: 0] menuTitle]];
    }
}

- (BOOL) undoForPersistentRootWithUUID: (COUUID *)aUUID
{
    NSMutableArray *undoActions = [self _undoActionsForKey: kCOUndoActions proot: aUUID];
    NSMutableArray *redoActions = [self _undoActionsForKey: kCORedoActions proot: aUUID];

    COUndoAction *action = [undoActions lastObject];
    [redoActions addObject: [action inverse]];
    [undoActions removeLastObject];
    
    COPersistentRoot *proot = [self persistentRootWithUUID: aUUID];
    [action applyToPersistentRoot: proot];
    return [self _writePersistentRoot: proot undoActions: undoActions redoActions: redoActions];
}

- (BOOL) redoForPersistentRootWithUUID: (COUUID *)aUUID
{
    NSMutableArray *undoActions = [self _undoActionsForKey: kCOUndoActions proot: aUUID];
    NSMutableArray *redoActions = [self _undoActionsForKey: kCORedoActions proot: aUUID];
    
    COUndoAction *action = [redoActions lastObject];
    [undoActions addObject: [action inverse]];
    [redoActions removeLastObject];
    
    COPersistentRoot *proot = [self persistentRootWithUUID: aUUID];
    [action applyToPersistentRoot: proot];
    return [self _writePersistentRoot: proot undoActions: undoActions redoActions: redoActions];
}

@end
