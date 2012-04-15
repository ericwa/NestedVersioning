#import "EWBezierPath.h"
#import "COSubtree.h"

@implementation EWBezierPath

+ (COSubtree *) subtreeFromBezierPath: (NSBezierPath *)path
{
	COSubtree *result = [COSubtree subtree];
	[result setValue: @"bezierPath" forAttribute:@"type" type: [COType stringType]];
	
	NSMutableArray *xArray = [NSMutableArray array];
	NSMutableArray *yArray = [NSMutableArray array];
	NSMutableArray *elementTypeArray = [NSMutableArray array];
	
	{
		NSUInteger count = [path elementCount];
		NSPoint	points[3];
		NSBezierPathElement type;
		for (NSUInteger i = 0; i < count; i++ )
		{
			type = [path elementAtIndex: i associatedPoints: points];
			switch (type)
			{
				case NSCurveToBezierPathElement:
					[elementTypeArray addObject: [NSNumber numberWithInt: 0]];
					[xArray addObject: [NSNumber numberWithDouble: points[0].x]];
					[yArray addObject: [NSNumber numberWithDouble: points[0].y]];
					[xArray addObject: [NSNumber numberWithDouble: points[1].x]];
					[yArray addObject: [NSNumber numberWithDouble: points[1].y]];
					[xArray addObject: [NSNumber numberWithDouble: points[2].x]];
					[yArray addObject: [NSNumber numberWithDouble: points[2].y]];
					break;	
				case NSMoveToBezierPathElement:
					[elementTypeArray addObject: [NSNumber numberWithInt: 1]];
					[xArray addObject: [NSNumber numberWithDouble: points[0].x]];
					[yArray addObject: [NSNumber numberWithDouble: points[0].y]];
					break;
				case NSLineToBezierPathElement:
					[elementTypeArray addObject: [NSNumber numberWithInt: 2]];
					[xArray addObject: [NSNumber numberWithDouble: points[0].x]];
					[yArray addObject: [NSNumber numberWithDouble: points[0].y]];					
					break;
				case NSClosePathBezierPathElement:
					[elementTypeArray addObject: [NSNumber numberWithInt: 3]];
					[xArray addObject: [NSNumber numberWithDouble: points[0].x]];
					[yArray addObject: [NSNumber numberWithDouble: points[0].y]];					
					break;
				default:
					[NSException raise: NSInvalidArgumentException format: @"unknown NSBezierPath element type %d", (int)type];
					break;
			}
		}
	}
	
	[result setValue: xArray forAttribute: @"xArray" type: [COType arrayWithPrimitiveType: [COType doubleType]]];
	[result setValue: yArray forAttribute: @"yArray" type: [COType arrayWithPrimitiveType: [COType doubleType]]];
	[result setValue: elementTypeArray forAttribute: @"elementTypeArray" type: [COType arrayWithPrimitiveType: [COType int64Type]]];
	
	return result;
}

+ (NSBezierPath *) bezierPathFromSubtree: (COSubtree *)subtree
{
	NSBezierPath *result = [NSBezierPath bezierPath];
	
	// type-check
	
	if (![[subtree valueForAttribute: @"type"] isEqual: @"bezierPath"])
	{
		[NSException raise: NSInvalidArgumentException format: @"wrong type"];
	}		
	if (![[subtree typeForAttribute: @"xArray"] isEqual: [COType arrayWithPrimitiveType: [COType doubleType]]])
	{
		[NSException raise: NSInvalidArgumentException format: @"wrong type"];		
	}
	if (![[subtree typeForAttribute: @"yArray"] isEqual: [COType arrayWithPrimitiveType: [COType doubleType]]])
	{
		[NSException raise: NSInvalidArgumentException format: @"wrong type"];	
	}
	if (![[subtree typeForAttribute: @"elementTypeArray"] isEqual: [COType arrayWithPrimitiveType: [COType int64Type]]])
	{
		[NSException raise: NSInvalidArgumentException format: @"wrong type"];
	}
	
	
	NSArray *xArray = [subtree valueForAttribute: @"xArray"];
	NSArray *yArray = [subtree valueForAttribute: @"yArray"];
	NSArray *elementTypeArray = [subtree valueForAttribute: @"elementTypeArray"];
	
	{
		NSUInteger pointArraysIndex = 0;
		NSUInteger count = [elementTypeArray count];
		NSPoint	p0, p1, p2;
		int type;
		for (NSUInteger i = 0; i < count; i++ )
		{		
			type =  [[elementTypeArray objectAtIndex: i] intValue];
			switch (type)
			{
				case 0:
					p0 = NSMakePoint([[xArray objectAtIndex: pointArraysIndex] doubleValue],
									 [[yArray objectAtIndex: pointArraysIndex] doubleValue]);
					p1 = NSMakePoint([[xArray objectAtIndex: pointArraysIndex + 1] doubleValue],
									 [[yArray objectAtIndex: pointArraysIndex + 1] doubleValue]);
					p2 = NSMakePoint([[xArray objectAtIndex: pointArraysIndex + 2] doubleValue],
									 [[yArray objectAtIndex: pointArraysIndex + 2] doubleValue]);
					[result curveToPoint: p2 controlPoint1: p0 controlPoint2: p1];
					pointArraysIndex += 3;
					break;	
				case 1:
					p0 = NSMakePoint([[xArray objectAtIndex: pointArraysIndex] doubleValue],
									 [[yArray objectAtIndex: pointArraysIndex] doubleValue]);
					[result moveToPoint: p0];
					pointArraysIndex++;
					break;
				case 2:
					p0 = NSMakePoint([[xArray objectAtIndex: pointArraysIndex] doubleValue],
									 [[yArray objectAtIndex: pointArraysIndex] doubleValue]);
					[result lineToPoint: p0];
					pointArraysIndex++;
					break;
				case 3:
					[result closePath];
					pointArraysIndex++;
					break;
				default:
					[NSException raise: NSInvalidArgumentException format: @"unknown element type %d", type];
					break;
			}
		}
	}
	
	return result;
}

@end
