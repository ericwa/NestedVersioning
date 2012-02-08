#import <Foundation/Foundation.h>
#import "EWTest.h"
#import "COStore.h"
#import "COPath.h"
#import "COItem.h"
#import "COStorePrivate.h"
#import "COPersistentRootEditingContext.h"
#import "COMacros.h"
#import "COSubtree.h"
#import "COSubtreeFactory.h"
#import "COSubtreeFactory+PersistentRoots.h"
#import "COSubtreeFactory+Undo.h"
#import "COSubtreeFactory+Pull.h"
#import "COItemDiff.h"

#define STOREPATH [@"~/om5teststore" stringByExpandingTildeInPath]

COStore *setupStore(void);

void testSubtree(void);
void testUndo(void);
void testTagging(void);
void testTreeManager(void);
void testPull(void);