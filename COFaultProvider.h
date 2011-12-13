#import <Foundation/Foundation.h>
#import "COItem.h"
#import "ETUUID.h"

@protocol COFaultObserver <NSObject>

/**
 * The fault provider will call this when its state changes
 */
- (void) refetchUUIDs: (NSSet*)aSet;

@end

/**
 * Protocol to bridge an editing context and an item tree cache
 */
@protocol COFaultProvider <NSObject>

/**
 * Interface for the fault observer to get rows from the fault provider
 */
- (COItem*) itemForUUID: (ETUUID *)aUUID;

- (void) addFaultObserver: (id<COFaultObserver>)anObserver;
- (void) removeFaultObserver: (id<COFaultObserver>)anObserver;

@end
