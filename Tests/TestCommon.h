#import <Foundation/Foundation.h>
#import "EWTest.h"
#import "COStore.h"
#import "COPath.h"
#import "COItem.h"
#import "COStorePrivate.h"
#import "COPersistentRootEditingContext.h"
#import "COMacros.h"
#import "COPersistentRootEditingContext+PersistentRoots.h"
#import "COPersistentRootEditingContext+Convenience.h"
#import "COItemTreeNode.h"
#import "COItemFactory.h"
#import "COItemDiff.h"

#define STOREPATH [@"~/om5teststore" stringByExpandingTildeInPath]

COStore *setupStore();

void testUndo();
void testTagging();
void testTreeManager();