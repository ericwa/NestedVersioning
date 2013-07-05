#import <Foundation/Foundation.h>

/**
 * Each key/value pair of a COItem has a COType associated with it.
 *
 * The type defines the set of permissible values which can be set for
 * that attribute, and possibly additional semantics of the value
 * which aren't captured by the Objective-C object alone - for example,
 * one value in a COItem might be an NSArray instance, but the corresponding
 * COType might additionally indicate that the array contains embedded item
 * UUIDs, and the array has a restriction that its elements must be unique.
 *
 * COType is designed with a few things in mind:
 *  - being able to store the values of a COItem in an SQL database,
 *    so the primitive types map cleanly to SQL types.
 *  - validation of ObjC objects against the schema
 *  - plist import/export of ObjC objects of a known COType
 */
typedef int32_t COType;

/**
 
 
 
 */
enum {
    /**
     * Represented as NSNumber
     */
    kCOInt64Type = 1,
    kCODoubleType = 2,
    /**
     * Represented as NSString
     */
    kCOStringType = 3,
    /**
     * Represented as NSData
     */
    kCOBlobType = 4,

    // Internal references (within a persistent root). These could be lumped together
    // and distinguished at the metamodel level only, but they are kept separate
    // to enhance support for loading data with no metamodel available.
    
    /**
     * A composite reference from a parent to a child. The reference is stored
     * in the parent.
     */
    kCOCompositeReferenceType = 7,
    /**
     * A reference that does not necessairily model parent-child relationships -
     * could be graphs with cycles, etc.     
     */
    kCOReferenceType = 9,
    
    // Only exists in the metamodel: kCOCopyReference. This is a reference that
    // lacks the parent/child constraint of kCOEmbeddedItemType, but the copier
    // always copies (so it acts like kCOEmbeddedItemType for the copier.)
    
    // References across persistent roots. This is an explicit type so that when indexing the contents
    // of a commit, 
    kCOPathType = 6,
    
    kCOAttachmentType = 8,
    
    
    kCOSetType = 16,
    kCOArrayType = 32,
    
    kCOPrimitiveTypeMask = 0x0f,
    kCOMultivaluedTypeMask = 0xf0
};

static inline
BOOL COTypeIsMultivalued(COType type)
{
    return (type & kCOMultivaluedTypeMask) != 0;
}

static inline
BOOL COTypeIsPrimitive(COType type)
{
    return (type & kCOMultivaluedTypeMask) == 0;
}

static inline
BOOL COTypeIsOrdered(COType type)
{
    return (type & kCOMultivaluedTypeMask) == kCOArrayType;
}

static inline
COType COPrimitiveType(COType type)
{
    return type & kCOPrimitiveTypeMask;
}
