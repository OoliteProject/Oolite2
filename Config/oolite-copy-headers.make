# Postamble script to copy headers for library/pseudo-framework projects.

ifndef CP_FLAGS
	CP_FLAGS                         = -rf
	
	ifeq ($(findstring -gnu,$(GNUSTEP_HOST_OS)),-gnu)
		CP_FLAGS                     += -u
	endif
endif

ifndef CP
	CP = cp
endif

ifndef RM
	RM = rm
endif


ifndef SRC_DIR
	SRC_DIR = Source
endif

ifndef DST_DIR
	DST_DIR = "$(OOLITE_INCLUDE_DIR)/$(OOLITE_TARGET)"
endif


after-all::
	$(MKDIRS) $(DST_DIR)
	$(CP) $(CP_FLAGS) $(addprefix $(SRC_DIR)/,$($(OOLITE_TARGET)_HEADER_FILES)) $(DST_DIR)

after-clean::
	$(RM) -rf $(DST_DIR)
