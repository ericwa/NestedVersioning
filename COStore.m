#import "COStore.h"
#import "COMacros.h"

#import "COPersistentRootEditingContext.h"
#import "COSubtree.h"

#import "COBranch.h"
#import "COPersistentRoot.h"
#import "COPersistentRootState.h"
#import "COPersistentRootStateDelta.h"
#import "COPersistentRootStateToken.h"

NSString *kCOPersistentRootsPlistPath = @"persistentRoots.plist";

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
- (NSString *) persistentRootsPlistPath
{
    return [[url path] stringByAppendingPathComponent: kCOPersistentRootsPlistPath];
}

- (NSDictionary *) readPersistentRootsPlist
{
    return [NSDictionary dictionaryWithContentsOfFile: [self persistentRootsPlistPath]];
}

- (BOOL) writePersistentRootsPlist: (NSDictionary *)aPlist
{
    return [aPlist writeToFile: [self persistentRootsPlistPath] atomically: YES];
}

/** @taskunit reading persistent roots */

//
// we could have a bunch of methods for querying the state of a persistent root,
// but it's faster to just read the entire state in one go.
//

- (COPersistentRoot *) persistentRootWithUUID: (COUUID *)aUUID
{
    assert(aUUID != nil);
    
    NSDictionary *proots = [self readPersistentRootsPlist];
    
    id plist = [proots objectForKey: [aUUID stringValue]];
    
    assert(plist != nil);
    
    return [[[COPersistentRoot alloc] initWithPlist: plist] autorelease];
}

- (NSArray *) allPersistentRootUUIDs
{
    NSArray *strings = [[self readPersistentRootsPlist] allKeys];
    NSMutableArray *result = [NSMutableArray array];
    for (NSString *string in strings)
    {
        [result addObject: [COUUID UUIDWithString: string]];
    }
    
    return result;
}

/** @taskunit writing */

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
    ok = [self _writePersistentRoot: result];
    assert(ok);
    
    return result;
}

- (BOOL) _writePersistentRoot: (COPersistentRoot *)aRoot
{
    NSMutableDictionary *prootDict = [NSMutableDictionary dictionaryWithDictionary: [self readPersistentRootsPlist]];
    [prootDict setObject: [aRoot plist] forKey: [[aRoot UUID] stringValue]];
    return [self writePersistentRootsPlist: prootDict];
}



- (COPersistentRoot *) createCopyOfPersistentRoot: (COUUID *)aRoot
{
    COPersistentRoot *newRoot = [[self persistentRootWithUUID: aRoot] persistentRootWithNewName];
    [self _writePersistentRoot: newRoot];
    return newRoot;
}

- (COPersistentRoot *)createPersistentRootByCopyingBranch: (COUUID *)aBranch
                                         ofPersistentRoot: (COUUID *)aRoot
{
    COPersistentRoot *newRoot = [[self persistentRootWithUUID: aRoot] persistentRootCopyingBranch: aBranch];
    [self _writePersistentRoot: newRoot];
    return newRoot;
}

- (BOOL) deletePersistentRoot: (COUUID *)aRoot
{
    NSMutableDictionary *prootDict = [NSMutableDictionary dictionaryWithDictionary: [self readPersistentRootsPlist]];
    [prootDict removeObjectForKey: [aRoot stringValue]];
    return [self writePersistentRootsPlist: prootDict];
}

// branches

- (BOOL) deleteBranch: (COUUID *)aBranch
     ofPersistentRoot: (COUUID *)aRoot
{
    COPersistentRoot *newRoot = [self persistentRootWithUUID: aRoot];
    [newRoot deleteBranch: aRoot];
    return [self _writePersistentRoot: newRoot];
}

- (BOOL) setCurrentBranch: (COUUID *)aBranch
		forPersistentRoot: (COUUID *)aRoot
{
    COPersistentRoot *newRoot = [self persistentRootWithUUID: aRoot];
    [newRoot setCurrentBranch: aRoot];
    return [self _writePersistentRoot: newRoot];
}

- (COUUID *) createCopyOfBranch: (COUUID *)aBranch
			   ofPersistentRoot: (COUUID *)aRoot
{
    COPersistentRoot *newRoot = [self persistentRootWithUUID: aRoot];
    COBranch *newBranch = [newRoot _makeCopyOfBranch: aBranch];
    [self _writePersistentRoot: newRoot];
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
    [[newRoot branchForUUID: aBranch] _addCommit: aVersion];
    [[newRoot branchForUUID: aBranch] _setCurrentState: aVersion];
    return [self _writePersistentRoot: newRoot];
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

@end
