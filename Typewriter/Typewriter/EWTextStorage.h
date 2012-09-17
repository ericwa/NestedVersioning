#import <Cocoa/Cocoa.h>
#import "COUUID.h"

@interface EWTextStorage : NSTextStorage
{
    NSMutableAttributedString *backing_;
}

- (NSArray *) paragraphUUIDs;

- (NSRange) rangeForParagraphWithUUID: (COUUID *)aUUID;

- (NSAttributedString *) attributedStringForParagraphWithUUID: (COUUID *)aUUID;

@end
