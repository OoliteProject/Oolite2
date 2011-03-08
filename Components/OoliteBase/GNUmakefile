FRAMEWORK_NAME = OoliteBase
OOLITE_ROOT = ../../

include $(OOLITE_ROOT)/Config/oolite-shared.make


SOURCE_PATHS = Source:Dependencies/JAValueToString
vpath %.c $(SOURCE_PATHS)
vpath %.h $(SOURCE_PATHS)
vpath %.m $(SOURCE_PATHS)

ADDITIONAL_ALLCFLAGS		+= $(WARNING_CFLAGS)
ADDITIONAL_CFLAGS			+= $(ADDITIONAL_ALLCFLAGS)
ADDITIONAL_OBJCFLAGS		+= $(ADDITIONAL_ALLCFLAGS)

ADDITIONAL_INCLUDE_DIRS		= -IDependencies/JAValueToString


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

# Missing: JAValueToString.
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


include $(GNUSTEP_MAKEFILES)/framework.make
