OOLITE_TARGET				= ooconftool
OOLITE_ROOT					= ../../
TOOL_NAME					= $(OOLITE_TARGET)

include $(OOLITE_ROOT)/Config/oolite-shared.make

ooconftool_VERSION			= $(OOLITE_VERSION)


SOURCE_PATHS = Source
vpath %.c $(SOURCE_PATHS)
vpath %.h $(SOURCE_PATHS)
vpath %.m $(SOURCE_PATHS)

ADDITIONAL_CFLAGS			+= $(ADDITIONAL_ALLCFLAGS)
ADDITIONAL_OBJCFLAGS		+= $(ADDITIONAL_ALLCFLAGS)

ooconftool_VERSION			= $(OOLITE_VERSION)


ooconftool_OBJC_FILES		=	ooconftool.m \
								OldSchoolPropertyListWriting.m


ADDITIONAL_TOOL_LIBS		= -lOoliteBase

ADDITIONAL_INCLUDE_DIRS		= -I$(OOLITE_INCLUDE_DIR)
ADDITIONAL_LIB_DIRS			= -L$(OOLITE_OBJ_DIR)


-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
