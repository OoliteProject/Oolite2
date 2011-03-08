include $(GNUSTEP_MAKEFILES)/common.make
include $(OOLITE_ROOT)/Config/oolite-version.inc


ADDITIONAL_ALLCFLAGS		= -std=gnu99 -DOOLITE_VERSION="\"$(OOLITE_VERSION)\""
WARNING_CFLAGS				= -Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers -Wno-missing-braces -Wreturn-type -Wunused-variable


ifeq ($(GNUSTEP_HOST_OS),mingw32)
	ADDITIONAL_ALLCFLAGS	+= -DWIN32
else
	ADDITIONAL_ALLCFLAGS	+= -DLINUX
endif
