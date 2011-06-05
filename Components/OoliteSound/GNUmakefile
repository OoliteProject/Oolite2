OOLITE_TARGET				=	OoliteSound
OOLITE_ROOT					=	../../
LIBRARY_NAME				=	$(OOLITE_TARGET)

include $(OOLITE_ROOT)/Config/oolite-shared.make


SOURCE_PATHS = Source
vpath %.c $(SOURCE_PATHS)
vpath %.h $(SOURCE_PATHS)
vpath %.m $(SOURCE_PATHS)


ADDITIONAL_OBJC_LIBS		=	-lOoliteBase

ADDITIONAL_INCLUDE_DIRS		=	-I$(OOLITE_INCLUDE_DIR) $(OO_SDL_INCLUDE_DIR)
ADDITIONAL_LIB_DIRS			=	-L$(OOLITE_OBJ_DIR)


ADDITIONAL_CFLAGS			+=	$(ADDITIONAL_ALLCFLAGS)
ADDITIONAL_OBJCFLAGS		+=	$(ADDITIONAL_ALLCFLAGS)


OOSND_FOO_FILES				=	OOFoo.m

OoliteSound_OBJC_FILES		=	$(OOSND_FOO_FILES)

OoliteSound_HEADER_FILES	=	OoliteSOund.h


-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
-include GNUmakefile.postamble
