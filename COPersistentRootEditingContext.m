#import "COPersistentRootEditingContext.h"
#import "COMacros.h"
#import "COStore.h"
#import "COSubtree.h"
#import "COPersistentRoot.h"
#import "COPersistentRootState.h"
#import "COBranch.h"

@implementation COPersistentRootEditingContext

/** @taskunit creation */

+ (COPersistentRootEditingContext *) contextForNewPersistentRootInStore: (COStore *)aStore
{
    assert(0 && "not implemented");
}

/**
 * creates a new persistent root by copying an existing one
 */
+ (COPersistentRootEditingContext *) contextForCopyingPersistentRootWithUUID: (COUUID *)aUUID
                                                                     inStore: (COStore *)aStore
{
   assert(0 && "not implemented");
}

+ (COPersistentRootEditingContext *) contextForEditingPersistentRootWithUUID: (COUUID *)aUUID
                                                                     inStore: (COStore *)aStore
{
    COPersistentRoot *root = [aStore persistentRootWithUUID: aUUID];
    return [[[self alloc] initWithMetadata: root
                             editingBranch: [[root currentBranch] UUID]
                                   inStore: aStore] autorelease];
}

/**
 * editing a branch of a proot
 */
+ (COPersistentRootEditingContext *) contextForEditingBranch: (COUUID *)aBranch
                                    ofPersistentRootWithUUID: (COUUID *)aUUID
                                                     inStore: (COStore *)aStore
{
    return [[[self alloc] initWithMetadata: [aStore persistentRootWithUUID: aUUID]
                             editingBranch: aBranch
                                   inStore: aStore] autorelease];
}



/**
 * Private init method
 */
- (id)initWithMetadata: (COPersistentRoot *)metadata
         editingBranch: (COUUID *)branch
               inStore: (COStore *)aStore

{
	NILARG_EXCEPTION_TEST(metadata);
	NILARG_EXCEPTION_TEST(branch);
	NILARG_EXCEPTION_TEST(aStore);

    COBranch *branchObj = [metadata branchForUUID: branch];
    if (branchObj == nil)
    {
        [NSException raise: NSInvalidArgumentException
                    format: @"given branch %@ not in persistent root", branch];
    }
    
    SUPERINIT;
	
	ASSIGN(store_, aStore);
	ASSIGN(metadata_, metadata);
	ASSIGN(editingBranch_, branch);
    
	ASSIGN(tree_, [[store_ fullStateForToken: [branchObj currentState]] tree]);
    if (tree_ == nil)
    {
        [NSException raise: NSInvalidArgumentException
                    format: @"given branch %@ not in persistent root", branch];
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	assert(0 && "not implemented");
	return nil;
}

- (void)dealloc
{
	DESTROY(store_);
	DESTROY(metadata_);
	DESTROY(editingBranch_);
	DESTROY(tree_);
	[super dealloc];
}

- (COStore *) store
{
	return store_;
}

- (COPersistentRoot *) persistentRootMetadata
{
    return metadata_;
}

- (COBranch *) editingBranchMetadata
{
    return [metadata_ branchForUUID: editingBranch_];
}

- (COUUID *) UUID
{
    return [metadata_ UUID];
}

- (COPersistentRootStateToken *) commitWithMetadata: (NSDictionary *)theMetadata
{
	if (tree_ == nil)
	{
		[NSException raise: NSInvalidArgumentException
					format: @"called -commitWithMetadata: but tree_ is nil"];
	}
	
	//
	// <<<<<<<<<<<<<<<<<<<<< LOCK DB, BEGIN TRANSACTION <<<<<<<<<<<<<<<<<<<<<
	//
	
	// we need to check if we need to merge, first.
	
	
    COPersistentRootStateToken *token = [[self editingBranchMetadata] currentState];
    
    COPersistentRootState *newState = [COPersistentRootState stateWithTree: tree_];
    COPersistentRootStateToken *token2 = [store_ addState: newState parentState: token];
    
    BOOL ok = [store_ setCurrentVersion: token2 forBranch: editingBranch_ ofPersistentRoot: [self UUID]];

    if (!ok)
    {
        assert(0 && "commit failed");
        return nil;
    }
    
    ASSIGN(metadata_, [store_ persistentRootWithUUID: [self UUID]]);
    
	return token2;
}

- (COSubtree *)persistentRootTree
{
	return tree_;
}

- (void) setPersistentRootTree: (COSubtree *)aSubtree
{
	NILARG_EXCEPTION_TEST(aSubtree);
	ASSIGN(tree_, aSubtree);
}

@end
