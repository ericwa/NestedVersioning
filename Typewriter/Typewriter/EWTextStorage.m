#import "EWTextStorage.h"

@implementation EWTextStorage

- (id) init
{
    self = [super init];
    
    backing_ = [[NSMutableAttributedString alloc] init];
    paragraphStartIndices_ = [[NSMutableIndexSet alloc] init];
    paragraphUUIDs_ = [[NSMutableArray alloc] init];
        
    return self;
}

- (void) dealloc
{
    [paragraphStartIndices_ release];
    [paragraphUUIDs_ release];
    [backing_ release];
    [super dealloc];
}

// Model access

- (NSArray *) paragraphUUIDs
{
    return [NSArray arrayWithArray: paragraphUUIDs_];
}

- (NSRange) rangeForParagraphWithUUID: (id)aUUID
{
    // FIXME: use paragraphStartIndices_ to get the range
    
//    for (id uuid in paragraphUUIDs_) {
//        if ([uuid isEqual: aUUID]) {
//            return 
//        }
//    }
    return NSMakeRange(NSNotFound, 0);
}

- (NSAttributedString *) attributedStringForParagraphWithUUID: (id)aUUID
{
    return [self attributedSubstringFromRange: [self rangeForParagraphWithUUID: aUUID]];
}

// Overrides for primitive methods

/**
 * Should be O(1)
 */
- (NSString *)string
{
    //NSLog(@"EWTextStorage -string");
    return [backing_ string];
}

- (NSDictionary *)attributesAtIndex:(NSUInteger)index effectiveRange:(NSRangePointer)aRange
{
    //NSLog(@"EWTextStorage -attributesAtIndex:effectiveRange:");
    return [backing_ attributesAtIndex: index effectiveRange: aRange];
}

- (void)replaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString
{
    //NSLog(@"EWTextStorage -replaceCharactersInRange:withString:");
    
    [backing_ replaceCharactersInRange: aRange withString: aString];
    
    // Update paragraph metadata
    
    /*
     
     cases:
       [0..n] paragraph deletions
     U [0..n] paragraph additions
     U [0,1,2] paragraph modifications     
     
     */
    
    
    NSString *string = [self string];
    NSUInteger length = [string length];
    NSUInteger paraStart = 0, paraEnd = 0, contentsEnd = 0;
    NSRange currentRange;
    while (paraEnd < length) {
        [string getParagraphStart:&paraStart end:&paraEnd
                       contentsEnd:&contentsEnd forRange:NSMakeRange(paraEnd, 0)];
        currentRange = NSMakeRange(paraStart, contentsEnd - paraStart);
        NSLog(@"paragraph: %@", [string substringWithRange: currentRange]);
    }
    
    [self edited: NSTextStorageEditedCharacters
           range: aRange
  changeInLength: [aString length] - aRange.length];
}

- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)aRange
{
    //NSLog(@"EWTextStorage -setAttributes:range:");
    [backing_ setAttributes: attributes range: aRange];
    [self edited: NSTextStorageEditedAttributes
           range: aRange
  changeInLength: 0];
}

@end
