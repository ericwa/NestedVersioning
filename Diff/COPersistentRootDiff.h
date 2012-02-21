#import <Foundation/Foundation.h>

@class COPath;
@class COStore;

/*
 Since nested persistent roots are conceptually "embedded" inside their parent,
 as far as version control is concerned, we need a diff strategy that diffs
 nested persistent roots in an intelligent way.
 
 This is analogous to git (et. al.) comparing two "tags" and merging them.
 
 
 aside: How about updating a branch with changes from another branch?
 
 void pull_changes_from_branch(dest_branch_uuid, src_branch_path)
 {
 // first see if dest_branch_uuid can simply be fast-forwarded to src_branch_path.
 // if not, find LCA and do 3-way merge.
 }
 
 
 void diff_version_with_version(version_a_uuid, version_b_uuid)
 {
 
 }
 
 void diff_branch_with_branch(branch_a_path, branch_b_path)
 {
 // record metadata changes normally.
 
 // for the branch contents:
 // first compute the referenced versions: branch_a_version, branch_b_version
 
 // IDEA:
 // next see if branch_b_version is a ancestor or descendent of branch_a_version.
 // --->problem is, that doesn't give any useful information when merging.
 //     i.e. 'branch diff A->B says "fast forward to X", branch diff A->C says
 //     "fast forward to Y"' is useless for merging. so we have to actually
 //     open the destination versions and diff them.
 
 // so next just do:
 // diff_version_with_version(branch_a_version, branch_b_version);
 }
 
 void diff_proot_with_proot(proot_a_path, proot_b_path)
 {
 // call diff_branch_with_branch on branches that appear in both proots.
 // otherwise, record the added/removed branches, and any other metadata changes, normally.
 } 
 
 
 */

@interface COPersistentRootDiff : NSObject
{

}

// FIXME: another constructor that takes an in-memory COPersistentRoot?

- (id) initWithPath: (COPath *)aRootOrBranchA
			andPath: (COPath *)aRootOrBranchB
			inStore: (COStore *)aStore; 

@end
