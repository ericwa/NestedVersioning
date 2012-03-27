include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME=Sketch
VERSION=1

$(APP_NAME)_OBJC_FILES=\
	$(wildcard *.m)\
	$(wildcard ../*.m)\
	$(wildcard ../Diff/*.m)

$(APP_NAME)_CC_FILES=\
	$(wildcard ../Diff/*.cc)

$(APP_NAME)_RESOURCE_FILES=\
	$(wildcard *.png)\
	$(wildcard *.xib)\
	$(wildcard *.nib)

$(APP_NAME)_MAIN_MODEL_FILE=MainMenu.xib

$(APP_NAME)_LANGUAGES=\
	English

$(APP_NAME)_INCLUDE_DIRS=\
	-I../Diff\
	-I../\
	-I.

$(APP_NAME)_LIB_DIRS=

ADDITIONAL_NATIVE_LIBS+= crypto

ADDITIONAL_CFLAGS += -std=c99 -Wno-unknown-pragmas
ADDITIONAL_OBJCFLAGS += -std=c99 -Wno-unknown-pragmas

ADDITIONAL_CPPFLAGS+= -DGNUSTEP

include $(GNUSTEP_MAKEFILES)/application.make
