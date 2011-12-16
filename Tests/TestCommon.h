#import <Foundation/Foundation.h>
#import "EWTest.h"
#import "COStore.h"
#import "COPath.h"
#import "COItem.h"
#import "COStorePrivate.h"
#import "COMacros.h"
#import "COItemDiff.h"

#define STOREPATH [@"~/om5teststore" stringByExpandingTildeInPath]

COStore *setupStore();

void testUndo();
void testTagging();
void testTreeManager();