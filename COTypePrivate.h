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
@interface COPathType : COPrimitiveType
@end
@interface COAttachmentType : COPrimitiveType
@end
@interface COUUIDType : COPrimitiveType
@end
@interface COCommitType : COUUIDType
@end
@interface COEmbeddedItemType : COUUIDType
@end
@interface COReferenceType : COUUIDType
@end
@interface CONamedType : COType
{
    NSString *name_;
    COType *storageType_;
}
@property (readwrite, nonatomic, retain) NSString *name;
@property (readwrite, nonatomic, retain) COType *storageType;
@end

@interface COMultivaluedType : COType
{
	COPrimitiveType *primitiveType;
	BOOL ordered;
}
- (id) initWithPrimitiveType: (COType*)aType
				   isOrdered: (BOOL)isOrdered;
@end