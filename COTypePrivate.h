#import "COType.h"

@interface COPrimitiveType : COType
@end
@interface COInt64Type : COPrimitiveType
@end
@interface CODoubleType : COPrimitiveType
@end
@interface COStringType : COPrimitiveType
@end
@interface COFullTextIndexableStringType : COPrimitiveType
@end
@interface COBlobType : COPrimitiveType
@end
@interface COCommitType : COPrimitiveType
@end
@interface COPathType : COPrimitiveType
@end
@interface COEmbeddedItemType : COPrimitiveType
@end
@interface COAttachmentType : COPrimitiveType
@end

@interface COMultivaluedType : COType
{
	COPrimitiveType *primitiveType;
	BOOL ordered;
	BOOL unique;
}
- (id) initWithPrimitiveType: (COType*)aType
				   isOrdered: (BOOL)isOrdered
					isUnique: (BOOL)isUnique;
@end