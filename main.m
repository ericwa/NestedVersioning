#import <Foundation/Foundation.h>
#import "Common.h"

static void testBasic()
{
    EmbeddedObject *embtest = [EmbeddedObject objectWithContents: [NSArray array]
                                                        metadata: [NSDictionary dictionary]];
    
    EmbeddedObject *edit1 = [[embtest copy] autorelease];
    edit1.metadata = [NSDictionary dictionaryWithObjectsAndKeys: @"Hello world", @"name",
                      nil];
    
    
    VersionedObject *rootVersionedObject = [VersionedObject versionedObjectWrappingEmbeddedObject: embtest];
    
    NSLog(@"Versioned Object before commit:\n%@", rootVersionedObject);
    
    [rootVersionedObject checkSanityWithOwner: nil];
    
    VersionedObject *rootWithCommit = [rootVersionedObject versionedObjectWithNewVersionOfEmbeddedObject: edit1
                                                                                      withCommitMetadata:
                                            [NSDictionary dictionaryWithObjectsAndKeys: @"first commit", @"message",
                                                                                        nil]];
    
    NSLog(@"Versioned Object after commit:\n%@", rootWithCommit);
    
    [rootWithCommit checkSanityWithOwner: nil];
}

int main (int argc, const char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    testBasic();

    EWTestLog();
    
    [pool drain];
    return 0;
}

