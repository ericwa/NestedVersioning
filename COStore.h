#import <Foundation/Foundation.h>
#import "ETUUID.h"

@interface COStore : NSObject
{
@private
	NSURL *url;
}

// TODO: how to handle disk full error? db in use error?
// TODO: think carefully about transaction atomicity - if a transaction is
// blocked because changes were made to the DB in the ﻿﻿meantime, what
// could need to be changed in the original transaction to finish committing it?


/** @taskunit Initialization */

- (id)initWithURL: (NSURL*)aURL;
- (NSURL*)URL;



@end