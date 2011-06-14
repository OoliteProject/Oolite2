/*

HeadUpDisplay.h

Class handling the player ship’s heads-up display, and 2D drawing functions.

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

#import <Foundation/Foundation.h>
#import "OOLegacyOpenGL.h"

#import "OOTypes.h"
#import "MyOpenGLView.h"
#import "OOShipEntity.h"

@class OOCrosshairs, OOColor, OOEntity, OOPlayerShipEntity, OOTextureSprite;
@protocol OOHUDBeaconIcon;


@interface HeadUpDisplay: NSObject
{
@private
	NSMutableArray		*legendArray;
	NSMutableArray		*dialArray;
	
	// zoom level
	GLfloat				scanner_zoom;
	
	//where to draw it
	GLfloat				z1;
	GLfloat				line_width;
	
	NSString			*hudName;
	
	GLfloat				overallAlpha;
	
	BOOL				reticleTargetSensitive;   // TO DO: Move this into the propertiesReticleTargetSensitive structure (Getafix - 2010/08/21)
	NSMutableDictionary *propertiesReticleTargetSensitive;
	
	BOOL				cloakIndicatorOnStatusLight;
	
	BOOL				hudHidden;
	
	OOWeakReference		*_lastTransmitter;
	
	// Crosshairs
	OOCrosshairs		*_crosshairs;
	OOWeaponType		_lastWeaponType;
	GLfloat				_lastOverallAlpha;
	BOOL				_lastWeaponsOnline;
	NSDictionary		*_crosshairOverrides;
	OOColor				*_crosshairColor;
	GLfloat				_crosshairScale;
	GLfloat				_crosshairWidth;
}

- (id) initWithDictionary:(NSDictionary *) hudinfo;
- (id) initWithDictionary:(NSDictionary *)hudinfo inFile:(NSString *)hudFileName;

- (void) resetGuis:(NSDictionary *) info;

- (NSString *) hudName;
- (void) setHudName:(NSString *)newHudName;

- (double) scannerZoom;
- (void) setScannerZoom:(double) value;

- (GLfloat) overallAlpha;
- (void) setOverallAlpha:(GLfloat) newAlphaValue;

- (BOOL) reticleTargetSensitive;
- (void) setReticleTargetSensitive:(BOOL) newReticleTargetSensitiveValue;
- (NSMutableDictionary *) propertiesReticleTargetSensitive;

- (BOOL) isHidden;
- (void) setHidden:(BOOL)newValue;

- (void) addLegend:(NSDictionary *) info;
- (void) addDial:(NSDictionary *) info;

- (void) renderHUD;

- (void) refreshLastTransmitter;

- (void) setLine_width:(GLfloat) value;
- (GLfloat) line_width;

- (void) drawWatermarkString:(NSString *) watermarkString;

@end


@interface NSString (OODisplayEncoding)

// Return a C string in the 8-bit encoding used for display.
- (const char *) cStringUsingOoliteEncoding;

// Return a C string in the 8-bit encoding used for display, with substitutions performed.
- (const char *) cStringUsingOoliteEncodingAndRemapping;

@end


/*
	Protocol for things that can be used as HUD compass items. Really ought
	to grow into a general protocol for HUD elements.
*/
@protocol OOHUDBeaconIcon <NSObject>

- (void) oo_drawHUDBeaconIconAt:(NSPoint)where size:(NSSize)size alpha:(GLfloat)alpha z:(GLfloat)z;

@end


@interface NSString (OOHUDBeaconIcon) <OOHUDBeaconIcon>
@end


void OODrawString(NSString *text, double x, double y, double z, NSSize siz);
void OODrawHilightedString(NSString *text, double x, double y, double z, NSSize siz);
void OODrawPlanetInfo(int gov, int eco, int tec, double x, double y, double z, NSSize siz);
void OODrawHilightedPlanetInfo(int gov, int eco, int tec, double x, double y, double z, NSSize siz);
NSRect OORectFromString(NSString *text, double x, double y, NSSize siz);
CGFloat OOStringWidthInEm(NSString *text);
