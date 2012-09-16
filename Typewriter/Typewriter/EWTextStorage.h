#import <Cocoa/Cocoa.h>

@interface EWTextStorage : NSTextStorage
{
    NSMutableAttributedString *backing_;
    NSMutableIndexSet *paragraphStartIndices_;
    NSMutableArray *paragraphUUIDs_;
}

- (NSArray *) paragraphUUIDs;

- (NSRange) rangeForParagraphWithUUID: (id)aUUID;

- (NSAttributedString *) attributedStringForParagraphWithUUID: (id)aUUID;

@end
