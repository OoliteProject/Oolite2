/*
	SGConditionalTag.h
	
	A tag that evaluates a condition based on current state, and sets state
	based on the result.
	
	The condition is based on three elements, the condition key, comparator
	and operation. The value in the state dictionary referenced by the
	condition key is compared to the comparator based on the condition type.
	For instance, if the condition key is “myValue”, the comparator is an
	NSNumber with the value 3, and the operation is NSOrderedAscending, the
	condition is logically equivalent to (3 < state["myValue"]). Note the
	order of operands.
	
	The result of the condition is then used to set a value in the state. The
	value is specified by the result key, and the values to set are specified
	as the true value and false value. By default, these will be the boolean
	NSNumbers for true and false. Given the condition specified above and the
	result key “myResult”, the operation performed can be thought of as:
	
		if (3 < state["myValue"])
			state["myResult"] = true;
		else
			state["myResult"] = false;
	
	A tag for the above expression can be set up as follows:
	
		tag = [SGConditionalTag tagWithComparator:[NSNumber numberWithInt:3]
									   operation:NSOrderedAscending
								   conditionKey:@"myValue"
									  resultKey:"myResult"];
	
	A practical example would be using an enumerator to select between
	objects/subtrees using the standard "visible" state key. Assume there are
	three objects we might want to render, and we select these by setting a
	state key "selectedObject" to a number between 0 and 2. A SGConditionalTag
	to control the second of these would then be set up as follows:
	
		tag = [SGConditionalTag tagWithComparator:[NSNumber numberWithInt:1]
									   operation:NSOrderedSame
								   conditionKey:@"selectedObject"
									  resultKey:"visible"];
	
	The expression description for this condition (as returned by the
	-expressionDescription method) would be:
	"visible = (1 == selectedObject) ? 1 : 0".
	
	The condition types supported are NSOrderedAscending (as in the example),
	NSOrderedSame and NSOrderedDescending. If the condition type is
	NSOrderedSame, comparision will use -isEqual:. For the other condition
	types, if the comparator responds to the -compare: selector, this will
	be used. Otherwise, the expression’s value will be considered to be false.
	
	A more advanced tag of this nature should probably be built on top of
	NSPredicate.
	
	
	Copyright © 2009 Jens Ayton
	
	Permission is hereby granted, free of charge, to any person obtaining a
	copy of this software and associated documentation files (the “Software”),
	to deal in the Software without restriction, including without limitation
	the rights to use, copy, modify, merge, publish, distribute, sublicense,
	and/or sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
	THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
	DEALINGS IN THE SOFTWARE.
*/

#import "SGSceneTag.h"


@interface SGConditionalTag: SGSceneTag
{
	NSString					*_conditionKey;
	NSComparisonResult			_operation;
	id							_comparator;
	
	NSString					*_resultKey;
	id							_trueValue;
	id							_falseValue;
}

// +tag and +init work too.
+ (id) tagWithComparator:(id)inComparator
			   operation:(NSComparisonResult)inOperation
			conditionKey:(NSString *)inConditionKey
			   resultKey:(NSString *)inResultKey;
- (id) initWithComparator:(id)inComparator
				operation:(NSComparisonResult)inOperation
			 conditionKey:(NSString *)inConditionKey
				resultKey:(NSString *)inResultKey;

// Return YES/NO
- (BOOL) evaluateExpressionWithState:(NSDictionary *)inState;
- (BOOL) evaluateExpressionWithValue:(id)inValue;

// Return trueValue/falseValue
- (id) evaluateWithState:(NSDictionary *)inState;
- (id) evaluateWithValue:(id)inValue;

@property (readonly, nonatomic) NSString *expressionDescription;

@property (nonatomic, copy) NSString *conditionKey;
@property (nonatomic) NSComparisonResult operation;
@property (nonatomic, retain) id comparator;
@property (nonatomic, copy) NSString *resultKey;
@property (nonatomic, retain) id trueValue;
@property (nonatomic, retain) id falseValue;

@end
