#
# This file generated by pbxbuild 
#

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME=StoreBrowser

VERSION=1

$(APP_NAME)_OBJC_FILES=\
	COItem.m\
	COSubtreeFactory.m\
	COSubtreeFactory+PersistentRoots.m\
	COSubtreeFactory+Undo.m\
	COPath.m\
	COPersistentRootEditingContext.m\
	COStore.m\
	COType+Diff.m\
	COType+Plist.m\
	COType+String.m\
	COType.m\
	Diff/../COSubtreeDiff.m\
	Diff/COArrayDiff.m\
	Diff/COItemDiff.m\
	Diff/COObjectGraphDiff.m\
	Diff/COSequenceDiff.m\
	Diff/COSetDiff.m\
	Diff/COStringDiff.m\
	ETUUID.m\
	StoreBrowser/AppDelegate.m\
	StoreBrowser/EWGraphRenderer.m\
	StoreBrowser/EWHistoryGraphView.m\
	StoreBrowser/EWOutlineView.m\
	StoreBrowser/EWPersistentRootOutlineRow.m\
	StoreBrowser/EWPersistentRootWindowController.m\
	StoreBrowser/main.m\
	Tests/TestCommon.m\
	Tests/TestTagging.m\
	COSubtree.m\
	COSubtreeCopy.m\
	COItemPath.m

$(APP_NAME)_CC_FILES=\
	Diff/diff.cc

$(APP_NAME)_RESOURCE_FILES=\
	StoreBrowser/PersistentRootWindow.nib\
	StoreBrowser/arrow_branch.png\
	StoreBrowser/arrow_branch_purple.png\
	StoreBrowser/brick.png\
	StoreBrowser/bullet_yellow.png\
	StoreBrowser/bullet_yellow_multiple.png\
	StoreBrowser/package.png\
	StoreBrowser/Credits.rtf\
	StoreBrowser/InfoPlist.strings\
	StoreBrowser/MainMenu.xib

$(APP_NAME)_MAIN_MODEL_FILE=MainMenu.xib

$(APP_NAME)_LANGUAGES=\
	English

$(APP_NAME)_INCLUDE_DIRS=\
	-I./Tests\
	-I./Diff\
	-I./StoreBrowser\
	-I./Scraps

$(APP_NAME)_LIB_DIRS=

ADDITIONAL_NATIVE_LIBS+= crypto

ADDITIONAL_CFLAGS += -std=c99
ADDITIONAL_OBJCFLAGS += -std=c99

ADDITIONAL_CPPFLAGS+= -DGNUSTEP

include $(GNUSTEP_MAKEFILES)/application.make
