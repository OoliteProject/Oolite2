include $(GNUSTEP_MAKEFILES)/common.make
include $(OOLITE_ROOT)/Config/oolite-version.inc


# Configurable options. Standard option packages are defined with the "style"
# parameter, which may be "debug", "developer" or "enduser".
# If no style is specified, but debug=yes, the debug style is used. Otherwise,
# the default style is developer.
# 
# Other supported flags:
#   gldebug=yes				In debug style, also use extra OpenGL error testing.
#   profile=yes				Enable gprof profiling support.

ifndef style
	ifeq ($(debug),yes)
		style=debug
	else
		style=developer
	endif
endif

ifneq ($(style),debug)
	ifneq ($(style),developer)
		ifneq ($(style),enduser)
			# Actually halts with "*** commands commence before first target." Oh, well.
			$(error "Invalid style '$(style)' - must be 'debug', 'developer' or 'enduser'.")
		endif
	endif
endif



# "developer" configuration is the default and the baseline.
#ifeq ($(style),developer)
	OO_DEBUG					= no
	OO_OPTIMIZE					= yes
	OO_ASSERTIONS				= yes
	OO_LEAN						= no
	OO_DEVELOPER_EXTRAS			= yes
	
	STYLE_DIR					= "Developer"
#endif

ifeq ($(style),debug)
	OO_DEBUG					= yes
	OO_OPTIMIZE					= no
	
	STYLE_DIR					= "Debug"
endif

ifeq ($(style),enduser)
	OO_ASSERTIONS				= no
	OO_LEAN						= yes
	OO_DEVELOPER_EXTRAS			= no
	
	STYLE_DIR					= "EndUser"
endif


ifeq ($(OO_DEBUG),yes)
	ADDITIONAL_ALLCFLAGS		+= -DDEBUG=1 -DOO_DEBUG=1 -g
	ifeq ($(gldebug),yes)
		ADDITIONAL_ALLCFLAGS	+= -DOO_CHECK_GL_HEAVY=1
	endif
	# $(debug) is used by GNUstep-make.
	debug						= yes
endif

ifeq ($(OO_OPTIMIZE),yes)
	ADDITIONAL_ALLCFLAGS		+= -O3
else
	ADDITIONAL_ALLCFLAGS		+= -O0
endif

ifneq ($(OO_ASSERTIONS),yes)
	ADDITIONAL_ALLCFLAGS		+= -DNDEBUG=1
endif

ifeq ($(OO_LEAN),yes)
	ADDITIONAL_ALLCFLAGS		+= -DOOLITE_LEAN=1
endif

ifeq ($(OO_DEVELOPER_EXTRAS),yes)
	ADDITIONAL_ALLCFLAGS		+= -DOO_LOCALIZATION_TOOLS=1
else
	OO_EXCLUDE_DEBUG_SUPPORT	+= -DOO_EXCLUDE_DEBUG_SUPPORT=1
endif

ifeq ($(profile),yes)
	ADDITIONAL_ALLCFLAGS		+= -g -pg
endif




ADDITIONAL_ALLCFLAGS			+= -std=gnu99 -DOOLITE_VERSION="\"$(OOLITE_VERSION)\""
WARNING_CFLAGS					= -Wall \
								  -Wextra \
								  -Wno-unused-parameter \
								  -Wno-missing-field-initializers \
								  -Wno-missing-braces \
								  -Wreturn-type \
								  -Wunused-variable


ifeq ($(GNUSTEP_HOST_OS),mingw32)
	ADDITIONAL_ALLCFLAGS		+= -DWIN32
	PLATFORM_DIR				= Win32
else
	ADDITIONAL_ALLCFLAGS		+= -DLINUX
	PLATFORM_DIR				= Unix
endif


OUTPUT_BASE_DIR = "$(OOLITE_ROOT)/build/$(PLATFORM_DIR)/$(STYLE_DIR)"
GNUSTEP_BUILD_DIR = "$(OUTPUT_BASE_DIR)"
