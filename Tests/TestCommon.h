#import <Foundation/Foundation.h>
#import <UnitKit/UnitKit.h>
#import "COSQLiteStore.h"
#import "COSQLiteStore+Attachments.h"
#import "COPath.h"
#import "COItem.h"

#import "CORevisionID.h"
#import "COMacros.h"
#import "COStore.h"
#import "COPersistentRoot.h"
#import "COBranch.h"

#import "CORevision.h"
#import "COPersistentRootState.h"
#import "COBranchState.h"

#import "COItemTree.h"
#import "COItemPath.h"
#import "COEditingContext.h"
#import "COObject.h"

#import "COEdit.h"
#import "COEditCreateBranch.h"
#import "COEditDeleteBranch.h"
#import "COEditSetCurrentBranch.h"
#import "COEditSetCurrentVersionForBranch.h"
#import "COEditSetMetadata.h"
#import "COEditSetBranchMetadata.h"

#import "COSchemaTemplate.h"
#import "COSchemaRegistry.h"

#import "CORelationshipCache.h"

#import "COBinaryReader.h"
#import "COBinaryWriter.h"
#import "COItem+Binary.h"
#import "COSearchResult.h"
#import "COCopier.h"


#define STOREPATH [@"~/om6teststore" stringByExpandingTildeInPath]
#define STOREURL [NSURL fileURLWithPath: STOREPATH]

@interface COSQLiteStoreTestCase : NSObject
{
    COSQLiteStore *store;
}

@end
