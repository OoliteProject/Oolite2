/*

OOLegacyEngineUtilities.h

Utility functions and types torn from PlayerEntityLegacyScriptEngine.


Oolite
Copyright (C) 2004-2011 Giles C Williams and contributors

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
MA 02110-1301, USA.

*/

#import <OoliteBase/OoliteBase.h>


typedef enum
{
	COMPARISON_EQUAL,
	COMPARISON_NOTEQUAL,
	COMPARISON_LESSTHAN,
	COMPARISON_GREATERTHAN,
	COMPARISON_ONEOF,
	COMPARISON_UNDEFINED
} OOComparisonType;


typedef enum
{
	OP_STRING,
	OP_NUMBER,
	OP_BOOL,
	OP_MISSION_VAR,
	OP_LOCAL_VAR,
	OP_FALSE,
	
	OP_INVALID	// Must be last.
} OOOperationType;


NSString *OOComparisonTypeToString(OOComparisonType type) CONST_FUNC;
