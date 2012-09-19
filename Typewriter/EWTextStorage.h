#import <Cocoa/Cocoa.h>
#import "COUUID.h"

@interface EWTextStorage : NSTextStorage
{
    NSMutableAttributedString *backing_;
    
    NSMutableSet *paragraphsChangedDuringEditing_;
}

- (NSArray *) paragraphUUIDs;

- (NSRange) rangeForParagraphWithUUID: (COUUID *)aUUID;

- (NSAttributedString *) attributedStringForParagraphWithUUID: (COUUID *)aUUID;

- (NSArray *) paragraphUUIDsChangedDuringEditing;

@end
