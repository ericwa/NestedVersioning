#import <Cocoa/Cocoa.h>
#import <EtoileFoundation/ETUUID.h>
#import <NestedVersioning/COSubtree.h>

@interface EWTextStorage : NSTextStorage
{
    NSMutableAttributedString *backing_;
    
    NSMutableSet *paragraphsChangedDuringEditing_;
}

- (BOOL) setTypewriterDocument: (COSubtree *)aTree;
- (COSubtree *) typewriterDocument;
- (COSubtree *) paragraphTreeForUUID: (ETUUID *)aUUID;

// FIXME: we will need the ability to incrementally update an EWTextStorage
// by writing a new root node and supplying the relevant added/modified paragraph
// nodes.


- (NSArray *) paragraphUUIDs;

- (NSRange) rangeForParagraphWithUUID: (ETUUID *)aUUID;

- (NSAttributedString *) attributedStringForParagraphWithUUID: (ETUUID *)aUUID;

- (NSArray *) paragraphUUIDsChangedDuringEditing;

@end
