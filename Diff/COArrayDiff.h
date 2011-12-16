#import <Foundation/Foundation.h>
#import "COSequenceDiff.h"
#import "COType+Diff.h"

@interface COArrayDiff : COSequenceDiff <COValueDiff>
{
	
}

- (id) initWithFirstArray: (NSArray *)first
              secondArray: (NSArray *)second;

- (void) applyTo: (NSMutableArray*)array;
- (NSArray *)arrayWithDiffAppliedTo: (NSArray *)array;

- (id) valueWithDiffAppliedToValue: (id)aValue;

@end





@interface COArrayDiffOperationInsert : COSequenceDiffOperation 
{
	NSArray *insertedObjects;
}

@property (nonatomic, retain, readonly)  NSArray* insertedObjects;

+ (COArrayDiffOperationInsert*)insertWithLocation: (NSUInteger)loc objects: (NSArray*)objs;

@end



@interface COArrayDiffOperationDelete : COSequenceDiffOperation
{
}

+ (COArrayDiffOperationDelete*)deleteWithRange: (NSRange)range;

@end



@interface COArrayDiffOperationModify : COSequenceDiffOperation
{
	NSArray *insertedObjects;  
}

@property (nonatomic, retain, readonly)  NSArray* insertedObjects;

+ (COArrayDiffOperationModify*)modifyWithRange: (NSRange)range newObjects: (NSArray*)objs;

@end