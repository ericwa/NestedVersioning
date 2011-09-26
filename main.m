#import <Foundation/Foundation.h>
#import "Common.h"

int main (int argc, const char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    EmbeddedObject *embtest = [EmbeddedObject objectWithContents: [NSArray array] metadata: [NSDictionary dictionary]];
    
    //fixme:  separate into a coreobject constructor, and a repo constructor that takes a co.
    Repository *repo = [Repository repositoryWithEmbeddedObject:embtest
                                       firstHistoryNodeMetadata:[NSDictionary dictionary]];
    
    //NSLog(@"repo %@", repo);
    
    
    // simplest test:
    // edit embtest's metadata
    
    EmbeddedObject *edit1 = [embtest copy];
    edit1.metadata = [NSDictionary dictionaryWithObjectsAndKeys: @"Hello world", @"name",
                      nil];
    
    VersionedObject *rootVersionedObject = [repo rootObject];
    
        NSLog(@"Versioned Object before commit:\n%@", rootVersionedObject);
    
    [rootVersionedObject checkSanityWithOwner: nil];
    
    VersionedObject *rootWithCommit = [rootVersionedObject versionedObjectWithNewVersionOfEmbeddedObject:edit1
                                                    withCommitMetadata: [NSDictionary dictionaryWithObjectsAndKeys: @"first commit", @"message",
                                                            nil]];
    
    NSLog(@"Versioned Object after commit:\n%@", rootWithCommit);

    [rootWithCommit checkSanityWithOwner: nil];
    
    [pool drain];
    return 0;
}

