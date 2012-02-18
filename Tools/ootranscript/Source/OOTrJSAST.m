//
//  OOTrJSAST.m
//  ootranscript
//
//  Created by Jens Ayton on 2010-07-22.
//  Copyright 2010 Jens Ayton. All rights reserved.
//

#import "OOTrJSAST.h"
#import "NSString+OOJavaScriptLiteral.h"


/*
	Precedence levels. Note that lower values have higher precedence.
*/
enum
{
	kPrecedenceAtom,	// Literals and identifiers.
	
	kPrecedencePropertyAccess,
	kPrecedenceNew = kPrecedencePropertyAccess,
	
	kPrecedenceFunctionCall,
	kPrecedenceCallExprPropertyAccess = kPrecedenceFunctionCall,
	
	kPrecedencePostIncrement,
	kPrecedencePostDecrement = kPrecedencePostIncrement,
	
	kPrecedenceDelete,
	kPrecedenceVoid = kPrecedenceDelete,
	kPrecedenceTypeof = kPrecedenceDelete,
	kPrecedencePreIncrement = kPrecedenceDelete,
	kPrecedencePreDecrement = kPrecedencePreIncrement,
	kPrecedenceUnaryPlus = kPrecedencePreDecrement,
	kPrecedenceUnaryMinus = kPrecedenceUnaryPlus,
	kPrecedenceBitwiseNot = kPrecedenceUnaryMinus,
	kPrecedenceLogicalNot = kPrecedenceBitwiseNot,
	
	kPrecedenceMultiply,
	kPrecedenceDivide = kPrecedenceMultiply,
	kPrecedenceRemainder = kPrecedenceDivide,
	
	kPrecedenceAdd,
	kPrecedenceSubtract = kPrecedenceAdd,
	
	kPrecedenceShiftLeft,
	kPrecedenceShiftRight = kPrecedenceShiftLeft,
	kPrecedenceShiftRightUnsigned = kPrecedenceShiftRight,
	
	kPrecedenceLessThanComparison,
	kPrecedenceGreaterThanComparison = kPrecedenceLessThanComparison,
	kPrecedenceLessThanOrEqualComparison = kPrecedenceLessThanComparison,
	kPrecedenceGreaterThanOrEqualComparison = kPrecedenceLessThanOrEqualComparison,
	kPrecedenceInstanceof = kPrecedenceGreaterThanOrEqualComparison,
	kPrecedenceIn = kPrecedenceInstanceof,
	
	kPrecedenceEqualComparison,
	kPrecedenceNotEqualComparison = kPrecedenceEqualComparison,
	kPrecedenceStrictlyEqualComparison = kPrecedenceEqualComparison,
	kPrecedenceNotStrictlyEqualComparison = kPrecedenceStrictlyEqualComparison,
	
	kPrecedenceBitwiseAnd,
	
	kPrecedenceBitwiseXor,
	
	kPrecedenceBitwiseOr,
	
	kPrecedenceLogicalAnd,
	
	kPrecedenceLogicalOr,
	
	kPrecedenceConditional,
	
	kPrecedenceAssign,
	kPrecedenceMultiplyAssign = kPrecedenceAssign,
	kPrecedenceDivideAssign = kPrecedenceAssign,
	kPrecedenceRemainderAssign = kPrecedenceAssign,
	kPrecedenceAddAssign = kPrecedenceAssign,
	kPrecedenceSubtractAssign = kPrecedenceAssign,
	kPrecedenceShiftLeftAssign = kPrecedenceAssign,
	kPrecedenceShiftRightAssign = kPrecedenceAssign,
	kPrecedenceShiftRightUnsignedAssign = kPrecedenceAssign,
	kPrecedenceBitwiseAndAssign = kPrecedenceAssign,
	kPrecedenceBitwiseXorAssign = kPrecedenceAssign,
	kPrecedenceBitwiseOrAssign = kPrecedenceAssign,
	
	kPrecedenceComma,
	
	kPrecedenceBottom
};


NSString * const kOOTrIsSideEffectFreeOverride	= @"kOOTrIsSideEffectFreeOverride";
NSString * const kOOTrHasNumericTypeOverride	= @"kOOTrHasNumericTypeOverride";
NSString * const kOOTrHasBooleanTypeOverride	= @"kOOTrHasBooleanTypeOverride";


static NSString *IndentTabs(NSUInteger indentLevel);


static void ThrowSubclassResponsibility_(Class class, SEL method)  GCC_ATTR((noreturn));
#define ThrowSubclassResponsibility() ThrowSubclassResponsibility_([self class], _cmd)


#ifndef NDEBUG
static void AssertArrayContentClass_(NSArray *array, Class expectedClass, const char *function);
#define AssertArrayContentClass(array, cls) AssertArrayContentClass_(array, [cls class], __func__)

static void AssertDictionaryContentClasses_(NSDictionary *dict, Class keyClass, Class valueClass, const char *function);
#define AssertDictionaryContentClasses(dict, keyCls, valueCls)  AssertDictionaryContentClasses_(dict, [keyCls class], [valueCls class], __func__)
#else
#define AssertArrayContentClass(array, cls)  do {} while (0)
#define AssertDictionaryContentClasses(dict, keyCls, valueCls)  do {} while (0)
#endif


#if OOLITE_64_BIT
/*	For 64-bit builds, it can be assumed that NSHashTable is an object
	(Mac OS X 10.5, GNUstep 1.19/1.20).
*/
static NSMapTable *sNumberLiteralCache;
#else
static NSMutableDictionary *sNumberLiteralCache;
#endif

static NSMutableDictionary *sStringLiteralCache;
static NSMutableDictionary *sRegExpLiteralCache;
static NSMutableDictionary *sIdentifierCache;


void OOTrASTFlushCache(void)
{
	DESTROY(sNumberLiteralCache);
	DESTROY(sStringLiteralCache);
	DESTROY(sRegExpLiteralCache);
	DESTROY(sIdentifierCache);
}


@implementation OOTrStatement: NSObject

- (void) clearSimplified
{
	if (_simplified != self)  [_simplified release];
	_simplified = nil;
}


- (void) dealloc
{
	[self clearSimplified];
	DESTROY(_annotations);
	
	[super dealloc];
}


- (NSString *) jsStatementCode
{
	return [self jsStatementCodeWithIndentLevel:0];
}


- (NSString *) jsStatementCodeWithIndentLevel:(NSUInteger)indentLevel
{
	ThrowSubclassResponsibility();
}


- (BOOL) isSideEffectFreeDefault
{
	return NO;
}


- (BOOL) isSideEffectFree
{
	id override = [_annotations objectForKey:kOOTrIsSideEffectFreeOverride];
	if (override && [override respondsToSelector:@selector(boolValue)])  return [override boolValue];
	
	return [self isSideEffectFreeDefault];
}


- (BOOL) isScopeLocalDeclaration
{
	return NO;
}


- (id) annotationForKey:(NSString *)key
{
	return [_annotations objectForKey:key];
}


- (void) setAnnotation:(id)annotation forKey:(NSString *)key
{
	if (EXPECT_NOT(key == nil))  return;
	
	if (_annotations == nil && annotation != nil)  _annotations = [[NSMutableDictionary alloc] init];
	if (annotation != nil)
	{
		[_annotations setObject:annotation forKey:key];
	}
	else
	{
		[_annotations removeObjectForKey:key];
	}
	
	// Annotations may affect simplification, and will affect annotations of simplified form.
	[self clearSimplified];
}


- (void) setBooleanAnnotation:(BOOL)annotation forKey:(NSString *)key
{
	[self setAnnotation:[NSNumber numberWithBool:annotation] forKey:key];
}

@end


@implementation OOTrExpression

- (NSString *) jsStatementCodeWithIndentLevel:(NSUInteger)indentLevel
{
	return $sprintf(@"%@%@;", IndentTabs(indentLevel), [self jsExpressionCodeWithIndentLevel:indentLevel]);
}


- (NSString *) jsExpressionCode
{
	return [self jsExpressionCodeWithIndentLevel:0];
}


- (NSString *) jsExpressionCodeWithIndentLevel:(NSUInteger)indentLevel
{
	ThrowSubclassResponsibility();
}


- (NSUInteger) precedence
{
	ThrowSubclassResponsibility();
}


- (NSString *) jsExpressionCodeForPrecedence:(NSUInteger)precedence withIndentLevel:(NSUInteger)indentLevel
{
	NSString *code = [self jsExpressionCodeWithIndentLevel:indentLevel];
	if ([self precedence] <= precedence)
	{
		return code;
	}
	else
	{
		return $sprintf(@"(%@)", code);
	}
}


- (BOOL) isNumericConstant
{
	return NO;
}


- (double) doubleValue
{
	return NAN;
}


- (BOOL) hasKnownBooleanValue
{
	return NO;
}


- (BOOL) hasBooleanTypeDefault
{
	return NO;
}


- (BOOL) hasBooleanType
{
	id override = [_annotations objectForKey:kOOTrHasBooleanTypeOverride];
	if (override && [override respondsToSelector:@selector(boolValue)])  return [override boolValue];
	
	return [self hasBooleanTypeDefault];
}


- (BOOL) hasNumericTypeDefault
{
	return NO;
}


- (BOOL) hasNumericType
{
	id override = [_annotations objectForKey:kOOTrHasNumericTypeOverride];
	if (override && [override respondsToSelector:@selector(boolValue)])  return [override boolValue];
	
	return [self hasNumericTypeDefault];
}


- (BOOL) boolValue
{
	if (![self hasKnownBooleanValue])
	{
		[NSException raise:NSInternalInconsistencyException format:@"-boolValue called on OOTrExpression for which -hasKnownBooleanValue is false."];
		return NO;
	}
	else
	{
		ThrowSubclassResponsibility();
	}
}


- (OOTrBooleanLiteral *) booleanLiteralValue
{
	return TrBOOL([self boolValue]);
}


- (OOTrExpression *) logicalInverse
{
	return TrNOT(self);
}

@end


@implementation OOTrReturnStatement

static OOTrReturnStatement *sValuelessReturn = nil;


- (id) initWithExpression:(OOTrExpression *)expression
{
	if ((self = [super init]))
	{
		_expression = [expression retain];
	}
	return self;
}


+ (id) statementWithExpression:(OOTrExpression *)expression
{
	if (expression != nil)
	{
		return [[[self alloc] initWithExpression:expression] autorelease];
	}
	else
	{
		if (sValuelessReturn == nil)  sValuelessReturn = [[[self alloc] initWithExpression:nil] autorelease];
		return sValuelessReturn;
	}
}


- (void) dealloc
{
	if (self == sValuelessReturn)  sValuelessReturn = nil;
	DESTROY(_expression);
	
	[super dealloc];
}


- (id) expression
{
	return _expression;
}


- (NSString *) jsStatementCodeWithIndentLevel:(NSUInteger)indentLevel
{
	if (_expression != nil)
	{
		return $sprintf(@"%@return %@;", IndentTabs(indentLevel), [_expression jsExpressionCodeWithIndentLevel:indentLevel]);
	}
	else
	{
		return @"return;";
	}
}


- (NSString *) descriptionComponents
{
	if (_expression != nil)
	{
		return @"return x;";
	}
	else
	{
		return @"return;";
	}
}

@end


@implementation OOTrVarStatement

- (id) initWithName:(NSString *)name initializer:(OOTrExpression *)initializer
{
	if (name == nil)
	{
		[self release];
		return nil;
	}
	
	if ((self = [super init]))
	{
		_name = [name copy];
		_initializer = [initializer retain];
	}
	
	return self;
}


+ (id) statementWithName:(NSString *)name initializer:(OOTrExpression *)initializer
{
	return [[[self alloc] initWithName:name initializer:initializer] autorelease];
}


- (void) dealloc
{
	DESTROY(_name);
	DESTROY(_initializer);
	
	[super dealloc];
}


- (NSString *) name
{
	return _name;
}


- (OOTrExpression *) initializer
{
	return _initializer;
}


- (NSString *) keyword
{
	return @"var";
}


- (NSString *) jsStatementCodeWithIndentLevel:(NSUInteger)indentLevel
{
	if (_initializer != nil)
	{
		return $sprintf(@"%@%@ %@ = %@;", IndentTabs(indentLevel), [self keyword], _name, [_initializer jsExpressionCodeWithIndentLevel:indentLevel]);
	}
	else
	{
		return $sprintf(@"%@%@ %@;", IndentTabs(indentLevel), [self keyword], _name);
	}
}


- (NSString *) descriptionComponents
{
	if (_initializer != nil)
	{
		return $sprintf(@"%@ %@ = x;", [self keyword], _name);
	}
	else
	{
		return $sprintf(@"%@ %@;", [self keyword], _name);
	}
}

@end


@implementation OOTrLetStatement


- (NSString *) keyword
{
	return @"let";
}


- (BOOL) isScopeLocalDeclaration
{
	return YES;
}

@end



@implementation OOTrCompoundStatement

static OOTrCompoundStatement *sNullStatement;


- (id) initWithStatements:(NSArray *)statements
{
	AssertArrayContentClass(statements, OOTrStatement);
	
	if ((self = [super init]))
	{
		_statements = [statements copy];
	}
	
	return self;
}


+ (id) compoundStatementWithStatements:(NSArray *)statements
{
	if ([statements count] == 0)
	{
		if (sNullStatement == nil)  sNullStatement = [[[self alloc] initWithStatements:nil] autorelease];
		return sNullStatement;
	}
	return [[[self alloc] initWithStatements:statements] autorelease];
}


+ (id) compoundStatementWithStatement:(OOTrStatement *)statement
{
	return [self compoundStatementWithStatements:[NSArray arrayWithObject:statement]];
}


+ (id) compoundStatementWithObject:(id)object
{
	if ([object isKindOfClass:[OOTrCompoundStatement class]])  return object;
	if ([object isKindOfClass:[OOTrStatement class]])  return [OOTrCompoundStatement compoundStatementWithStatement:object];
	if ([object isKindOfClass:[NSArray class]])  return [OOTrCompoundStatement compoundStatementWithStatements:object];
	return nil;
}


- (void) dealloc
{
	if (sNullStatement == self)  sNullStatement = nil;
	DESTROY(_statements);
	
	[super dealloc];
}


- (NSArray *) statements
{
	return (_statements != nil) ? _statements : [NSArray array];
}


- (NSString *) jsStatementCodeWithIndentLevel:(NSUInteger)indentLevel
{
	if ([_statements count] == 0)  return $sprintf(@"%@{}", IndentTabs(indentLevel));
	
	NSMutableString *result = [NSMutableString string];
	[result appendFormat:@"%@{\n", IndentTabs(indentLevel)];
	
	OOTrStatement *statement = nil;
	foreach (statement, _statements)
	{
		[result appendFormat:@"%@\n", [statement jsStatementCodeWithIndentLevel:indentLevel + 1]];
	}
	
	[result appendFormat:@"%@}", IndentTabs(indentLevel)];
	
	return result;
}


- (NSString *) descriptionComponents
{
	return $sprintf(@"{%u;}", [_statements count]);
}


- (BOOL) isSideEffectFreeDefault
{
	OOTrStatement *statement = nil;
	foreach (statement, _statements)
	{
		if (![statement isSideEffectFree])  return NO;
	}
	
	return YES;
}


- (BOOL) isEqual:(id)other
{
	if (other == self)  return YES;
	if ([other isKindOfClass:[OOTrCompoundStatement class]])  return [[self statements] isEqualToArray:[other statements]];
	
	return NO;
}


- (BOOL) isEqualToOrWraps:(OOTrStatement *)statement
{
	if ([self isEqual:statement])  return YES;
	if ([_statements count] == 1 && [[_statements objectAtIndex:0] isEqual:statement])  return YES;
	
	return NO;
}


- (BOOL) isNullStatement
{
	return [_statements count] == 0;
}

@end


@implementation OOTrConditionalStatement

- (id) initWithCondition:(OOTrExpression *)condition
		   trueStatement:(OOTrCompoundStatement *)trueStatement
		  falseStatement:(OOTrCompoundStatement *)falseStatement
{
	if ((self = [super init]))
	{
		_condition = [condition retain];
		_trueStatement = [trueStatement retain];
		_falseStatement = [falseStatement retain];
	}
	return self;
}


+ (id) statementWithCondition:(OOTrExpression *)condition
				trueStatement:(id)trueStatement
			   falseStatement:(id)falseStatement
{
	trueStatement = [OOTrCompoundStatement compoundStatementWithObject:trueStatement];
	falseStatement = [OOTrCompoundStatement compoundStatementWithObject:falseStatement];
	
	if (trueStatement == nil || [trueStatement isNullStatement])
	{
		if (falseStatement == nil)  return nil;
		else
		{
			trueStatement = falseStatement;
			falseStatement = nil;
			condition = TrNOT(condition);
		}
	}
	if (condition == nil)  return nil;
	
	if ([falseStatement isNullStatement])  falseStatement = nil;
	
	return [[[self alloc] initWithCondition:condition trueStatement:trueStatement falseStatement:falseStatement] autorelease];
}


- (void) dealloc
{
	DESTROY(_condition);
	DESTROY(_trueStatement);
	DESTROY(_falseStatement);
	
	[super dealloc];
}


- (OOTrExpression *) condition
{
	return _condition;
}


- (OOTrCompoundStatement *) trueStatement
{
	return _trueStatement;
}


- (OOTrCompoundStatement *) falseStatement
{
	return _falseStatement;
}


- (BOOL) isSideEffectFreeDefault
{
	return [_condition isSideEffectFree] && [_trueStatement isSideEffectFree] && [_falseStatement isSideEffectFree];
}


- (NSString *) jsStatementCodeWithIndentLevel:(NSUInteger)indentLevel chained:(BOOL)chained
{
	NSMutableString *result = [NSMutableString string];
	
	[result appendFormat:@"%@if (%@)\n", (chained) ? @"" : IndentTabs(indentLevel), [_condition jsExpressionCodeWithIndentLevel:indentLevel + 1]];
	[result appendString:[_trueStatement jsStatementCodeWithIndentLevel:indentLevel]];
	
	if (_falseStatement != nil)
	{
		// Handle "else if" chaining.
		NSArray *falseBody = [_falseStatement statements];
		id elseIf = nil;
		if ([falseBody count] == 1)
		{
			elseIf = [falseBody objectAtIndex:0];
			if (![elseIf isKindOfClass:[OOTrConditionalStatement class]])  elseIf = nil;
		}
		if (elseIf == nil)
		{
			[result appendFormat:@"\n%@else\n", IndentTabs(indentLevel)];
			[result appendString:[_falseStatement jsStatementCodeWithIndentLevel:indentLevel]];
		}
		else
		{
			[result appendFormat:@"\n%@else ", IndentTabs(indentLevel)];
			[result appendString:[elseIf jsStatementCodeWithIndentLevel:indentLevel chained:YES]];
		}
	}
	
	return result;
}


- (NSString *) jsStatementCodeWithIndentLevel:(NSUInteger)indentLevel
{
	return [self jsStatementCodeWithIndentLevel:indentLevel chained:NO];
}


- (NSString *) descriptionComponents
{
	if (_falseStatement == nil)
	{
		return $sprintf(@"if (cond) %@", [_trueStatement descriptionComponents]);
	}
	else
	{
		return $sprintf(@"if (cond) %@ else %@", [_trueStatement descriptionComponents], [_falseStatement descriptionComponents]);
	}

}

@end


@implementation OOTrFunctionDeclaration

- (id) initWithName:(NSString *)name
		  arguments:(NSArray *)arguments
			   body:(id)body
{
	body = [OOTrCompoundStatement compoundStatementWithObject:body];
	if (body == nil)
	{
		[self release];
		return nil;
	}
	
	if ((self = [super init]))
	{
		_name = [name copy];
		_arguments = [arguments copy];
		_body = [body retain];
	}
	
	return self;
}


+ (id) functionWithName:(NSString *)name
			  arguments:(NSArray *)arguments
				   body:(id)body
{
	return [[[self alloc] initWithName:name arguments:arguments body:body] autorelease];
}


- (void) dealloc
{
	DESTROY(_name);
	DESTROY(_arguments);
	DESTROY(_body);
	
	[super dealloc];
}


- (NSString *) name
{
	return _name;
}


- (NSArray *) arguments
{
	return _arguments;
}


- (OOTrCompoundStatement *) body
{
	return _body;
}


- (NSUInteger) precedence
{
	return kPrecedenceAtom;
}


- (NSString *) jsStatementCodeWithIndentLevel:(NSUInteger)indentLevel
{
	return [IndentTabs(indentLevel) stringByAppendingString:[self jsExpressionCodeWithIndentLevel:indentLevel]];
}


- (NSString *) jsExpressionCodeWithIndentLevel:(NSUInteger)indentLevel
{
	NSMutableString *result = [NSMutableString stringWithFormat:@"function "];
	if (_name != nil)  [result appendFormat:@"%@", _name];
	
	[result appendFormat:@"("];
	if ([_arguments count] > 0)
	{
		[result appendString:[_arguments componentsJoinedByString:@", "]];
	}
	[result appendString:@")\n"];
	
	[result appendString:[_body jsStatementCodeWithIndentLevel:indentLevel]];
	
	return result;
}


- (NSString *) descriptionComponents
{
	NSMutableString *result = [NSMutableString stringWithString:@"function "];
	if (_name != nil)  [result appendFormat:@"%@", _name];
	
	[result appendString:@"("];
	if ([_arguments count] > 0)
	{
		[result appendString:[_arguments componentsJoinedByString:@", "]];
	}
	[result appendString:@") "];
	
	[result appendString:[_body descriptionComponents]];
	
	return result;
}

@end


@implementation OOTrNumberLiteral

#if OOLITE_64_BIT && !defined(NDEBUG)
+ (void) initialize
{
	assert(sizeof (double) == sizeof (void *));
}
#endif


- (id) initWithValue:(double)value
{
	if ((self = [super init]))
	{
		_value = value;
	}
	
	return self;
}


#if OOLITE_64_BIT
/*	In 64-bit mode, the number literal cache uses doubles themselves as cache
	keys, saving the overhead of an NSNumber object.
*/

static NSString *NCacheDescribeDouble(NSMapTable *table, const void *value)
{
	return [NSString stringWithFormat:@"%g", *(double *)&value];
}


static NSMapTableKeyCallBacks kNCacheCallBacks =
{
	.describe = NCacheDescribeDouble
};

typedef void *NCacheKey;
static inline NCacheKey NCacheMakeKey(double value)  { return *(void **)&value; }
static OOTrNumberLiteral *NCacheGet(NCacheKey key)  { return (sNumberLiteralCache != nil) ? NSMapGet(sNumberLiteralCache, key) : nil; }
static void NCacheSet(NCacheKey key, OOTrNumberLiteral *value)
{
	if (sNumberLiteralCache == nil)
	{
		kNCacheCallBacks.notAKeyMarker = NCacheMakeKey(NAN);
		sNumberLiteralCache = NSCreateMapTable(kNCacheCallBacks, NSObjectMapValueCallBacks, 0);
	}
	NSMapInsert(sNumberLiteralCache, key, value);
}

#else
/*	In 32-bit mode, doubles are bigger than pointers and it isn't worth
	writing a custom map, so we use NSNumbers as keys.
*/

typedef NSNumber *NCacheKey;
static inline NCacheKey NCacheMakeKey(double value)  { return [NSNumber numberWithDouble:value]; }
static OOTrNumberLiteral *NCacheGet(NCacheKey key)  { return [sNumberLiteralCache objectForKey:key]; }
static void NCacheSet(NCacheKey key, OOTrNumberLiteral *value)
{
	if (sNumberLiteralCache == nil)
	{
		sNumberLiteralCache = [[NSMutableDictionary alloc] init];
	}
	[sNumberLiteralCache setObject:value forKey:key];
}
#endif


+ (id) literalWithDoubleValue:(double)value
{
	NCacheKey key = NCacheMakeKey(value);
	id result = NCacheGet(key);
	
	if (result == nil)
	{
		result = [[self alloc] initWithValue:value];
#if OOLITE_64_BIT
		if (EXPECT_NOT(isnan(value)))
		{
			// NaN can't be stored in hash table.
			return [result autorelease];
		}
#endif
		NCacheSet(key, result);
		[result release];
	}
	return result;
}


- (BOOL) isNumericConstant
{
	return YES;
}


- (BOOL) hasNumericTypeDefault
{
	return YES;
}


- (double) doubleValue
{
	return _value;
}


- (NSString *) stringValue
{
	return [self jsExpressionCode];
}


- (BOOL) hasKnownBooleanValue
{
	return YES;
}


- (BOOL) boolValue
{
	return _value != 0.0 && !isnan(_value);
}


- (NSString *) descriptionComponents
{
	return [self jsExpressionCode];
}


- (NSString *) jsExpressionCodeWithIndentLevel:(NSUInteger)indentLevel
{
	return $sprintf(@"%g", _value);
}


- (NSUInteger) precedence
{
	return kPrecedenceAtom;
}


- (BOOL) isSideEffectFreeDefault
{
	return YES;
}

@end


@implementation OOTrStringLiteral

- (id) initWithString:(NSString *)string
{
	if (EXPECT_NOT(string == nil))
	{
		[self release];
		return nil;
	}
	
	if ((self = [super init]))
	{
		_string = [string copy];
	}
	
	return self;
}


+ (id) literalWithStringValue:(NSString *)string
{
	NSString *result = [sStringLiteralCache objectForKey:string];
	if (result == nil)
	{
		result = [[self alloc] initWithString:string];
		if (sStringLiteralCache == nil)  sStringLiteralCache = [[NSMutableDictionary alloc] init];
		[sStringLiteralCache setObject:result forKey:string];
		[result release];
	}
	
	return result;
}


- (void) dealloc
{
	DESTROY(_string);
	
	[super dealloc];
}


- (NSString *) stringValue
{
	return _string;
}


- (BOOL) isNumericConstant
{
	return OOIsNumberLiteral(_string, YES);
}


- (double) doubleValue
{
	if ([self isNumericConstant])  return [_string doubleValue];
	else  return NAN;
}


- (BOOL) hasKnownBooleanValue
{
	return YES;
}


- (BOOL) boolValue
{
	return [_string length] > 0;
}


- (NSString *) descriptionComponents
{
	return [_string oo_javaScriptLiteral];
}


- (NSString *) jsExpressionCodeWithIndentLevel:(NSUInteger)indentLevel
{
	return [_string oo_javaScriptLiteral];
}


- (NSUInteger) precedence
{
	return kPrecedenceAtom;
}


- (BOOL) isSideEffectFreeDefault
{
	return ![_string isEqualToString:@"use strict"];
}

@end


@implementation OOTrRegExpLiteral

- (id) initWithRegExp:(NSString *)regExp flags:(NSString *)flags
{
	if (EXPECT_NOT(regExp == nil))
	{
		[self release];
		return nil;
	}
	if (flags == nil)  flags = @"";
	
	if ((self = [super init]))
	{
		_regExp = [regExp copy];
		_flags = [flags copy];
	}
	
	return self;
}


+ (id) literalWithRegExp:(NSString *)regExp flags:(NSString *)flags
{
	if ([flags length] == 0)
	{
		NSString *result = [sRegExpLiteralCache objectForKey:regExp];
		if (result == nil)
		{
			result = [[self alloc] initWithRegExp:regExp flags:nil];
			if (sRegExpLiteralCache == nil)  sRegExpLiteralCache = [[NSMutableDictionary alloc] init];
			[sRegExpLiteralCache setObject:result forKey:regExp];
			[result release];
		}
		return result;
	}
	else
	{
		return [[[self alloc] initWithRegExp:regExp flags:flags] autorelease];
	}
}


- (void) dealloc
{
	DESTROY(_regExp);
	DESTROY(_flags);
	
	[super dealloc];
}


- (NSString *) regExp
{
	return _regExp;
}


- (NSString *) flags
{
	return _flags;
}


- (BOOL) hasKnownBooleanValue
{
	return YES;
}


- (BOOL) boolValue
{
	// Any object is considered "true".
	return YES;
}


- (NSString *) descriptionComponents
{
	return [self jsExpressionCodeWithIndentLevel:0];
}


- (NSString *) jsExpressionCodeWithIndentLevel:(NSUInteger)indentLevel
{
	return $sprintf(@"/%@/%@", _regExp, _flags);
}


- (NSUInteger) precedence
{
	return kPrecedenceAtom;
}


- (BOOL) isSideEffectFreeDefault
{
	return YES;
}

@end


@implementation OOTrBooleanLiteral: OOTrExpression

- (id) initWithBoolValue:(BOOL)value
{
	if ((self = [super init]))
	{
		_value = value;
	}
	return self;
}


+ (id) literalWithBoolValue:(BOOL)value
{
	static OOTrBooleanLiteral *bools[2] = { nil, nil };
	
	value = !!value;
	if (bools[value] == nil)
	{
		bools[value] = [[self alloc] initWithBoolValue:value];
	}
	return bools[value];
}


- (BOOL) boolValue
{
	return _value;
}


- (BOOL) hasKnownBooleanValue
{
	return YES;
}


- (BOOL) hasBooleanTypeDefault
{
	return YES;
}


- (BOOL) isNumericConstant
{
	return YES;
}


- (double) doubleValue
{
	return _value ? 1.0 : +0.0;
}


- (NSString *) descriptionComponents
{
	return [self jsExpressionCode];
}


- (NSString *) jsExpressionCodeWithIndentLevel:(NSUInteger)indentLevel
{
	return _value ? @"true" : @"false";
}


- (NSUInteger) precedence
{
	return kPrecedenceAtom;
}


- (BOOL) isSideEffectFreeDefault
{
	return YES;
}


- (id) retain
{
	return self;
}


- (oneway void) release
{}


- (id) autorelease
{
	return self;
}


- (NSUInteger) retainCount
{
	return UINT_MAX;
}

@end


@implementation OOTrIdentifier

- (id) initWithName:(NSString *)name
{
	if (EXPECT_NOT(name == nil))
	{
		[self release];
		return nil;
	}
	
	if ((self = [super init]))
	{
		_name = [name copy];
	}
	
	return self;
}


+ (id) identifierWithName:(NSString *)name
{
	NSString *result = [sIdentifierCache objectForKey:name];
	if (result == nil)
	{
		result = [[self alloc] initWithName:name];
		if (sIdentifierCache == nil)  sIdentifierCache = [[NSMutableDictionary alloc] init];
		[sIdentifierCache setObject:result forKey:name];
		[result release];
	}
	
	return result;
}


+ (id) identifierWithNonKeywordName:(NSString *)name
{
	if ([name oo_isJavaScriptKeyword])  return nil;
	return [self identifierWithName:name];
}


- (void) dealloc
{
	DESTROY(_name);
	
	[super dealloc];
}


- (NSString *) name
{
	return _name;
}


- (NSString *) descriptionComponents
{
	return _name;
}


- (NSString *) jsExpressionCodeWithIndentLevel:(NSUInteger)indentLevel
{
	return _name;
}


- (NSUInteger) precedence
{
	return kPrecedenceAtom;
}


- (BOOL) isSideEffectFreeDefault
{
	return YES;
}

@end


@implementation OOTrUndefinedLiteral: OOTrExpression

+ (id) undefinedLiteral
{
	static OOTrUndefinedLiteral *sValue = nil;
	if (sValue == nil)  sValue = [[self alloc] init];
	return sValue;
}


- (NSUInteger) precedence
{
	return kPrecedenceAtom;
}


- (BOOL) isSideEffectFreeDefault
{
	return YES;
}


- (BOOL) hasKnownBooleanValue
{
	return YES;
}


- (BOOL) boolValue
{
	return NO;
}


- (BOOL) isNumericConstant
{
	return YES;
}


- (double) doubleValue
{
	return NAN;
}


- (NSString *) descriptionComponents
{
	return @"undefined";
}


- (NSString *) jsExpressionCodeWithIndentLevel:(NSUInteger)indentLevel
{
	return @"undefined";
}


- (id) retain
{
	return self;
}


- (oneway void) release
{}


- (id) autorelease
{
	return self;
}


- (NSUInteger) retainCount
{
	return UINT_MAX;
}

@end


@implementation OOTrNullLiteral: OOTrExpression

+ (id) nullLiteral
{
	static OOTrNullLiteral *sValue = nil;
	if (sValue == nil)  sValue = [[self alloc] init];
	return sValue;
}


- (NSUInteger) precedence
{
	return kPrecedenceAtom;
}


- (BOOL) isSideEffectFreeDefault
{
	return YES;
}


- (BOOL) hasKnownBooleanValue
{
	return YES;
}


- (BOOL) boolValue
{
	return NO;
}


- (BOOL) isNumericConstant
{
	return YES;
}


- (double) doubleValue
{
	return +0.0;
}


- (NSString *) descriptionComponents
{
	return @"null";
}


- (NSString *) jsExpressionCodeWithIndentLevel:(NSUInteger)indentLevel
{
	return @"null";
}


- (id) retain
{
	return self;
}


- (oneway void) release
{}


- (id) autorelease
{
	return self;
}


- (NSUInteger) retainCount
{
	return UINT_MAX;
}

@end


@implementation OOTrThisLiteral: OOTrExpression

+ (id) thisLiteral
{
	static OOTrThisLiteral *sValue = nil;
	if (sValue == nil)  sValue = [[self alloc] init];
	return sValue;
}


- (NSUInteger) precedence
{
	return kPrecedenceAtom;
}


- (BOOL) isSideEffectFreeDefault
{
	return YES;
}


- (NSString *) descriptionComponents
{
	return @"this";
}


- (NSString *) jsExpressionCodeWithIndentLevel:(NSUInteger)indentLevel
{
	return @"this";
}


- (BOOL) hasKnownBooleanValue
{
	return YES;
}


- (BOOL) boolValue
{
	// Any object is considered "true".
	return YES;
}


- (id) retain
{
	return self;
}


- (oneway void) release
{}


- (id) autorelease
{
	return self;
}


- (NSUInteger) retainCount
{
	return UINT_MAX;
}

@end


@implementation OOTrObjectDeclaration

static OOTrObjectDeclaration *sEmptyObject;


- (id) initWithProperties:(NSDictionary *)properties
{
	if ((self = [super init]))
	{
		_properties = [properties retain];
	}
	return self;
}


+ (id) declarationWithProperties:(NSDictionary *)properties
{
	if ([properties count] == 0)
	{
		if (sEmptyObject == nil)  sEmptyObject = [[[self alloc] initWithProperties:nil] autorelease];
		return sEmptyObject;
	}
	
	AssertDictionaryContentClasses(properties, NSString, OOTrExpression);
	return [[[self alloc] initWithProperties:properties] autorelease];
}


- (void) dealloc
{
	if (sEmptyObject == self)  sEmptyObject = nil;
	
	DESTROY(_properties);
	
	[super dealloc];
}


- (NSDictionary *) properties
{
	return (_properties != nil) ? _properties : [NSDictionary dictionary];
}


- (NSUInteger) precedence
{
	return kPrecedenceAtom;
}


- (BOOL) isSideEffectFreeDefault
{
	id expr = nil;
	foreach (expr, _properties)
	{
		if (![expr isSideEffectFree])  return NO;
	}
	
	return YES;
}


- (BOOL) hasKnownBooleanValue
{
	return YES;
}


- (BOOL) boolValue
{
	// Any object is considered "true".
	return YES;
}


- (NSString *) descriptionComponents
{
	return $sprintf(@"{%lu}", (long)[_properties count]);
}


- (NSString *) jsExpressionCodeWithIndentLevel:(NSUInteger)indentLevel
{
	if ([_properties count] == 0)  return @"{}";
	
	NSMutableString *result = [NSMutableString string];
	[result appendString:@"{\n"];
	
	NSArray *keys = [[_properties allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
	NSUInteger i, count = [keys count];
	for (i = 0; i < count; i++)
	{
		NSString *key = [keys objectAtIndex:i];
		NSString *keyStr = key;
		if (![key oo_isSimpleJSIdentifier])  keyStr = [key oo_javaScriptLiteral];
		OOTrExpression *value = [_properties objectForKey:key];
		
		[result appendFormat:@"%@%@: %@", IndentTabs(indentLevel + 1), keyStr,
		 [value jsExpressionCodeForPrecedence:kPrecedenceComma + 1
							  withIndentLevel:indentLevel + 1]];
		if (i < count - 1)  [result appendString:@",\n"];
		else  [result appendString:@"\n"];
	}
	
	[result appendFormat:@"%@}", IndentTabs(indentLevel)];
	
	return result;
}


- (BOOL) isEqual:(id)other
{
	if (self == other)  return YES;
	
	if ([other isKindOfClass:[OOTrObjectDeclaration class]])
	{
		return [_properties isEqualToDictionary:[other properties]];
	}
	
	return NO;
}

@end


@implementation OOTrArrayDeclaration

- (id) initWithExpressions:(NSArray *)expressions
{
	if ((self = [super init]))
	{
		_array = [expressions copy];
	}
	
	return self;
}


+ (id) declarationWithExpressions:(NSArray *)expressions
{
	AssertArrayContentClass(expressions, OOTrExpression);
	return [[[self alloc] initWithExpressions:expressions] autorelease];
}


+ (id) declarationWithStrings:(NSArray *)strings
{
	AssertArrayContentClass(strings, NSString);
	
	NSMutableArray *expressions = [NSMutableArray arrayWithCapacity:[strings count]];
	
	NSString *string = nil;
	foreach (string, strings)
	{
		[expressions addObject:TrSTR(string)];
	}
	
	return [[[self alloc] initWithExpressions:expressions] autorelease];
}


- (void) dealloc
{
	DESTROY(_array);
	
	[super dealloc];
}


- (NSArray *) array
{
	return (_array != nil) ? _array : [NSArray array];
}


- (NSUInteger) precedence
{
	return kPrecedenceAtom;
}


- (BOOL) isSideEffectFreeDefault
{
	id expr = nil;
	foreach (expr, _array)
	{
		if (![expr isSideEffectFree])  return NO;
	}
	
	return YES;
}


- (BOOL) hasKnownBooleanValue
{
	return YES;
}


- (BOOL) boolValue
{
	// Any object is considered "true".
	return YES;
}


- (NSString *) descriptionComponents
{
	return $sprintf(@"[%lu]", (long)[_array count]);
}


- (NSString *) jsExpressionCodeWithIndentLevel:(NSUInteger)indentLevel
{
	NSMutableString *result = [NSMutableString string];
	[result appendString:@"["];
	
	NSUInteger i, count = [_array count];
	for (i = 0; i < count; i++)
	{
		[result appendString:[[_array objectAtIndex:i] jsExpressionCodeForPrecedence:kPrecedenceComma + 1 withIndentLevel:indentLevel]];
		if (i < count - 1)  [result appendString:@", "];
	}
	
	[result appendString:@"]"];
	
	return result;
}


- (BOOL) isEqual:(id)other
{
	if (self == other)  return YES;
	
	if ([other isKindOfClass:[OOTrArrayDeclaration class]])
	{
		return [_array isEqualToArray:[other array]];
	}
	
	return NO;
}

@end


@implementation OOTrOperator

- (BOOL) isRightAssociative
{
	// Right-associative operators must override.
	return NO;
}

@end


@implementation OOTrUnaryOperator

- (id) initWithArgument:(OOTrExpression *)argument
{
	if (EXPECT_NOT(argument == nil))
	{
		[self release];
		return nil;
	}
	
	if ((self = [super init]))
	{
		_argument = [argument retain];
	}
	return self;
}


+ (id) operatorWithArgument:(OOTrExpression *)argument
{
	return [[[self alloc] initWithArgument:argument] autorelease];
}


- (void) dealloc
{
	DESTROY(_argument);
	
	[super dealloc];
}


- (id) argument
{
	return _argument;
}


- (NSString *) operatorSymbol
{
	ThrowSubclassResponsibility();
}


- (NSString *) formatWithArgumentJS:(NSString *)argumentJS
{
	// Default: assume prefix operator with no space.
	return [[self operatorSymbol] stringByAppendingString:argumentJS];
}


- (NSString *) jsExpressionCodeWithIndentLevel:(NSUInteger)indentLevel
{
	return [self formatWithArgumentJS:[_argument jsExpressionCodeForPrecedence:[self precedence] withIndentLevel:indentLevel]];
}


- (NSString *) descriptionComponents
{
	return [self formatWithArgumentJS:@"x"];
}


- (BOOL) isSideEffectFreeDefault
{
	// Note: overridden in categories where appropriate.
	return [_argument isSideEffectFree];
}


- (BOOL) isEqual:(id)other
{
	if (self == other)  return YES;
	
	if ([self class] == [other class])	// Exact match only, no subclasses.
	{
		return [[self argument] isEqual:[other argument]];
	}
	
	return NO;
}

@end


@implementation OOTrUnaryWordOperator

- (NSString *) formatWithArgumentJS:(NSString *)argumentJS
{
	return $sprintf(@"%@ %@", [self operatorSymbol], argumentJS);
}

@end


@implementation OOTrPostfixUnaryOperator

- (NSString *) formatWithArgumentJS:(NSString *)argumentJS
{
	return [argumentJS stringByAppendingString:[self operatorSymbol]];
}

@end


@implementation OOTrBinaryOperator

- (id) initWithLeftArgument:(OOTrExpression *)left rightArgument:(OOTrExpression *)right
{
	if (EXPECT_NOT(left == nil || right == nil))
	{
		[self release];
		return nil;
	}
	
	if ((self = [super init]))
	{
		_leftArgument = [left retain];
		_rightArgument = [right retain];
	}
	
	return self;
}


+ (id) operatorWithLeftArgument:(OOTrExpression *)left rightArgument:(OOTrExpression *)right
{
	return [[[self alloc] initWithLeftArgument:left rightArgument:right] autorelease];
}


- (void) dealloc
{
	DESTROY(_leftArgument);
	DESTROY(_rightArgument);
	
	[super dealloc];
}


- (id) leftArgument
{
	return _leftArgument;
}


- (id) rightArgument
{
	return _rightArgument;
}


- (NSString *) operatorSymbol
{
	ThrowSubclassResponsibility();
}


- (NSString *) formatWithLeftJS:(NSString *)leftJS rightJS:(NSString *)rightJS indentLevel:(NSUInteger)indentLevel
{
	// Default: "x <op> y"
	return $sprintf(@"%@ %@ %@", leftJS, [self operatorSymbol], rightJS);
}


- (NSString *) jsExpressionCodeWithIndentLevel:(NSUInteger)indentLevel
{
	NSUInteger precedence = [self precedence];
	BOOL rightAssociative = [self isRightAssociative];
	
	return [self formatWithLeftJS:[_leftArgument jsExpressionCodeForPrecedence:precedence - rightAssociative withIndentLevel:indentLevel]
						  rightJS:[_rightArgument jsExpressionCodeForPrecedence:precedence - !rightAssociative withIndentLevel:indentLevel]
					  indentLevel:indentLevel];
}


- (NSString *) descriptionComponents
{
	return [self formatWithLeftJS:@"x" rightJS:@"y" indentLevel:0];
}


// Subclasses with side effects better take note!
- (BOOL) isSideEffectFreeDefault
{
	return [_leftArgument isSideEffectFree] && [_rightArgument isSideEffectFree];
}


- (BOOL) isEqual:(id)other
{
	if (self == other)  return YES;
	
	if ([self class] == [other class])	// Exact match only, no subclasses.
	{
		return [[self leftArgument] isEqual:[other leftArgument]] && [[self rightArgument] isEqual:[other rightArgument]];
	}
	
	return NO;
}

@end


@implementation OOTrPropertyAccessOperator: OOTrBinaryOperator

+ (id) operatorWithObject:(id)object property:(id)property
{
	NSParameterAssert([object isKindOfClass:[OOTrExpression class]] || [object isKindOfClass:[NSString class]]);
	NSParameterAssert([property isKindOfClass:[OOTrExpression class]] || [property isKindOfClass:[NSString class]]);
	
	if ([object isKindOfClass:[NSString class]])
	{
		object = TrID(object);
		if (object == nil)  return nil;
	}
	
	if ([property isKindOfClass:[NSString class]])
	{
		property = TrSTR(property);
	}
	
	return [self operatorWithLeftArgument:object rightArgument:property];
}


- (NSUInteger) precedence
{
	return kPrecedencePropertyAccess;
}


- (NSString *) operatorSymbol
{
	return @"[]";
}


- (NSString *) formatWithLeftJS:(NSString *)leftJS rightJS:(NSString *)rightJS indentLevel:(NSUInteger)indentLevel
{
	id rightArg = [self rightArgument];
	
	if ([rightArg isKindOfClass:[OOTrIdentifier class]])
	{
		return $sprintf(@"%@.%@", leftJS, rightJS);
	}
	
	return $sprintf(@"%@[%@]", leftJS, rightJS);
}


/*
	Strictly speaking, property access may have side effects since it will
	call a callback for native objects. However, for our purposes we can
	ignore this and assume getters are well-behaved. Note that assigning to a
	property or calling a method will be effectful because the assignment and
	call operators are.

- (BOOL) isSideEffectFreeDefault
{
	return NO;
}
*/

@end


@implementation OOTrFunctionCallOperator

- (id) initWithCallee:(OOTrExpression *)callee arguments:(NSArray *)arguments
{
	if (callee == nil)
	{
		[self release];
		return nil;
	}
	
	if ((self = [super init]))
	{
		_callee = [callee retain];
		_arguments = [arguments retain];
	}
	
	return self;
}


+ (id) operatorWithCallee:(id)callee arguments:(NSArray *)arguments
{
	if ([callee isKindOfClass:[NSString class]])
	{
		callee = TrID(callee);
	}
	NSParameterAssert([callee isKindOfClass:[OOTrExpression class]]);
	
	return [[[self alloc] initWithCallee:callee arguments:arguments] autorelease];
}


- (void) dealloc
{
	DESTROY(_callee);
	DESTROY(_arguments);
	
	[super dealloc];
}


- (id) callee
{
	return _callee;
}


- (NSArray *) arguments
{
	return (_arguments != nil) ? _arguments : [NSArray array];
}


- (NSUInteger) precedence
{
	return kPrecedenceFunctionCall;
}


- (NSString *) operatorSymbol
{
	return @"()";
}


- (NSString *) jsExpressionCodeWithIndentLevel:(NSUInteger)indentLevel
{
	NSMutableString *result = [NSMutableString string];
	
	// If callee is a function declaration, wrap it in parentheses.
	BOOL directInvocation = [_callee isKindOfClass:[OOTrFunctionDeclaration class]];
	
	if (directInvocation)  [result appendString:@"("];
	[result appendString:[_callee jsExpressionCodeForPrecedence:[self precedence] withIndentLevel:indentLevel]];
	if (directInvocation)  [result appendString:@")"];
	
	[result appendString:@"("];
	
	NSUInteger i, count = [_arguments count];
	for (i = 0; i < count; i++)
	{
		[result appendString:[[_arguments objectAtIndex:i] jsExpressionCodeForPrecedence:kPrecedenceComma + 1 withIndentLevel:indentLevel]];
		if (i < count - 1)  [result appendString:@", "];
	}
	
	[result appendString:@")"];
	
	return result;
}


- (NSString *) descriptionComponents
{
	NSString *name = @"f";
	if ([_callee isKindOfClass:[OOTrIdentifier class]])  name = [_callee name];
	return $sprintf(@"%@()", name);
}


- (BOOL) isSideEffectFreeDefault
{
	return NO;
}

@end


@implementation OOTrConditionalOperator

- (id) initWithCondition:(OOTrExpression *)condition trueValue:(OOTrExpression *)trueValue falseValue:(OOTrExpression *)falseValue
{
	if (condition == nil || trueValue == nil || falseValue == nil)
	{
		[self release];
		return nil;
	}
	
	if ((self = [super init]))
	{
		_condition = [condition retain];
		_trueValue = [trueValue retain];
		_falseValue = [falseValue retain];
	}
	
	return self;
}


+ (id) operatorWithCondition:(OOTrExpression *)condition trueValue:(OOTrExpression *)trueValue falseValue:(OOTrExpression *)falseValue
{
	return [[[self alloc] initWithCondition:condition trueValue:trueValue falseValue:falseValue] autorelease];
}


- (void) dealloc
{
	DESTROY(_condition);
	DESTROY(_trueValue);
	DESTROY(_falseValue);
	
	[super dealloc];
}


- (id) condition
{
	return _condition;
}


- (id) trueValue
{
	return _trueValue;
}


- (id) falseValue
{
	return _falseValue;
}


- (NSUInteger) precedence
{
	return kPrecedenceConditional;
}


- (NSString *) operatorSymbol
{
	return @"?:";
}


- (NSString *) jsExpressionCodeWithIndentLevel:(NSUInteger)indentLevel
{
	// Deliberately uses kPrecedenceFunctionCall so most subexpressions are parenthesized, even when not needed.
	return $sprintf(@"%@ ? %@ : %@",
					[_condition jsExpressionCodeForPrecedence:kPrecedenceFunctionCall withIndentLevel:indentLevel],
					[_trueValue jsExpressionCodeForPrecedence:kPrecedenceFunctionCall withIndentLevel:indentLevel],
					[_falseValue jsExpressionCodeForPrecedence:kPrecedenceFunctionCall withIndentLevel:indentLevel]);
}


- (NSString *) descriptionComponents
{
	return @"c ? x : y";
}


- (BOOL) isSideEffectFreeDefault
{
	return [_condition isSideEffectFree] && [_trueValue isSideEffectFree] && [_falseValue isSideEffectFree];
}


- (BOOL) isEqual:(id)other
{
	if (self == other)  return YES;
	
	if ([self class] == [other class])
	{
		return [[self condition] isEqual:[(OOTrConditionalOperator *)other condition]] &&
				[[self trueValue] isEqual:[other trueValue]] && 
				[[self falseValue] isEqual:[other falseValue]];
	}
	
	return NO;
}

@end


@implementation OOTrAssignmentOperator

- (BOOL) isRightAssociative
{
	return YES;
}


- (BOOL) isSideEffectFreeDefault
{
	return NO;
}


- (NSString *) formatWithLeftJS:(NSString *)leftJS rightJS:(NSString *)rightJS indentLevel:(NSUInteger)indentLevel
{
	if ([[self rightArgument] isKindOfClass:[OOTrObjectDeclaration class]])
	{
		return $sprintf(@"%@ %@\n%@%@", leftJS, [self operatorSymbol], IndentTabs(indentLevel), rightJS);
	}
	else
	{
		return [super formatWithLeftJS:leftJS rightJS:rightJS indentLevel:indentLevel];
	}
}

@end


@implementation OOTrCommaOperator

- (NSUInteger) precedence
{
	return kPrecedenceComma;
}


- (NSString *) operatorSymbol
{
	return @",";
}


- (NSString *) formatWithLeftJS:(NSString *)leftJS rightJS:(NSString *)rightJS indentLevel:(NSUInteger)indentLevel
{
	return $sprintf(@"%@, %@", leftJS, rightJS);
}

@end


/*
	Macro to define concrete operator subclasses which don't require any
	special formatting.
*/
#define OPERATOR(name, symbol) \
@implementation OOTr##name##Operator \
- (NSUInteger) precedence  { return kPrecedence##name; } \
- (NSString *) operatorSymbol  { return symbol; } \
@end

// Macros to define operator properties.
#define RIGHT_ASSOCIATIVE(op)  \
@implementation OOTr##op##Operator (RightAssociative) \
- (BOOL) isRightAssociative  { return YES; } \
@end

#define HAS_SIDE_EFFECTS(op)  \
@implementation OOTr##op##Operator (SideEffects) \
- (BOOL) isSideEffectFreeDefault  { return NO; } \
@end

#define HAS_NUMERIC_TYPE(op)  \
@implementation OOTr##op##Operator (Numeric) \
- (BOOL) hasNumericTypeDefault  { return YES; } \
@end

#define HAS_BOOLEAN_TYPE(op)  \
@implementation OOTr##op##Operator (Boolean) \
- (BOOL) hasBooleanTypeDefault  { return YES; } \
@end

#define HAS_ASSIGNMENT_FORM(op)  \
@implementation OOTr##op##Operator (AssigmentForm) \
- (BOOL) hasAssignmentForm  { return YES; } \
- (Class) assigmentForm  { return [OOTr##op##AssignOperator class]; } \
@end


OPERATOR(New, @"new")
RIGHT_ASSOCIATIVE(New)
HAS_SIDE_EFFECTS(New)

OPERATOR(PostIncrement, @"++")
HAS_SIDE_EFFECTS(PostIncrement)
HAS_NUMERIC_TYPE(PostIncrement)
OPERATOR(PostDecrement, @"--")
HAS_SIDE_EFFECTS(PostDecrement)
HAS_NUMERIC_TYPE(PostDecrement)

OPERATOR(Delete, @"delete")
RIGHT_ASSOCIATIVE(Delete)
HAS_SIDE_EFFECTS(Delete)
OPERATOR(Void, @"void")
RIGHT_ASSOCIATIVE(Void)
OPERATOR(Typeof, @"typeof")
RIGHT_ASSOCIATIVE(Typeof)
OPERATOR(PreIncrement, @"++")
RIGHT_ASSOCIATIVE(PreIncrement)
HAS_SIDE_EFFECTS(PreIncrement)
HAS_NUMERIC_TYPE(PreIncrement)
OPERATOR(PreDecrement, @"--")
RIGHT_ASSOCIATIVE(PreDecrement)
HAS_SIDE_EFFECTS(PreDecrement)
HAS_NUMERIC_TYPE(PreDecrement)
OPERATOR(UnaryPlus, @"+")
HAS_NUMERIC_TYPE(UnaryPlus)
OPERATOR(UnaryMinus, @"-")
HAS_NUMERIC_TYPE(UnaryMinus)
OPERATOR(BitwiseNot, @"~")
HAS_NUMERIC_TYPE(BitwiseNot)
OPERATOR(LogicalNot, @"!")
HAS_BOOLEAN_TYPE(LogicalNot)

OPERATOR(Multiply, @"*")
HAS_NUMERIC_TYPE(Multiply)
HAS_ASSIGNMENT_FORM(Multiply)
OPERATOR(Divide, @"/")
HAS_NUMERIC_TYPE(Divide)
HAS_ASSIGNMENT_FORM(Divide)
OPERATOR(Remainder, @"%")
HAS_NUMERIC_TYPE(Remainder)
HAS_ASSIGNMENT_FORM(Remainder)

OPERATOR(Add, @"+")
// Not HAS_NUMERIC_TYPE; -hasNumericType is defined in OOTRJSSimplify.m.
HAS_ASSIGNMENT_FORM(Add)
OPERATOR(Subtract, @"-")
HAS_NUMERIC_TYPE(Subtract)
HAS_ASSIGNMENT_FORM(Subtract)

OPERATOR(ShiftLeft, @"<<")
HAS_NUMERIC_TYPE(ShiftLeft)
HAS_ASSIGNMENT_FORM(ShiftLeft)
OPERATOR(ShiftRight, @">>")
HAS_NUMERIC_TYPE(ShiftRight)
HAS_ASSIGNMENT_FORM(ShiftRight)
OPERATOR(ShiftRightUnsigned, @">>>")
HAS_NUMERIC_TYPE(ShiftRightUnsigned)
HAS_ASSIGNMENT_FORM(ShiftRightUnsigned)

OPERATOR(LessThanComparison, @"<")
HAS_BOOLEAN_TYPE(LessThanComparison)
OPERATOR(GreaterThanComparison, @">")
HAS_BOOLEAN_TYPE(GreaterThanComparison)
OPERATOR(LessThanOrEqualComparison, @"<=")
HAS_BOOLEAN_TYPE(LessThanOrEqualComparison)
OPERATOR(GreaterThanOrEqualComparison, @">=")
HAS_BOOLEAN_TYPE(GreaterThanOrEqualComparison)
OPERATOR(Instanceof, @"instanceof")
HAS_BOOLEAN_TYPE(Instanceof)
OPERATOR(In, @"in")
HAS_BOOLEAN_TYPE(In)

OPERATOR(EqualComparison, @"==")
HAS_BOOLEAN_TYPE(EqualComparison)
OPERATOR(NotEqualComparison, @"!=")
HAS_BOOLEAN_TYPE(NotEqualComparison)
OPERATOR(StrictlyEqualComparison, @"===")
HAS_BOOLEAN_TYPE(StrictlyEqualComparison)
OPERATOR(NotStrictlyEqualComparison, @"!==")
HAS_BOOLEAN_TYPE(NotStrictlyEqualComparison)

OPERATOR(BitwiseAnd, @"&")
HAS_NUMERIC_TYPE(BitwiseAnd)
HAS_ASSIGNMENT_FORM(BitwiseAnd)

OPERATOR(BitwiseXor, @"^")
HAS_NUMERIC_TYPE(BitwiseXor)
HAS_ASSIGNMENT_FORM(BitwiseXor)

OPERATOR(BitwiseOr, @"|")
HAS_NUMERIC_TYPE(BitwiseOr)
HAS_ASSIGNMENT_FORM(BitwiseOr)

OPERATOR(LogicalAnd, @"&&")
HAS_BOOLEAN_TYPE(LogicalAnd)	// Not strictly true, but probably OK for simplification. (See note in ECMA-262 5th Edition, 11.11.)

OPERATOR(LogicalOr, @"||")
HAS_BOOLEAN_TYPE(LogicalOr)		// Not strictly true as above.

// All assign operators have side effects and right-associativity by inheritance.
OPERATOR(Assign, @"=")
OPERATOR(MultiplyAssign, @"*=")
HAS_NUMERIC_TYPE(MultiplyAssign)
OPERATOR(DivideAssign, @"/=")
HAS_NUMERIC_TYPE(DivideAssign)
OPERATOR(RemainderAssign, @"%=")
HAS_NUMERIC_TYPE(RemainderAssign)
OPERATOR(AddAssign, @"+=")
// Not HAS_NUMERIC_TYPE; -hasNumericType is defined in OOTRJSSimplify.m.
OPERATOR(SubtractAssign, @"-=")
HAS_NUMERIC_TYPE(SubtractAssign)
OPERATOR(ShiftLeftAssign, @"<<=")
HAS_NUMERIC_TYPE(ShiftLeftAssign)
OPERATOR(ShiftRightAssign, @">>=")
HAS_NUMERIC_TYPE(ShiftRightAssign)
OPERATOR(ShiftRightUnsignedAssign, @">>>=")
HAS_NUMERIC_TYPE(ShiftRightUnsignedAssign)
OPERATOR(BitwiseAndAssign, @"&=")
HAS_NUMERIC_TYPE(BitwiseAndAssign)
OPERATOR(BitwiseXorAssign, @"^=")
HAS_NUMERIC_TYPE(BitwiseXorAssign)
OPERATOR(BitwiseOrAssign, @"|=")
HAS_NUMERIC_TYPE(BitwiseOrAssign)


@implementation OOTrVoidOperator (Boolean)

- (BOOL) hasKnownBooleanValue
{
	return YES;
}


- (BOOL) boolValue
{
	return NO;
}

@end


static void ThrowSubclassResponsibility_(Class class, SEL method)
{
	[NSException raise:NSGenericException format:@"[%@ %@] is a subclass responsibility.", class, NSStringFromSelector(method)];
	
	OO_UNREACHABLE();
	abort();
}


#ifndef NDEBUG
static void AssertArrayContentClass_(NSArray *array, Class expectedClass, const char *function)
{
	id element = nil;
	foreach (element, array)
	{
		if (![element isKindOfClass:expectedClass])
		{
			[NSException raise:NSInvalidArgumentException format:@"%s: expected array of %@, got %@.", function, expectedClass, [element class]];
		}
	}
}


static void AssertDictionaryContentClasses_(NSDictionary *dict, Class keyClass, Class valueClass, const char *function)
{
	id key = nil;
	foreachkey (key, dict)
	{
		id value = [dict objectForKey:key];
		if (![key isKindOfClass:keyClass] || ![value isKindOfClass:valueClass])
		{
			[NSException raise:NSInvalidArgumentException format:@"%s: expected dict of %@->%@, got %@->%@.", function, keyClass, valueClass, [key class], [value class]];
		}
	}
}
#endif


static NSString *IndentTabs(NSUInteger count)
{
	NSString * const staticTabs[] =
	{
		@"",
		@"\t",
		@"\t\t",
		@"\t\t\t",
		@"\t\t\t\t",
		@"\t\t\t\t\t",
		@"\t\t\t\t\t\t",
		@"\t\t\t\t\t\t\t"
	};
	
	if (count < sizeof staticTabs / sizeof *staticTabs)
	{
		return staticTabs[count];
	}
	else
	{
		NSMutableString *result = [NSMutableString stringWithCapacity:count];
		for (NSUInteger i = 0; i < count; i++)
		{
			[result appendString:@"\t"];
		}
		return result;
	}
}
