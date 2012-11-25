#import <Foundation/Foundation.h>
#import <UnitKit/UnitKit.h>
#import "COSQLiteStore.h"
#import "COPath.h"
#import "COItem.h"

#import "CORevisionID.h"
#import "COSubtree.h"
#import "COMacros.h"
#import "COSubtree.h"

#import "COStoreEditQueue.h"
#import "COPersistentRootEditQueue.h"
#import "COBranchEditQueue.h"

#define STOREPATH [@"~/om5teststore" stringByExpandingTildeInPath]
#define STOREURL [NSURL fileURLWithPath: STOREPATH]
COSQLiteStore *setupStore(void);
