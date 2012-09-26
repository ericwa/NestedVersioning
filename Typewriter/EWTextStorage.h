#import <Cocoa/Cocoa.h>
#import "COUUID.h"
#import <NestedVersioning/COSubtree.h>

@interface EWTextStorage : NSTextStorage
{
    NSMutableAttributedString *backing_;
    
    NSMutableSet *paragraphsChangedDuringEditing_;
}

- (BOOL) setTypewriterDocument: (COSubtree *)aTree;
- (COSubtree *) typewriterDocument;
- (COSubtree *) paragraphTreeForUUID: (COUUID *)aUUID;

// FIXME: we will need the ability to incrementally update an EWTextStorage
// by writing a new root node and supplying the relevant added/modified paragraph
// nodes.


- (NSArray *) paragraphUUIDs;

- (NSRange) rangeForParagraphWithUUID: (COUUID *)aUUID;

- (NSAttributedString *) attributedStringForParagraphWithUUID: (COUUID *)aUUID;

- (NSArray *) paragraphUUIDsChangedDuringEditing;

@end
