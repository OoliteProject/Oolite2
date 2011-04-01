/*

OOTrJSAST.h
ootranscript

Classes to construct abstract syntax trees for JavaScript. This does not
attempt to represent the entire language.


Copyright © 2010-2011 Jens Ayton

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

#import <OoliteBase/OoliteBase.h>

/*
	Some expressions may be cached; this clears the cache. Note that this may
	invalidate objects which have not been retained.
	
	Not all cached objects are cleared, as various singeltons may be created.
*/
void OOTrASTFlushCache(void);


@interface OOTrStatement: NSObject
{
	id						_simplified;
	NSMutableDictionary		*_annotations;
}

- (NSString *) jsStatementCode;
- (NSString *) jsStatementCodeWithIndentLevel:(NSUInteger)indentLevel;

/*	True if statement is definitely free of effects - assuming any native
	callbacks involved are sane. (For instance, the equality operator is
	considered side-effect free if its arguments are; a native callback might
	happen, but shouldn't be semantically meaningful. In the same way, the
	addition operator is considered side effect-free, even though it may
	call a toString() method.)
*/
- (BOOL) isSideEffectFree;

/*
	Annotations are arbitrary metadata attached to an AST node. While the
	properties of an AST node that describe the language are immutable, the
	annotations are mutable.
	
	When an AST is simplified, the annotations of the original node are copied
	to the simplified node.
	
	Note that since certain atoms (number, string, boolean, null and undefined
	literals, and identifiers) are uniqued, those objects will share
	annotations.
*/
- (id) annotationForKey:(NSString *)key;
- (void) setAnnotation:(id)annotation forKey:(NSString *)key;

- (void) setBooleanAnnotation:(BOOL)annotation forKey:(NSString *)key;

// True for let, currently false for anything else.
- (BOOL) isScopeLocalDeclaration;

@end


/*
	Annotation keys used internally.
 */
extern NSString * const kOOTrIsSideEffectFreeOverride;
extern NSString * const kOOTrHasNumericTypeOverride;
extern NSString * const kOOTrHasBooleanTypeOverride;


/*
	Macros to help build statements/expressions.
	TrNUM and TrSTR box numbers and strings as literals.
	TrID creates an identifier.
	TrYES, TrNO and TrBOOL deal with booleans.
	TrUOP and TrBOP build operator expressions. The name argument is the
	    unique part of the relevant class name, e.g. Add for OOTrAddOperator.
	TrCALL builds a function call.
	
	TrPROP builds a property access.
*/
#define TrNUM(num)					[OOTrNumberLiteral literalWithDoubleValue:(num)]
#define TrSTR(str)					[OOTrStringLiteral literalWithStringValue:(str)]
#define TrREGEXP(regexp, flagStr)	[OOTrRegExpLiteral literalWithRegExp:(regexp) flags:(flagStr)]
#define TrBOOL(value)				[OOTrBooleanLiteral literalWithBoolValue:(value)]
#define TrYES						TrBOOL(YES)
#define TrNO						TrBOOL(NO)
#define TrID(identifier)			[OOTrIdentifier identifierWithNonKeywordName:(identifier)]
#define TrUOP(name, arg)			[OOTr##name##Operator operatorWithArgument:(arg)]
#define TrBOP(name, left, right)	[OOTr##name##Operator operatorWithLeftArgument:(left) rightArgument:(right)]
#define TrCALL(callee, args...)		[OOTrFunctionCallOperator operatorWithCallee:(callee) arguments:$array(args)]
#define TrNULL						[OOTrNullLiteral nullLiteral]
#define TrUNDEFINED					[OOTrUndefinedLiteral undefinedLiteral]
#define TrTHIS						[OOTrThisLiteral thisLiteral]
#define TrVAR(name, val)			[OOTrVarStatement statementWithName:name initializer:val]
#define TrLET(name, val)			[OOTrLetStatement statementWithName:name initializer:val]

#define TrPROP(obj, prop)			[OOTrPropertyAccessOperator operatorWithObject:(obj) property:(prop)]

#define TrRETURN(expr)				[OOTrReturnStatement statementWithExpression:(expr)]
#define TrFUNC(name, args, bdy)		[OOTrFunctionDeclaration functionWithName:(name) arguments:(args) body:(bdy)]

// Specific operators.
#define TrADD(left, right)			TrBOP(Add, left, right)
#define TrSUB(left, right)			TrBOP(Subtract, left, right)
#define TrMUL(left, right)			TrBOP(Multiply, left, right)
#define TrDIV(left, right)			TrBOP(Divide, left, right)
#define TrREM(left, right)			TrBOP(Remainder, left, right)
#define TrEQUAL(left, right)		TrBOP(EqualComparison, left, right)
#define TrNEQUAL(left, right)		TrBOP(NotEqualComparison, left, right)
#define TrSEQUAL(left, right)		TrBOP(StrictlyEqualComparison, left, right)
#define TrNSEQUAL(left, right)		TrBOP(NotStrictlyEqualComparison, left, right)
#define TrLESS(left, right)			TrBOP(LessThanComparison, left, right)
#define TrGRTR(left, right)			TrBOP(GreaterThanComparison, left, right)
#define TrLESSEQL(left, right)		TrBOP(LessThanOrEqualComparison, left, right)
#define TrGRTREQL(left, right)		TrBOP(GreaterThanOrEqualComparison, left, right)
#define TrAND(left, right)			TrBOP(LogicalAnd, left, right)
#define TrOR(left, right)			TrBOP(LogicalOr, left, right)
#define TrNOT(arg)					TrUOP(LogicalNot, arg)
#define TrVOID(arg)					TrUOP(Void, arg)
#define TrASSIGN(left, right)		TrBOP(Assign, left, right)
#define TrCOMMA(left, right)		TrBOP(Comma, left, right)
#define TrDELETE(arg)				TrUOP(Delete, arg)

#define TrCOND(cond, tval, fval)	[OOTrConditionalOperator operatorWithCondition:(cond) trueValue:(tval) falseValue:(fval)]
#define TrIF(cond, tstmt, fstmt)	[OOTrConditionalStatement statementWithCondition:(cond) trueStatement:(tstmt) falseStatement:(fstmt)]

#define TrNULLSTMT					[OOTrCompoundStatement compoundStatementWithStatements:nil]


@interface OOTrExpression: OOTrStatement

- (NSString *) jsExpressionCode;
- (NSUInteger) precedence;

- (NSString *) jsExpressionCodeWithIndentLevel:(NSUInteger)indentLevel;
- (NSString *) jsExpressionCodeForPrecedence:(NSUInteger)precedence withIndentLevel:(NSUInteger)indentLevel;

@end


@interface OOTrReturnStatement: OOTrStatement
{
@private
	OOTrExpression			*_expression;
}

+ (id) statementWithExpression:(OOTrExpression *)expression;	// Expression is optional; elide for valueless return.

- (id) expression;

@end


@interface OOTrVarStatement: OOTrStatement
{
@private
	NSString				*_name;
	OOTrExpression			*_initializer;
}

+ (id) statementWithName:(NSString *)name initializer:(OOTrExpression *)initializer;

- (NSString *) name;
- (OOTrExpression *) initializer;

@end


@interface OOTrLetStatement: OOTrVarStatement
@end


// Compound statement: a sequence of zero or more statements - that is, a block.
@interface OOTrCompoundStatement: OOTrStatement
{
@private
	NSArray					*_statements;
}

+ (id) compoundStatementWithStatements:(NSArray *)statements;
+ (id) compoundStatementWithStatement:(OOTrStatement *)statement;

/*	If object is a compound statement, returns object.
	If object is any other type of statement, returns a compound statement
	containing that statement.
	If object is an array of statements, returns a compound statement
	containing those statements.
	If object is an array containing objects other than statements, result is
	undefined.
	If object is any other class, nil is returned.
*/
+ (id) compoundStatementWithObject:(id)object;

- (NSArray *) statements;

/*	True if self is equal to statement (i.e., identical or statement is a
	compound statement whose substatments are equal to self’s), or self
	contains a single statement which is equal to statement.
*/
- (BOOL) isEqualToOrWraps:(OOTrStatement *)statement;

- (BOOL) isNullStatement;	// True if it contains no statements.

@end


/*	if/else statement.
	
	The trueStatement and falseStatement may be any statement or an array of
	statements; in any case, they will be converted to OOTrCompoundStatements.
	(OOTrJSAST cannot generate control structures whose statements are not
	blocks. This is a feature. "else if" chaining is handled as a special
	case.)
	If there is a falseStatement but no trueStatement, the condition will be
	negated and the statements swapped. If both statements are nil, or the
	condition is nil, the factory method will return nil.
*/
@interface OOTrConditionalStatement: OOTrStatement
{
@private
	OOTrExpression			*_condition;
	OOTrCompoundStatement	*_trueStatement;
	OOTrCompoundStatement	*_falseStatement;
}

+ (id) statementWithCondition:(OOTrExpression *)condition
				trueStatement:(id)trueStatement
			   falseStatement:(id)falseStatement;

- (OOTrExpression *) condition;
- (OOTrCompoundStatement *) trueStatement;
- (OOTrCompoundStatement *) falseStatement;

@end


/*	A function's body may be specified as any statement type, but will be
	wrapped in a compound statement if it isn’t one already.
	All parameters are optional; if you want "function () {}" I’m not going
	to stop you.
*/
@interface OOTrFunctionDeclaration: OOTrExpression
{
@private
	NSString				*_name;
	NSArray					*_arguments;
	OOTrCompoundStatement	*_body;
}

+ (id) functionWithName:(NSString *)name		// Optional.
			  arguments:(NSArray *)arguments	// Array of strings; optional.
				   body:(id)body;				// OOTrStatement, OOTrCompoundStatement, or NSArray.

- (NSString *) name;
- (NSArray *) arguments;
- (OOTrCompoundStatement *) body;

@end


@interface OOTrNumberLiteral: OOTrExpression
{
@private
	double					_value;
}

+ (id) literalWithDoubleValue:(double)value;

- (double) doubleValue;
- (NSString *) stringValue;

@end


@interface OOTrStringLiteral: OOTrExpression
{
@private
	NSString				*_string;
}

+ (id) literalWithStringValue:(NSString *)string;

- (NSString *) stringValue;

@end


@interface OOTrRegExpLiteral: OOTrExpression
{
@private
	NSString				*_regExp;
	NSString				*_flags;
}

+ (id) literalWithRegExp:(NSString *)regExp flags:(NSString *)flags;

- (NSString *) regExp;
- (NSString *) flags;

@end



@interface OOTrExpression (Numeric)

/*	True for OOTrNumberLiteral, or OOTrStringLiteral whose value is a valid
	number literal. (Note that such strings can be used as mathematical
	operands in JavaScript, as in "8" - "5" == 3 -- except for addition, which
	becomes a concatenation if either side is a string.
	
	Also true for OOTrNullLiteral (0), OOTrUndefinedLiteral (NaN) and
	OOTrBooleanLiteral, as per section 9.3 of ECMA-262 5th Edition.
	
	This does not recognize constant expressions other than literals, but
	-simplified can handle some of those.
*/
- (BOOL) isNumericConstant;
- (double) doubleValue;

//	True for expressions of known number type.
- (BOOL) hasNumericType;

@end


@interface OOTrBooleanLiteral: OOTrExpression
{
@private
	BOOL					_value;
}

+ (id) literalWithBoolValue:(BOOL)value;

- (BOOL) boolValue;

@end


@interface OOTrExpression (Boolean)

/*	Like -isNumericConstant, this is true for literals with known boolean
	values, but not constant expressions generally.
	
	The conversions performed are equivalent to the ToBoolean operation
	defined in section 9.2 of ECMA-262 5th Edition.
*/
- (BOOL) hasKnownBooleanValue;
- (BOOL) boolValue;
- (OOTrBooleanLiteral *) booleanLiteralValue;

/*	True for expressions of known boolean type. Not all expressions with a known
	boolean value are of boolean type (example: undefined), and not all
	expressions of boolean type have a known boolean value (example: comparison
	operators).
*/
- (BOOL) hasBooleanType;

- (OOTrExpression *) logicalInverse;

@end


@interface OOTrIdentifier: OOTrExpression
{
@private
	NSString				*_name;
}

// Caller is responsible for ensuring name is a valid identifier.
+ (id) identifierWithName:(NSString *)name;

// This variant returns nil if name is a keyword.
+ (id) identifierWithNonKeywordName:(NSString *)name;

- (NSString *) name;

@end


@interface OOTrUndefinedLiteral: OOTrExpression

+ (id) undefinedLiteral;

@end


@interface OOTrNullLiteral: OOTrExpression

+ (id) nullLiteral;

@end


@interface OOTrThisLiteral: OOTrExpression

+ (id) thisLiteral;

@end


@interface OOTrObjectDeclaration: OOTrExpression
{
@private
	NSDictionary			*_properties;
}

+ (id) declarationWithProperties:(NSDictionary *)properties;

- (NSDictionary *) properties;

@end


@interface OOTrArrayDeclaration: OOTrExpression
{
@private
	NSArray					*_array;
}

+ (id) declarationWithExpressions:(NSArray *)expressions;
+ (id) declarationWithStrings:(NSArray *)strings;

- (NSArray *) array;

@end


@interface OOTrOperator: OOTrExpression

- (BOOL) isRightAssociative;

@end


@interface OOTrUnaryOperator: OOTrOperator
{
@private
	id						_argument;
}

+ (id) operatorWithArgument:(OOTrExpression *)argument;

- (id) argument;

- (NSString *) operatorSymbol;

@end


@interface OOTrBinaryOperator: OOTrOperator
{
@private
	id						_leftArgument;
	id						_rightArgument;
}

+ (id) operatorWithLeftArgument:(OOTrExpression *)left rightArgument:(OOTrExpression *)right;

- (id) leftArgument;
- (id) rightArgument;

- (NSString *) operatorSymbol;

@end


// These are effectively internal classes exposed only for reasons of inheritance.
@interface OOTrUnaryWordOperator: OOTrUnaryOperator
@end
@interface OOTrPostfixUnaryOperator: OOTrUnaryOperator
@end
@interface OOTrAssignmentOperator: OOTrBinaryOperator
@end


/*
	Operators follow.
	
	Operator precedence and associativity taken from:
	http://www.codehouse.com/javascript/precedence/
*/

/*** Precedence 1 operators ***/

/*	x[y] or x.y -- the latter form is used if y is an identifier or a string
	literal which is a simple identifier. (“Simple identifier” here means C
	identifier; JS supports a wider character set, but that's potentially
	confusing.)
	
	When applied to a CallExpression [ECMAScript concept, not the same as
	OOTrFunctionCallOperator], this has precedence 2. This case currently
	isn’t handled, although it would be simple if we had a representation of
	CallExpressions.
*/
@interface OOTrPropertyAccessOperator: OOTrBinaryOperator

+ (id) operatorWithObject:(id)object	// object may be an OOTrExpression or an NSString (which is converted to an identifier).
				 property:(id)property;	// property may be an OOTrExpression or an NSString.

@end


// new x
@interface OOTrNewOperator: OOTrUnaryWordOperator
@end


/*** Precedence 2 operators ***/

// f(...)
@interface OOTrFunctionCallOperator: OOTrOperator
{
@private
	id						_callee;
	NSArray					*_arguments;
}

+ (id) operatorWithCallee:(id)callee			// OOTrExpression or NSString (identifier).
				arguments:(NSArray *)arguments;	// Array of OOTrExpressions.

- (id) callee;
- (NSArray *) arguments;

@end


/*** Precedence 3 operators ***/

// x++
@interface OOTrPostIncrementOperator: OOTrPostfixUnaryOperator
@end


// x--
@interface OOTrPostDecrementOperator: OOTrPostfixUnaryOperator
@end


/*** Precedence 4 operators ***/

// delete x
@interface OOTrDeleteOperator: OOTrUnaryWordOperator
@end


// void x
@interface OOTrVoidOperator: OOTrUnaryWordOperator
@end


// typeof x
@interface OOTrTypeofOperator: OOTrUnaryWordOperator
@end


// ++x
@interface OOTrPreIncrementOperator: OOTrUnaryOperator
@end


// --x
@interface OOTrPreDecrementOperator: OOTrUnaryOperator
@end


// +x
@interface OOTrUnaryPlusOperator: OOTrUnaryOperator
@end


// -x
@interface OOTrUnaryMinusOperator: OOTrUnaryOperator
@end


// ~x
@interface OOTrBitwiseNotOperator: OOTrUnaryOperator
@end


// !x
@interface OOTrLogicalNotOperator: OOTrUnaryOperator
@end


/*** Precedence 5 operators ***/

// x * y
@interface OOTrMultiplyOperator: OOTrBinaryOperator
@end


// x / y
@interface OOTrDivideOperator: OOTrBinaryOperator
@end


// x % y
@interface OOTrRemainderOperator: OOTrBinaryOperator
@end


/*** Precedence 6 operators ***/

// x + y
@interface OOTrAddOperator: OOTrBinaryOperator
@end


// x - y
@interface OOTrSubtractOperator: OOTrBinaryOperator
@end


/*** Precedence 7 operators ***/

// x << y
@interface OOTrShiftLeftOperator: OOTrBinaryOperator
@end


// x >> y
@interface OOTrShiftRightOperator: OOTrBinaryOperator
@end


// x >>> y
@interface OOTrShiftRightUnsignedOperator: OOTrBinaryOperator
@end


/*** Precedence 8 operators ***/

// x < y
@interface OOTrLessThanComparisonOperator: OOTrBinaryOperator
@end


// x > y
@interface OOTrGreaterThanComparisonOperator: OOTrBinaryOperator
@end


// x <= y
@interface OOTrLessThanOrEqualComparisonOperator: OOTrBinaryOperator
@end


// x >= y
@interface OOTrGreaterThanOrEqualComparisonOperator: OOTrBinaryOperator
@end


// x instanceof y
@interface OOTrInstanceofOperator: OOTrBinaryOperator
@end


// x in y
@interface OOTrInOperator: OOTrBinaryOperator
@end


/*** Precedence 9 operators ***/

// x == y
@interface OOTrEqualComparisonOperator: OOTrBinaryOperator
@end


// x != y
@interface OOTrNotEqualComparisonOperator: OOTrBinaryOperator
@end


// x == y
@interface OOTrStrictlyEqualComparisonOperator: OOTrBinaryOperator
@end


// x != y
@interface OOTrNotStrictlyEqualComparisonOperator: OOTrBinaryOperator
@end


/*** Precedence 10 operators ***/

// x & y
@interface OOTrBitwiseAndOperator: OOTrBinaryOperator
@end


/*** Precedence 11 operators ***/

// x ^ y
@interface OOTrBitwiseXorOperator: OOTrBinaryOperator
@end


/*** Precedence 12 operators ***/

// x | y
@interface OOTrBitwiseOrOperator: OOTrBinaryOperator
@end


/*** Precedence 13 operators ***/

// x && y
@interface OOTrLogicalAndOperator: OOTrBinaryOperator
@end


/*** Precedence 14 operators ***/

// x || y
@interface OOTrLogicalOrOperator: OOTrBinaryOperator
@end


/*** Precedence 16 operators ***/

@interface OOTrConditionalOperator: OOTrOperator
{
@private
	id					_condition;
	id					_trueValue;
	id					_falseValue;
}

+ (id) operatorWithCondition:(OOTrExpression *)condition trueValue:(OOTrExpression *)trueValue falseValue:(OOTrExpression *)falseValue;

- (id) condition;
- (id) trueValue;
- (id) falseValue;

@end


/*** Precedence 16 operators ***/

// x = y
@interface OOTrAssignOperator: OOTrAssignmentOperator
@end


// x *= y
@interface OOTrMultiplyAssignOperator: OOTrAssignmentOperator
@end


// x /= y
@interface OOTrDivideAssignOperator: OOTrAssignmentOperator
@end


// x %= y
@interface OOTrRemainderAssignOperator: OOTrAssignmentOperator
@end


// x += y
@interface OOTrAddAssignOperator: OOTrAssignmentOperator
@end


// x -= y
@interface OOTrSubtractAssignOperator: OOTrAssignmentOperator
@end


// x <<= y
@interface OOTrShiftLeftAssignOperator: OOTrAssignmentOperator
@end


// x >>= y
@interface OOTrShiftRightAssignOperator: OOTrAssignmentOperator
@end


// x >>>= y
@interface OOTrShiftRightUnsignedAssignOperator: OOTrAssignmentOperator
@end


// x &= y
@interface OOTrBitwiseAndAssignOperator: OOTrAssignmentOperator
@end


// x ^= y
@interface OOTrBitwiseXorAssignOperator: OOTrAssignmentOperator
@end


// x |= y
@interface OOTrBitwiseOrAssignOperator: OOTrAssignmentOperator
@end


/*** Precedence 17 operators ***/

// x, y
@interface OOTrCommaOperator: OOTrBinaryOperator
@end
