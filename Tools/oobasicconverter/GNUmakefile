OOLITE_TARGET				=	oobasicconverter
OOLITE_ROOT					=	../../
TOOL_NAME					=	$(OOLITE_TARGET)

include $(OOLITE_ROOT)/Config/oolite-shared.make

oobasicconverter_VERSION	=	$(OOLITE_VERSION)


SOURCE_PATHS = Source
vpath %.c $(SOURCE_PATHS)
vpath %.h $(SOURCE_PATHS)
vpath %.m $(SOURCE_PATHS)


ADDITIONAL_OBJC_LIBS		=	-lOoliteBase -lOoliteGraphics $(OOLITE_GL_LIBS)

ADDITIONAL_INCLUDE_DIRS		+=	-I$(OOLITE_INCLUDE_DIR) $(OO_SDL_INCLUDE_DIR)
ADDITIONAL_LIB_DIRS			=	-L$(OOLITE_OBJ_DIR)


ADDITIONAL_CFLAGS			+=	$(ADDITIONAL_ALLCFLAGS)
ADDITIONAL_OBJCFLAGS		+=	$(ADDITIONAL_ALLCFLAGS)


oobasicconverter_VERSION	=	$(OOLITE_VERSION)


oobasicconverter_OBJC_FILES	=	oobasicconverter.m


-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
