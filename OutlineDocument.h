//
//  OutlineDocument.h
//  ObjectMerging
//
//  Created by Eric Wasylishen on 9/20/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface OutlineDocument : NSDocument
{
  IBOutlet NSView *outlineView;
}

- (IBAction) addColumn: (id)sender;

@end
