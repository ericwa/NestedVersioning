#import <Foundation/Foundation.h>
#import <UnitKit/UnitKit.h>
#import "COArrayDiff.h"
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

#import "COSubtreeDiff.h"
#import "COSubtreeEdits.h"

#define STOREPATH [@"~/om5teststore" stringByExpandingTildeInPath]

COStore *setupStore(void);
