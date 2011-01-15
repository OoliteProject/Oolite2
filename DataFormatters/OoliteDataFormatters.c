/*
	Actually, the data formatter code is built into Oolite itself in Debug and
	TestRelease configurations. However, data formatter bundles are formally
	required to export this symbol.
*/

#include <stdlib.h>
#if 0
#include "/Developer/Applications/Xcode.app/Contents/PlugIns/GDBMIDebugging.xcplugin/Contents/Headers/DataFormatterPlugin.h"
#endif

struct _pbxgdb_plugin_function_list *_pbxgdb_plugin_functions = NULL;
