OOLITE_ROOT = .
include $(OOLITE_ROOT)/Config/oolite-shared.make

.PHONY: all clean

all: ooconftool


ooconftool: OoliteBase
	$(MAKE) -C Tools/ooconftool


OoliteBase:
	$(MAKE) -C Components/OoliteBase


OoliteGraphics: OoliteBase
	$(MAKE) -C Components/OoliteGraphics



clean:
	$(MAKE) -C Components/OoliteBase clean
	$(MAKE) -C Components/OoliteGraphics clean
	$(MAKE) -C Tools/ooconftool clean
	
	$(RM) -rf "$(OUTPUT_PLATFORM_DIR)"
