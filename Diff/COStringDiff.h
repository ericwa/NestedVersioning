#import <Foundation/Foundation.h>
#import "COSequenceDiff.h"

@interface COStringDiff : COSequenceDiff
{
}

- (id) initWithFirstString: (NSString *)first
              secondString: (NSString *)second;

- (void) applyTo: (NSMutableString*)string;
- (NSString *)stringWithDiffAppliedTo: (NSString*)string;
// - (void) applyToAttributedString: (NSMutableAttributedString*)string;
// - (NSAttributedString *)attributedStringWithDiffAppliedTo: (NSString*)string;

@end

