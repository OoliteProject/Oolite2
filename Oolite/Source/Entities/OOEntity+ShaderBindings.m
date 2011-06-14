/*

OOEntity+ShaderBindings.m

Extra methods exposed for shader bindings.


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

#import "OOPlayerShipEntity+ScriptMethods.h"
#import "Universe.h"


@implementation OOEntity (ShaderBindings)

// Clock time.
- (GLfloat) clock
{
	return [PLAYER clockTime];
}


// System "flavour" numbers.
- (unsigned) pseudoFixedD100
{
	return [PLAYER systemPseudoRandom100];
}

- (unsigned) pseudoFixedD256
{
	return [PLAYER systemPseudoRandom256];
}


// System attributes.
- (unsigned) systemGovernment
{
	return [[UNIVERSE currentSystemData] oo_unsignedIntForKey:KEY_GOVERNMENT];
}

- (unsigned) systemEconomy
{
	return [[UNIVERSE currentSystemData] oo_unsignedIntForKey:KEY_ECONOMY];
}

- (unsigned) systemTechLevel
{
	return [[UNIVERSE currentSystemData] oo_unsignedIntForKey:KEY_TECHLEVEL];
}

- (unsigned) systemPopulation
{
	return [[UNIVERSE currentSystemData] oo_unsignedIntForKey:KEY_POPULATION];
}

- (unsigned) systemProductivity
{
	return [[UNIVERSE currentSystemData] oo_unsignedIntForKey:KEY_PRODUCTIVITY];
}

@end
