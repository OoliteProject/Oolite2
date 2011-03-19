OOLITE_TARGET				= OoliteBase
OOLITE_ROOT					= ../../
LIBRARY_NAME				= $(OOLITE_TARGET)

include $(OOLITE_ROOT)/Config/oolite-shared.make


SOURCE_PATHS = Source
vpath %.c $(SOURCE_PATHS)
vpath %.h $(SOURCE_PATHS)
vpath %.m $(SOURCE_PATHS)

ADDITIONAL_ALLCFLAGS		+= $(WARNING_CFLAGS)
ADDITIONAL_CFLAGS			+= $(ADDITIONAL_ALLCFLAGS)
ADDITIONAL_OBJCFLAGS		+= $(ADDITIONAL_ALLCFLAGS)


OOBASE_CORE_FILES			=	OOCocoa.m \
								MYCollectionUtilities.m

OOBASE_LOGGING_FILES		=	OOLogOutputHandler.m \
								OOLogging.m

OOBASE_MATHS_FILES			=	OOBoundingBox.m \
								OOMatrix.m \
								OOQuaternion.m \
								OORandom.m \
								OOVector.m

OOBASE_OOCONF_FILES			=	OOConfGeneration.m \
								OOConfParsing.m \
								OOConfLexer.m

OOBASE_UTILITY_FILES		=	NSDataOOExtensions.m \
								NSDictionaryOOExtensions.m \
								NSNumberOOExtensions.m \
								NSObjectOOExtensions.m \
								NSScannerOOExtensions.m \
								NSStringOOExtensions.m \
								NSThreadOOExtensions.m \
								OOAsyncQueue.m \
								OOBaseStringParsing.m \
								OOCollectionExtractors.m \
								OOCPUInfo.m \
								OODeepCopy.m \
								OOExcludeObjectEnumerator.m \
								OOFilteringEnumerator.m \
								OOIsNumberLiteral.m \
								OOPListParsing.m \
								OOPriorityQueue.m \
								OOProbabilitySet.m \
								OOProblemReporting.m \
								OOSimpleMethodType.m \
								OOWeakReference.m


OoliteBase_OBJC_FILES		=	$(OOBASE_CORE_FILES) \
								$(OOBASE_LOGGING_FILES) \
								$(OOBASE_MATHS_FILES) \
								$(OOBASE_OOCONF_FILES) \
								$(OOBASE_UTILITY_FILES)

OoliteBase_HEADER_FILES		=	MYCollectionUtilities.h \
								NSDataOOExtensions.h \
								NSDictionaryOOExtensions.h \
								NSNumberOOExtensions.h \
								NSObjectOOExtensions.h \
								NSScannerOOExtensions.h \
								NSStringOOExtensions.h \
								NSThreadOOExtensions.h \
								OOAsyncQueue.h \
								OOBaseErrors.h \
								OOBaseStringParsing.h \
								OOBoundingBox.h \
								OOCocoa.h \
								OOCollectionExtractors.h \
								OOConfGeneration.h \
								OOConfGenerationInternal.h \
								OOConfLexer.h \
								OOConfParsing.h \
								OOConfParsingInternal.h \
								OOCPUInfo.h \
								OODeepCopy.h \
								OOExcludeObjectEnumerator.h \
								OOFastArithmetic.h \
								OOFilteringEnumerator.h \
								OOFunctionAttributes.h \
								OOGarbageCollectionSupport.h \
								OOIsNumberLiteral.h \
								OoliteBase.h \
								OOLogging.h \
								OOLogOutputHandler.h \
								OOMaths.h \
								OOMatrix.h \
								OOPListParsing.h \
								OOPriorityQueue.h \
								OOProbabilitySet.h \
								OOProblemReporting.h \
								OOQuaternion.h \
								OORandom.h \
								OOSimpleMethodType.h \
								OOVector.h \
								OOWeakReference.h


-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
-include GNUmakefile.postamble
