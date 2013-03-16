#import <Foundation/Foundation.h>

@class COUUID;

/**
 * Given an NSData produced by AddCommitUUIDAndDataToCombinedCommitData,
 * extracts the UUID : NSData pairs within it and adds them to dest
 */
void ParseCombinedCommitDataInToUUIDToItemDataDictionary(NSMutableDictionary *dest, NSData *commitData, BOOL replaceExisting);

/**
 * Adds a COUUID : NSData pair to combinedCommitData
 */
void AddCommitUUIDAndDataToCombinedCommitData(NSMutableData *combinedCommitData, COUUID *uuidToAdd, NSData *dataToAdd);