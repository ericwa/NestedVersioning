#import <Foundation/Foundation.h>

@interface COSQLiteStore (Attachments)

- (NSURL *) URLForAttachment: (NSData *)aHash;
- (NSData *) addAttachmentAtURL: (NSURL *)aURL;

@end
