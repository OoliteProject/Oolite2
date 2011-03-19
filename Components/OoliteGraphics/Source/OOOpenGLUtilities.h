/*

OOOpenGLUtilities.h

OpenGL-related utility functions.


Oolite
Copyright (C) 2004-2010 Giles C Williams and contributors

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
#import "OOOpenGL.h"


/*	OOCheckOpenGLErrors()
	Check for and log OpenGL errors, and returns YES if an error occurred.
	NOTE: this is controlled by the log message class rendering.opengl.error.
		  If logging is disabled, no error checking will occur. This is done
		  because glGetError() is quite expensive, requiring a full OpenGL
		  state sync.
*/
BOOL OOCheckOpenGLErrors(NSString *format, ...);


/*	OOLogOpenGLState()
	Write a bunch of OpenGL state information to the log.
*/
void OOLogOpenGLState(void);


/*	OO_CHECK_GL_HEAVY and error-checking stuff
	
	If OO_CHECK_GL_HEAVY is non-zero, the following error-checking facilities
	come into play:
	OOGL(foo) checks for GL errors before and after performing the statement foo.
	OOGLBEGIN(mode) checks for GL errors, then calls glBegin(mode).
	OOGLEND() calls glEnd(), then checks for GL errors.
	OOCheckOpenGLErrorsHeavy() checks for errors exactly like OOCheckOpenGLErrors().
	
	If OO_CHECK_GL_HEAVY is zero, these macros don't perform error checking,
	but otherwise continue to work as before, so:
	OOGL(foo) performs the statement foo.
	OOGLBEGIN(mode) calls glBegin(mode);
	OOGLEND() calls glEnd().
	OOCheckOpenGLErrorsHeavy() does nothing (including not performing any parameter side-effects).
*/
#ifndef OO_CHECK_GL_HEAVY
#define OO_CHECK_GL_HEAVY 0
#endif


#if OO_CHECK_GL_HEAVY

NSString *OOLogAbbreviatedFileName(const char *inName);
#define OOGL_PERFORM_CHECK(label, code, line)  OOCheckOpenGLErrors(@"%s %@:%u (%s)%s", label, OOLogAbbreviatedFileName(__FILE__), line, __PRETTY_FUNCTION__, code)
#define OOGL(statement)  do { OOGL_PERFORM_CHECK("PRE", " -- " #statement, __LINE__); statement; OOGL_PERFORM_CHECK("POST", " -- " #statement, __LINE__); } while (0)
#define OOCheckOpenGLErrorsHeavy OOCheckOpenGLErrors
#define OOGLBEGIN(mode) do { OOGL_PERFORM_CHECK("PRE-BEGIN", " -- " #mode); glBegin(mode); } while (0)
#define OOGLEND() do { glEnd(); OOGL_PERFORM_CHECK("POST-END", ""); } while (0)

#else

#define OOGL(statement)  do { statement; } while (0)
#define OOCheckOpenGLErrorsHeavy(...) do {} while (0)
#define OOGLBEGIN glBegin
#define OOGLEND glEnd

#endif
