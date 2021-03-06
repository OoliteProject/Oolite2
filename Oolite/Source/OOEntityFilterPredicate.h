/*

OOEntityFilterPredicate.h

Filters used to select entities in various contexts. Callers are required to
ensure that the "entity" argument is non-nil and the "parameter" argument is
valid and relevant.

To reduce header spaghetti, the EntityFilterPredicate type is declared in
OOUniverse.h, which is included just about everywhere anyway. This file just
declares a set of widely-useful predicates.


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


#import "OOUniverse.h"
#import "OOShipEntity.h"


typedef struct
{
	EntityFilterPredicate	predicate;
	void					*parameter;
} ChainedEntityPredicateParameter;

typedef struct
{
	EntityFilterPredicate	predicate1;
	void					*parameter1;
	EntityFilterPredicate	predicate2;
	void					*parameter2;
} BinaryOperationPredicateParameter;


         BOOL YESPredicate(OOEntity *entity, void *parameter);					// Parameter: ignored. Always returns YES. (Not inline because it’s only useful when the predicate is selected dynamically and can’t be inlined anyway.)
         BOOL NOPredicate(OOEntity *entity, void *parameter);						// Parameter: ignored. Always returns NO.

OOINLINE BOOL NOTPredicate(OOEntity *entity, void *parameter);					// Parameter: ChainedEntityPredicateParameter. Reverses effect of chained predicate.

OOINLINE BOOL ANDPredicate(OOEntity *entity, void *parameter);					// Parameter: BinaryOperationPredicateParameter. Short-circuiting AND operator.
OOINLINE BOOL ORPredicate(OOEntity *entity, void *parameter);						// Parameter: BinaryOperationPredicateParameter. Short-circuiting OR operator.
OOINLINE BOOL NORPredicate(OOEntity *entity, void *parameter);					// Parameter: BinaryOperationPredicateParameter. Short-circuiting NOR operator.
OOINLINE BOOL XORPredicate(OOEntity *entity, void *parameter);					// Parameter: BinaryOperationPredicateParameter. XOR operator.
OOINLINE BOOL NANDPredicate(OOEntity *entity, void *parameter);					// Parameter: BinaryOperationPredicateParameter. NAND operator.

BOOL HasScanClassPredicate(OOEntity *entity, void *parameter) DEPRECATED_FUNC;	// Parameter: NSNumber (int)
OOINLINE BOOL HasScanClassPredicate2(OOEntity *entity, void *parameter);			// Parameter: intptr_t
OOINLINE BOOL HasClassPredicate(OOEntity *entity, void *parameter);				// Parameter: Class
OOINLINE BOOL IsShipPredicate(OOEntity *entity, void *parameter);					// Parameter: ignored. Tests isShip and !isSubentity.
OOINLINE BOOL IsStationPredicate(OOEntity *entity, void *parameter);				// Parameter: ignored. Tests isStation.
         BOOL IsPlanetPredicate(OOEntity *entity, void *parameter);				// Parameter: ignored. Tests isPlanet and planetType == STELLAR_TYPE_NORMAL_PLANET.
OOINLINE BOOL IsSunPredicate(OOEntity *entity, void *parameter);					// Parameter: ignored. Tests isSun.

// These predicates assume their parameter is a OOShipEntity.
OOINLINE BOOL HasRolePredicate(OOEntity *ship, void *parameter);					// Parameter: NSString
OOINLINE BOOL HasPrimaryRolePredicate(OOEntity *ship, void *parameter);			// Parameter: NSString
OOINLINE BOOL HasRoleInSetPredicate(OOEntity *ship, void *parameter);				// Parameter: NSSet
OOINLINE BOOL HasPrimaryRoleInSetPredicate(OOEntity *ship, void *parameter);		// Parameter: NSSet
         BOOL IsHostileAgainstTargetPredicate(OOEntity *ship, void *parameter);	// Parameter: OOShipEntity


/*** Only inline definitions beyond this point ***/

OOINLINE BOOL NOTPredicate(OOEntity *entity, void *parameter)
{
	NSCParameterAssert(parameter != NULL);
	ChainedEntityPredicateParameter *param = parameter;
	return !param->predicate(entity, param->parameter);
}

OOINLINE BOOL ANDPredicate(OOEntity *entity, void *parameter)
{
	BinaryOperationPredicateParameter *param = parameter;
	
	if (!param->predicate1(entity, param->parameter1))  return NO;
	if (!param->predicate2(entity, param->parameter2))  return NO;
	return YES;
}

OOINLINE BOOL ORPredicate(OOEntity *entity, void *parameter)
{
	BinaryOperationPredicateParameter *param = parameter;
	
	if (param->predicate1(entity, param->parameter1))  return YES;
	if (param->predicate2(entity, param->parameter2))  return YES;
	return NO;
}

OOINLINE BOOL NORPredicate(OOEntity *entity, void *parameter)
{
	BinaryOperationPredicateParameter *param = parameter;
	
	if (param->predicate1(entity, param->parameter1))  return NO;
	if (param->predicate2(entity, param->parameter2))  return NO;
	return YES;
}

OOINLINE BOOL XORPredicate(OOEntity *entity, void *parameter)
{
	BinaryOperationPredicateParameter *param = parameter;
	BOOL A, B;
	
	A = param->predicate1(entity, param->parameter1);
	B = param->predicate2(entity, param->parameter2);
	
	return (A || B) && !(A && B);
}

OOINLINE BOOL NANDPredicate(OOEntity *entity, void *parameter)
{
	BinaryOperationPredicateParameter *param = parameter;
	BOOL A, B;
	
	A = param->predicate1(entity, param->parameter1);
	B = param->predicate2(entity, param->parameter2);
	
	return !(A && B);
}

OOINLINE BOOL HasScanClassPredicate2(OOEntity *entity, void *parameter)
{
	NSCParameterAssert(entity != nil);
	return entity->scanClass == (intptr_t)parameter;
}

OOINLINE BOOL HasClassPredicate(OOEntity *entity, void *parameter)
{
	return [entity isKindOfClass:(Class)parameter];
}

OOINLINE BOOL IsShipPredicate(OOEntity *entity, void *parameter)
{
	return [entity isShip] && ![entity isSubEntity];
}

OOINLINE BOOL IsStationPredicate(OOEntity *entity, void *parameter)
{
	return [entity isStation];
}

OOINLINE BOOL IsSunPredicate(OOEntity *entity, void *parameter)
{
	return [entity isSun];
}

OOINLINE BOOL HasRolePredicate(OOEntity *ship, void *parameter)
{
	NSCParameterAssert([ship isShip] && [(id)parameter isKindOfClass:[NSString class]]);
	return [(OOShipEntity *)ship hasRole:(NSString *)parameter];
}

OOINLINE BOOL HasPrimaryRolePredicate(OOEntity *ship, void *parameter)
{
	NSCParameterAssert([ship isShip] && [(id)parameter isKindOfClass:[NSString class]]);
	return [(OOShipEntity *)ship hasPrimaryRole:(NSString *)parameter];
}

OOINLINE BOOL HasRoleInSetPredicate(OOEntity *ship, void *parameter)
{
	NSCParameterAssert([ship isShip] && [(id)parameter isKindOfClass:[NSSet class]]);
	return [[(OOShipEntity *)ship roleSet] intersectsSet:(NSSet *)parameter];
}
OOINLINE BOOL HasPrimaryRoleInSetPredicate(OOEntity *ship, void *parameter)
{
	NSCParameterAssert([ship isShip] && [(id)parameter isKindOfClass:[NSSet class]]);
	return [(NSSet *)parameter containsObject:[(OOShipEntity *)ship primaryRole]];
}
