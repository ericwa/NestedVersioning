#import <Foundation/Foundation.h>
#import "EWTest.h"
#import "COStore.h"
#import "COPath.h"
#import "COStoreItem.h"
#import "COStorePrivate.h"
#import "COPersistentRootEditingContext.h"
#import "Common.h"
#import "COPersistentRootEditingContext+PersistentRoots.h"
#import "COStoreItemTree.h"

#define STOREPATH [@"~/om5teststore" stringByExpandingTildeInPath]

COStore *setupStore();

void testUndo();
