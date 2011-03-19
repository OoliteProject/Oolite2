.PHONY: all

all: ooconftool

ooconftool: OoliteBase
	$(MAKE) -C Tools/ooconftool


OoliteBase:
	$(MAKE) -C Components/OoliteBase

