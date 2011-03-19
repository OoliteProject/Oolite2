OOLITE_TARGET				=	OoliteGraphics
OOLITE_ROOT					=	../../
LIBRARY_NAME				=	$(OOLITE_TARGET)

include $(OOLITE_ROOT)/Config/oolite-shared.make


SOURCE_PATHS = Source
vpath %.c $(SOURCE_PATHS)
vpath %.h $(SOURCE_PATHS)
vpath %.m $(SOURCE_PATHS)


ADDITIONAL_OBJC_LIBS		=	-lOoliteBase $(OO_GL_LIBS) $(OO_PNG_LIB)

ADDITIONAL_INCLUDE_DIRS		=	-I$(OOLITE_INCLUDE_DIR) $(OO_SDL_INCLUDE_DIR)
ADDITIONAL_LIB_DIRS			=	-L$(OOLITE_OBJ_DIR)


ADDITIONAL_CFLAGS			+=	$(ADDITIONAL_ALLCFLAGS)
ADDITIONAL_OBJCFLAGS		+=	$(ADDITIONAL_ALLCFLAGS)


OOGFX_RENDERING_FILES		=	OOOpenGLExtensionManager.m \
								OOOpenGLUtilities.m \
								OORenderMesh.m

OOGFX_PIXMAP_FILES			=	OOPixMap.m \
								OOPixMapChannelOperations.m \
								OOPixMapScaling.m

OOGFX_ABSTRACT_FILES		=	OOAbstractFace.m \
								OOAbstractFaceGroup.m \
								OOAbstractMesh.m \
								OOAbstractMesh+NormalSynthesis.m \
								OOAbstractMesh+Winding.m \
								OOAbstractVertex.m

# Missing: OOCTMReader.m (has extra dependencies)
OOGFX_READER_FILES			=	OODATLexer.m \
								OODATReader.m \
								OOMeshReader.m \
								OOMeshReading.m \
								OOOBJLexer.m \
								OOOBJReader.m

OOGFX_WRITER_FILES			=	OODATWriter.m \
								OOMeshWriter.m

OOGFX_UTILITY_FILES			=	OOColor.m \
								OOFloatArray.m \
								OOIndexArray.m \
								JAPropertyListRepresentation.m

OoliteGraphics_OBJC_FILES	=	$(OOGFX_RENDERING_FILES) \
								$(OOGFX_PIXMAP_FILES) \
								$(OOGFX_ABSTRACT_FILES) \
								$(OOGFX_READER_FILES) \
								$(OOGFX_WRITER_FILES) \
								$(OOGFX_UTILITY_FILES)

OoliteGraphics_HEADER_FILES	=	JAPropertyListRepresentation.h \
								OOAbstractFace.h \
								OOAbstractFaceGroup.h \
								OOAbstractMesh.h \
								OOAbstractMesh+NormalSynthesis.h \
								OOAbstractMesh+Winding.h \
								OOAbstractVertex.h \
								OOColor.h \
								OOCTMReader.h \
								OODATReader.h \
								OODATWriter.h \
								OOFloatArray.h \
								OOIndexArray.h \
								OoliteGraphics.h \
								OOMacroOpenGL.h \
								OOMaterialSpecification.h \
								OOMeshReader.h \
								OOMeshReading.h \
								OOMeshWriter.h \
								OOOBJLexer.h \
								OOOBJReader.h \
								OOOpenGL.h \
								OOOpenGLExtensionManager.h \
								OOOpenGLUtilities.h \
								OOPixMap.h \
								OOPixMapChannelOperations.h \
								OOPixMapScaling.h \
								OOProgressReporting.h \
								OORenderMesh.h \
								OOShaderProgram.h \
								OOTexture.h \
								OOTextureGenerator.h \
								OOTextureLoader.h \
								OOTextureSpecification.h


-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
-include GNUmakefile.postamble
