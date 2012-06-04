#import <Foundation/Foundation.h>
#import <UnitKit/UnitKit.h>
#import "COStore.h"
#import "COPath.h"
#import "COItem.h"

#import "COBranch.h"
#import "COPersistentRoot.h"
#import "COPersistentRootState.h"
#import "COPersistentRootStateDelta.h"
#import "COPersistentRootStateToken.h"
#import "COSubtree.h"
#import "COMacros.h"
#import "COSubtree.h"

#define STOREPATH [@"~/om5teststore" stringByExpandingTildeInPath]
#define STOREURL [NSURL fileURLWithPath: STOREPATH]
COStore *setupStore(void);
