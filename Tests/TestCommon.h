#import <Foundation/Foundation.h>
#import "EWTest.h"
#import "COStore.h"
#import "COPath.h"
#import "COStoreItem.h"
#import "COStorePrivate.h"
#import "COPersistentRootEditingContext.h"
#import "COMacros.h"
#import "COPersistentRootEditingContext+PersistentRoots.h"
#import "COPersistentRootEditingContext+Convenience.h"
#import "COStoreItemTree.h"
#import "COItemFactory.h"

#define STOREPATH [@"~/om5teststore" stringByExpandingTildeInPath]

COStore *setupStore();

void testUndo();
void testTagging();