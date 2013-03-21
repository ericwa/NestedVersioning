#import <Foundation/Foundation.h>

/**
 * NB Attachments screw with having objects in a COEditingContext not associated with a store.
 * What about collaborative editing?
 *
 * In the "conceptual schema" the type of attachment property should still be a regular blob.
 */
@interface COAttachment : NSObject

+ (COAttachment *) createAttachmentWithPath: (NSString *)aPath
                                    inStore: (COSQLiteStore *)aStore;

@end
