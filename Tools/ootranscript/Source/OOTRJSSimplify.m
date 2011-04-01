//
//  OOTRJSSimplify.m
//  ootranscript
//
//  Created by Jens Ayton on 2010-07-22.
//  Copyright 2010 Jens Ayton. All rights reserved.
//

#import "OOTRJSSimplify.h"
#import "NSString+OOJavaScriptLiteral.h"


@interface OOTrExpression (LogicalInversion)

/*	True if logical inversion is possible without inserting a LogicalNot node.
	Example: transformation from Equal to NotEqual.
*/
- (BOOL) hasSimpleLogicalInversion;

@end


@implementation OOTrStatement (Simplification)

- (id) performSimplification
{
	return self;
}


- (id) simplified
{
	if (_simplified == nil)
	{
		OOTrStatement *simplified = [[self performSimplification] retain];
		if (simplified != nil)
		{
			if (simplified->_annotations == nil)
			{
				simplified->_annotations = [_annotations mutableCopy];
			}
			else if (_annotations != nil)
			{
				[simplified->_annotations addEntriesFromDictionary:_annotations];
			}
			_simplified = simplified;
		}
		else
		{
			simplified = self;
		}
	}
	
	return _simplified;
}

@end


@implementation OOTrExpression (Simplification)

- (BOOL) hasSimpleLogicalInversion
{
	return NO;
}

@end


@implementation OOTrCompoundStatement (Simplification)

- (id) performSimplification
{
	NSMutableArray *simplifiedStatements = [NSMutableArray arrayWithCapacity:[_statements count]];
	id statement = nil;
	BOOL anyChanged = NO;
	BOOL recurse = NO;
	
	foreach (statement, _statements)
	{
		id simplified = [statement simplified];
		if ([simplified isSideEffectFree])  simplified = nil;
		
		// Flatten naked comma operators.
		if ([simplified isKindOfClass:[OOTrCommaOperator class]])
		{
			[simplifiedStatements addObject:[simplified leftArgument]];
			[simplifiedStatements addObject:[simplified rightArgument]];
			anyChanged = YES;
			recurse = YES;
		}
		else
		{
			if (simplified != statement)  anyChanged = YES;
			if (simplified != nil)  [simplifiedStatements addObject:simplified];
		}
	}
	
	// TODO: find sequences of if()s, and look for shared prefixes & switch opportunities.
	
	/*	We unpack statements here even though repacking will generally
		happen, because it’s possible an unpacked statment will be
		optimized where a packed one isn’t.
	*/
	if (anyChanged)
	{
		if ([simplifiedStatements count] == 1)  return [simplifiedStatements objectAtIndex:0];
		id result = [OOTrCompoundStatement compoundStatementWithStatements:simplifiedStatements];
		if (recurse)  result = [result simplified];
		return result;
	}
	if ([_statements count] == 1)
	{
		return [_statements objectAtIndex:0];
	}
	return self;
}

@end


@implementation OOTrUnaryOperator (Simplification)

- (id) performSimplification
{
	id argument = [self argument];
	id simplifiedArgument = [argument simplified];
	
	if (simplifiedArgument == argument)  return self;
	return [[self class] operatorWithArgument:simplifiedArgument];
}

@end


@implementation OOTrBinaryOperator (Simplification)

- (id) performSimplification
{
	id left = [self leftArgument];
	id right = [self rightArgument];
	id simplifiedLeft = [left simplified];
	id simplifiedRight = [right simplified];
	
	if (simplifiedLeft == left && simplifiedRight == right)  return self;
	return [[self class] operatorWithLeftArgument:simplifiedLeft rightArgument:simplifiedRight];
}


- (BOOL) hasAssignmentForm
{
	return NO;
}


- (Class) assigmentForm
{
	return Nil;
}

@end


@implementation OOTrFunctionCallOperator (Simplification)

- (id) performSimplification
{
	id simplifiedCallee = [_callee simplified];
	
	NSMutableArray *simplifiedArguments = [NSMutableArray arrayWithCapacity:[_arguments count]];
	id arg = nil;
	BOOL argsChanged = NO;
	foreach (arg, _arguments)
	{
		id simplified = [arg simplified];
		if (simplified != arg)  argsChanged = YES;
		[simplifiedArguments addObject:simplified];
	}
	
	if (argsChanged || simplifiedCallee != _callee)
	{
		return [OOTrFunctionCallOperator operatorWithCallee:simplifiedCallee arguments:simplifiedArguments];
	}
	return self;
}

@end


@implementation OOTrFunctionDeclaration (Simplification)

- (id) performSimplification
{
	id simplifiedBody = [_body simplified];
	
	if (simplifiedBody != _body)  return [OOTrFunctionDeclaration functionWithName:_name arguments:_arguments body:simplifiedBody];
	return self;
}

@end


@implementation OOTrUnaryPlusOperator (Simplification)

- (id) performSimplification
{
	id argument = [self argument];
	id simplified = [argument simplified];
	
	if ([simplified hasNumericType])
	{
		return simplified;
	}
	else if ([simplified isNumericConstant])
	{
		return TrNUM([simplified doubleValue]);
	}
	
	if (simplified == argument)  return self;
	return TrUOP(UnaryPlus, simplified);
}

@end


@implementation OOTrUnaryMinusOperator (Simplification)

- (id) performSimplification
{
	id argument = [self argument];
	id simplified = [argument simplified];
	
	if ([simplified isKindOfClass:[OOTrNumberLiteral class]])
	{
		return TrNUM(-[simplified doubleValue]);
	}
	else if ([simplified isNumericConstant])
	{
		return TrNUM(-[simplified doubleValue]);
	}
	
	if (simplified == argument)  return self;
	return TrUOP(UnaryMinus, simplified);
}

@end


@implementation OOTrAddOperator (Simplification)

- (id) performSimplification
{
	id left = [self leftArgument];
	id right = [self rightArgument];
	id simplifiedLeft = [left simplified];
	id simplifiedRight = [right simplified];
	
	BOOL leftIsNumber = [simplifiedLeft isNumericConstant];
	BOOL rightIsNumber = [simplifiedRight isNumericConstant];
	BOOL leftIsString = [simplifiedLeft isKindOfClass:[OOTrStringLiteral class]];
	BOOL rightIsString = [simplifiedRight isKindOfClass:[OOTrStringLiteral class]];
	
	if ((leftIsString && (rightIsString || rightIsNumber)) || (leftIsNumber && rightIsString))
	{
		// Concatenate strings.
		return TrSTR([[simplifiedLeft stringValue] stringByAppendingString:[simplifiedRight stringValue]]);
	}
	
	if (leftIsNumber && rightIsNumber)
	{
		// Add.
		NSAssert(!leftIsString && !rightIsString, @"Cases involving strings should have been handled by now.");
		return TrNUM([simplifiedLeft doubleValue] + [simplifiedRight doubleValue]);
	}
	
	if ([simplifiedLeft hasNumericType] && [simplifiedRight hasNumericType])
	{
		// Check for negative right and convert to subtraction.
		if (rightIsNumber)
		{
			double value = [simplifiedRight doubleValue];
			if (value < 0.0f)
			{
				return [TrSUB(simplifiedLeft, TrNUM(-value)) simplified];
			}
		}
		else
		{
			if ([simplifiedRight isKindOfClass:[OOTrUnaryMinusOperator class]])
			{
				right = [simplifiedRight argument];
				return [TrSUB(simplifiedLeft, right) simplified];
			}
		}
	}
	
	if (simplifiedLeft == left && simplifiedRight == right)  return self;
	return TrADD(simplifiedLeft, simplifiedRight);
}


- (BOOL) hasNumericTypeDefault
{
	// If args are not known to be numeric, they might be strings. If either is a string, + is concatenation.
	return [[self leftArgument] hasNumericType] && [[self rightArgument] hasNumericType];
}

@end


@implementation OOTrSubtractOperator (Simplification)

- (id) performSimplification
{
	id left = [self leftArgument];
	id right = [self rightArgument];
	id simplifiedLeft = [left simplified];
	id simplifiedRight = [right simplified];
	
	if ([simplifiedLeft isNumericConstant] && [simplifiedRight isNumericConstant])
	{
		return TrNUM([simplifiedLeft doubleValue] - [simplifiedRight doubleValue]);
	}
	
	if (simplifiedLeft == left && simplifiedRight == right)  return self;
	return TrADD(simplifiedLeft, simplifiedRight);
}

@end


@implementation OOTrMultiplyOperator (Simplification)

- (id) performSimplification
{
	id left = [self leftArgument];
	id right = [self rightArgument];
	id simplifiedLeft = [left simplified];
	id simplifiedRight = [right simplified];
	
	if ([simplifiedLeft isNumericConstant] && [simplifiedRight isNumericConstant])
	{
		return TrNUM([simplifiedLeft doubleValue] * [simplifiedRight doubleValue]);
	}
	
	if (simplifiedLeft == left && simplifiedRight == right)  return self;
	return TrMUL(simplifiedLeft, simplifiedRight);
}

@end


@implementation OOTrDivideOperator (Simplification)

- (id) performSimplification
{
	id left = [self leftArgument];
	id right = [self rightArgument];
	id simplifiedLeft = [left simplified];
	id simplifiedRight = [right simplified];
	
	if ([simplifiedLeft isNumericConstant] && [simplifiedRight isNumericConstant])
	{
		return TrNUM([simplifiedLeft doubleValue] / [simplifiedRight doubleValue]);
	}
	
	if (simplifiedLeft == left && simplifiedRight == right)  return self;
	return TrDIV(simplifiedLeft, simplifiedRight);
}

@end


@implementation OOTrLogicalAndOperator (Simplification)

- (id) performSimplification
{
	id left = [self leftArgument];
	id right = [self rightArgument];
	id simplifiedLeft = [left simplified];
	id simplifiedRight = [right simplified];
	
	BOOL leftSideEffectFree = [simplifiedLeft isSideEffectFree];
	BOOL rightSideEffectFree = [simplifiedRight isSideEffectFree];
	
	if (leftSideEffectFree && [simplifiedLeft hasKnownBooleanValue])  simplifiedLeft = [simplifiedLeft booleanLiteralValue];
	if (rightSideEffectFree && [simplifiedRight hasKnownBooleanValue])  simplifiedRight = [simplifiedRight booleanLiteralValue];
	
	// Optimize away in cases where side effects aren't a problem.
	if (simplifiedLeft == TrNO)  return TrNO;	// Always safe because of short circuiting.
	if (leftSideEffectFree && simplifiedRight == TrNO)  return TrNO;
	if (simplifiedRight == TrYES)  return simplifiedLeft;
	if (rightSideEffectFree && simplifiedLeft == TrYES)  return simplifiedRight;
	
	if (simplifiedLeft == left && simplifiedRight == right)  return self;
	return TrAND(simplifiedLeft, simplifiedRight);
}

@end


@implementation OOTrLogicalOrOperator (Simplification)

- (id) performSimplification
{
	id left = [self leftArgument];
	id right = [self rightArgument];
	id simplifiedLeft = [left simplified];
	id simplifiedRight = [right simplified];
	
	BOOL leftSideEffectFree = [simplifiedLeft isSideEffectFree];
	BOOL rightSideEffectFree = [simplifiedRight isSideEffectFree];
	
	if (leftSideEffectFree && [simplifiedLeft hasKnownBooleanValue])  simplifiedLeft = [simplifiedLeft booleanLiteralValue];
	if (rightSideEffectFree && [simplifiedRight hasKnownBooleanValue])  simplifiedRight = [simplifiedRight booleanLiteralValue];
	
	// Optimize away in cases where side effects aren't a problem.
	if (simplifiedLeft == TrYES)  return TrYES;	// Always safe because of short circuiting.
	if (leftSideEffectFree && simplifiedRight == TrYES)  return TrYES;
	if (simplifiedRight == TrNO)  return simplifiedLeft;
	if (rightSideEffectFree && simplifiedLeft == TrNO)  return simplifiedRight;
	
	if (simplifiedLeft == left && simplifiedRight == right)  return self;
	return TrOR(simplifiedLeft, simplifiedRight);
}

@end


@implementation OOTrPropertyAccessOperator (Simplification)

- (id) performSimplification
{
	id left = [self leftArgument];
	id right = [self rightArgument];
	id simplifiedLeft = [left simplified];
	id simplifiedRight = [right simplified];
	
	if ([simplifiedRight isKindOfClass:[OOTrStringLiteral class]])
	{
		NSString *string = [(OOTrStringLiteral *)simplifiedRight stringValue];
		if ([string oo_isSimpleJSIdentifier])
		{
			simplifiedRight = TrID(string);
		}
	}
	
	if (simplifiedLeft == left && simplifiedRight == right)  return self;
	return TrPROP(simplifiedLeft, simplifiedRight);
}

@end


@implementation OOTrLogicalNotOperator (Simplification)

- (id) priv_argWithDoubleNegativeStripped:(id)arg
{
	if ([arg isKindOfClass:[OOTrLogicalNotOperator class]])
	{
		id argArg = [arg argument];
		if ([argArg hasBooleanType])  return argArg;
	}
	
	return self;
}


- (id) performSimplification
{
	id arg = [self argument];
	
	// Check for !! before arg has opportunity to simplify itself away.
	id noDoubleNegatives = [self priv_argWithDoubleNegativeStripped:arg];
	if (noDoubleNegatives != nil)  return noDoubleNegatives;
	
	id simplifiedArg = [arg simplified];
	if ([simplifiedArg hasSimpleLogicalInversion])
	{
		return [simplifiedArg logicalInverse];
	}
	
	/*	Check for double negative again just in case simplification produced
		an opportunity, although the logical inversion stuff should have
		caught it.
	*/
	noDoubleNegatives = [self priv_argWithDoubleNegativeStripped:arg];
	if (noDoubleNegatives != nil)  return noDoubleNegatives;
	
	if (simplifiedArg == arg)  return self;
	return [simplifiedArg logicalInverse];
}


- (BOOL) hasSimpleLogicalInversion
{
	return [[self argument] hasBooleanType];
}


- (OOTrExpression *) logicalInverse
{
	id arg = [self argument];
	if ([arg hasBooleanType])  return arg;
	return TrNOT(self);
}

@end


@implementation OOTrLessThanComparisonOperator (Simplification)

- (BOOL) hasSimpleLogicalInversion
{
	return YES;
}


- (OOTrExpression *) logicalInverse
{
	return TrLESSEQL([self rightArgument], [self leftArgument]);
}

@end


@implementation OOTrGreaterThanComparisonOperator (Simplification)

- (BOOL) hasSimpleLogicalInversion
{
	return YES;
}


- (OOTrExpression *) logicalInverse
{
	return TrLESSEQL([self leftArgument], [self rightArgument]);
}

@end


@implementation OOTrLessThanOrEqualComparisonOperator (Simplification)

- (BOOL) hasSimpleLogicalInversion
{
	return YES;
}


- (OOTrExpression *) logicalInverse
{
	return TrLESS([self rightArgument], [self leftArgument]);
}

@end


@implementation OOTrGreaterThanOrEqualComparisonOperator (Simplification)

- (BOOL) hasSimpleLogicalInversion
{
	return YES;
}


- (OOTrExpression *) logicalInverse
{
	return TrLESS([self leftArgument], [self rightArgument]);
}

@end


@implementation OOTrEqualComparisonOperator (Simplification)

- (BOOL) hasSimpleLogicalInversion
{
	return YES;
}


- (OOTrExpression *) logicalInverse
{
	return TrNEQUAL([self leftArgument], [self rightArgument]);
}

@end


@implementation OOTrNotEqualComparisonOperator (Simplification)

- (BOOL) hasSimpleLogicalInversion
{
	return YES;
}


- (OOTrExpression *) logicalInverse
{
	return TrEQUAL([self leftArgument], [self rightArgument]);
}

@end


@implementation OOTrStrictlyEqualComparisonOperator (Simplification)

- (BOOL) hasSimpleLogicalInversion
{
	return YES;
}


- (OOTrExpression *) logicalInverse
{
	return TrNSEQUAL([self leftArgument], [self rightArgument]);
}

@end


@implementation OOTrNotStrictlyEqualComparisonOperator (Simplification)

- (BOOL) hasSimpleLogicalInversion
{
	return YES;
}


- (OOTrExpression *) logicalInverse
{
	return TrSEQUAL([self leftArgument], [self rightArgument]);
}

@end


@implementation OOTrAssignOperator (Simplification)

- (BOOL) hasNumericTypeDefault
{
	return [[self rightArgument] hasNumericType];
}


- (BOOL) hasBooleanTypeDefault
{
	return [[self rightArgument] hasBooleanType];
}


- (id) performSimplification
{
	id left = [self leftArgument];
	id right = [self rightArgument];
	id simplifiedLeft = [left simplified];
	id simplifiedRight = [right simplified];
	
	BOOL leftSideEffectFree = [simplifiedLeft isSideEffectFree];
	
	// Convert x = x • y to x •= y where appropriate.
	if (leftSideEffectFree && [simplifiedRight isKindOfClass:[OOTrBinaryOperator class]] && [simplifiedRight hasAssignmentForm])
	{
		id rightLeft = [[simplifiedRight leftArgument] simplified];
		if ([rightLeft isEqual:simplifiedLeft])
		{
			id rightRight = [simplifiedRight rightArgument];
			Class newClass = [simplifiedRight assigmentForm];
			
			return [[newClass operatorWithLeftArgument:simplifiedLeft rightArgument:rightRight] simplified];
		}
	}
	
	if (simplifiedLeft == left && simplifiedRight == right)  return self;
	return TrASSIGN(simplifiedLeft, simplifiedRight);
}

@end


@implementation OOTrAddAssignOperator (Simplification)

- (BOOL) hasNumericTypeDefault
{
	// If args are not known to be numeric, they might be strings. If either is a string, + is concatenation.
	return [[self leftArgument] hasNumericType] && [[self rightArgument] hasNumericType];
}

@end


@implementation OOTrConditionalOperator (Simplification)

- (id) performSimplification
{
	id simplifiedCondition = [_condition simplified];
	id simplifiedTrue = [_trueValue simplified];
	id simplifiedFalse = [_falseValue simplified];
	
	if ([simplifiedTrue isSideEffectFree] && [simplifiedTrue hasBooleanType])  simplifiedTrue = [simplifiedTrue booleanLiteralValue];
	if ([simplifiedFalse isSideEffectFree] && [simplifiedFalse hasBooleanType])  simplifiedFalse = [simplifiedFalse booleanLiteralValue];
	
	if ([simplifiedCondition isKindOfClass:[OOTrLogicalNotOperator class]])
	{
		simplifiedCondition = [simplifiedCondition argument];
		id temp = simplifiedTrue;
		simplifiedTrue = simplifiedFalse;
		simplifiedFalse = temp;
	}
	
	if ([simplifiedCondition isSideEffectFree])
	{
		/*	If condition is side-effect free and known, we can eliminate it
			entirely.
		*/
		if ([simplifiedCondition hasKnownBooleanValue])
		{
			return [simplifiedCondition boolValue] ? simplifiedTrue : simplifiedFalse;
		}
		
		/*	If the condition is side-effect free and the options are the same,
			we can also eliminate the condition.
		*/
		if ([simplifiedTrue isEqual:simplifiedFalse])  return simplifiedTrue;
	}
	else
	{
		/*	If the condition is not known to be side-effect free but the
			options are the same, use a (condition, value) sequence.
		*/
		if ([simplifiedTrue isEqual:simplifiedFalse])
		{
			return TrBOP(Comma, simplifiedCondition, simplifiedTrue);
		}
	}
	
	/*	If both values are booleans (but distinct, because we've handled the
		identical case already), replace with just the condition (converted to
		boolean or negated as necessary).
	*/
	if (simplifiedTrue == TrYES && simplifiedFalse == TrNO)
	{
		if ([simplifiedCondition hasBooleanType])  return simplifiedCondition;
		else  return [[TrNOT(simplifiedCondition) logicalInverse] simplified];
	}
	
	if (simplifiedTrue == TrNO && simplifiedFalse == TrYES)
	{
		return [TrNOT(simplifiedCondition) simplified];
	}
	
	if (simplifiedCondition == _condition && simplifiedTrue == _trueValue && simplifiedFalse == _falseValue)
	{
		return self;
	}
	return TrCOND(simplifiedCondition, simplifiedTrue, simplifiedFalse);
}


- (BOOL) hasSimpleLogicalInversion
{
	return YES;
}


- (OOTrExpression *) logicalInverse
{
	return TrCOND(_condition, _falseValue, _trueValue);
}

@end


@implementation OOTrConditionalStatement (Simplification)

- (id) performSimplification
{
	id simplifiedCondition = [_condition simplified];
	id simplifiedTrue = [_trueStatement simplified];
	id simplifiedFalse = [_falseStatement simplified];
	
	// If condition is known, eliminate unused branch.
	if ([simplifiedCondition hasKnownBooleanValue])
	{
		id takenBranch = [simplifiedCondition boolValue] ? simplifiedTrue : simplifiedFalse;
		if ([simplifiedCondition isSideEffectFree])  return takenBranch;
		if ([takenBranch isSideEffectFree])  return TrVOID(simplifiedCondition);
		return [OOTrCompoundStatement compoundStatementWithStatements:$array(simplifiedCondition, takenBranch)];
	}
	
	// If true branch is effectless, simplify it away.
	if (simplifiedTrue == nil || [simplifiedTrue isSideEffectFree])
	{
		if (simplifiedFalse == nil || [simplifiedFalse isSideEffectFree])
		{
			/*	Both branches simplified away. If condition is side-effect
				free, return null statement. Otherwise, return void statment
				with condition.
			*/
			if ([simplifiedCondition isSideEffectFree])
			{
				return TrNULLSTMT;
			}
			else
			{
				return TrVOID(simplifiedCondition);
			}
		}
		
		// Only true branch simplified away.
		simplifiedTrue = simplifiedFalse;
		simplifiedFalse = nil;
		simplifiedCondition = [simplifiedCondition logicalInverse];
	}
	
	if (simplifiedCondition == _condition &&
		[_trueStatement isEqualToOrWraps:simplifiedTrue] &&
		(_falseStatement == nil || [_falseStatement isEqualToOrWraps:simplifiedFalse]))
	{
		return self;
	}
	
	return TrIF(simplifiedCondition, simplifiedTrue, simplifiedFalse);
}

@end


@implementation OOTrReturnStatement (Simplification)

- (id) performSimplification
{
	id simplifiedExpression = [_expression simplified];
	
	if (simplifiedExpression == _expression)  return self;
	return TrRETURN(simplifiedExpression);
}

@end


@implementation OOTrVarStatement (Simplification)

- (id) performSimplification
{
	id simplifiedInitializer = [_initializer simplified];
	
	if (simplifiedInitializer == _initializer)  return self;
	return TrRETURN(simplifiedInitializer);
}

@end
