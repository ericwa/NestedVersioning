#import "COSQLiteStorePersistentRootBackingStoreBinaryFormats.h"
#import "COUUID.h"

void ParseCombinedCommitDataInToUUIDToItemDataDictionary(NSMutableDictionary *dest, NSData *commitData, BOOL replaceExisting, NSSet *restrictToItemUUIDs)
{
    // format:
    //
    // |------------|-----------------------|----------| |---..
    // |128-bit UUID| uint_32 little-endian | item data| | next UUID...
    // |------------|-----------------------|----------| |---..
    //                 ^- number of bytes in item data
    
    const unsigned char *bytes = [commitData bytes];
    const NSUInteger len = [commitData length];
    NSUInteger offset = 0;
    
    while (offset < len)
    {
        COUUID *uuid = [[COUUID alloc] initWithBytes: bytes + offset];
        offset += 16;
        
        uint32_t length;
        memcpy(&length, bytes + offset, 4);
        length = CFSwapInt32LittleToHost(length);
        offset += 4;
        
        if ((replaceExisting
             || nil == [dest objectForKey: uuid])
            && (nil == restrictToItemUUIDs
                || [restrictToItemUUIDs containsObject: uuid]))
        {

            NSData *data = [commitData subdataWithRange: NSMakeRange(offset, length)];
            [dest setObject: data
                     forKey: uuid];
        }
        [uuid release];
        offset += length;
    }
}

void AddCommitUUIDAndDataToCombinedCommitData(NSMutableData *combinedCommitData, COUUID *uuidToAdd, NSData *dataToAdd)
{
    [combinedCommitData appendBytes: uuidToAdd->uuid length: 16];
    
    const NSUInteger len = [dataToAdd length];
    if (len > UINT32_MAX)
    {
        [NSException raise: NSInvalidArgumentException format: @"Can't write item data larger than 2^32-1 bytes"];
    }
    uint32_t swappedInt = CFSwapInt32HostToLittle((uint32_t)len);
    
    [combinedCommitData appendBytes: &swappedInt
                             length: 4];
    
    [combinedCommitData appendData: dataToAdd];
}
