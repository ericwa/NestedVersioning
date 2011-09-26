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


static void test2LevelNestingOfVersionedObjects()
{
    // proj1 (VersionedObject)
	//  |
	//  \--proj1Contents (EmbeddedObject)
	//      |
	//      \-doc1 (VersionedObject)
	//          |
	//          \-doc1Contents (EmbeddedObject

    // set up the tree:
    
    EmbeddedObject *doc1Contents = [EmbeddedObject objectWithContents: [NSArray array]
                                                        metadata: [NSDictionary dictionary]];
    
    VersionedObject *doc1 = [VersionedObject versionedObjectWrappingEmbeddedObject: doc1Contents];
    
    EmbeddedObject *proj1Contents = [EmbeddedObject objectWithContents: [NSArray arrayWithObject: doc1]
                                                              metadata: [NSDictionary dictionary]];
    
    VersionedObject *proj1 = [VersionedObject versionedObjectWrappingEmbeddedObject: proj1Contents];
    
    NSLog(@"proj1:\n%@", proj1);
    [proj1 checkSanityWithOwner: nil];
    
    
    // make a modified version of doc1Contents
    
    EmbeddedObject *doc1ContentsModification1 = [[doc1Contents copy] autorelease];
    doc1ContentsModification1.metadata = [NSDictionary dictionaryWithObjectsAndKeys: @"Hello world", @"name",
                                          nil];
        // commit to doc1
    VersionedObject *doc1Mofification1 = [doc1 versionedObjectWithNewVersionOfEmbeddedObject: doc1ContentsModification1
                                                                          withCommitMetadata:
                                       [NSDictionary dictionaryWithObjectsAndKeys: @"first commit", @"message",
                                        nil]];
    
    // make a modified proj1Contents
    
    EmbeddedObject *proj1ContentsMofification1 = [EmbeddedObject objectWithContents: [NSArray arrayWithObject: doc1Mofification1]
                                                              metadata: [NSDictionary dictionary]];
        // commit to proj1
    VersionedObject *proj1Mofification1 = [proj1 versionedObjectWithNewVersionOfEmbeddedObject: proj1ContentsMofification1
                                                                          withCommitMetadata:
                                          [NSDictionary dictionaryWithObjectsAndKeys: @"automatic commit in parent", @"message",
                                           nil]];
    
    [proj1Mofification1 checkSanityWithOwner: nil];
    
    NSLog(@"proj1 after committing a new version of the document:\n%@", proj1Mofification1);
}


int main (int argc, const char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    //testBasic();
    test2LevelNestingOfVersionedObjects();

    EWTestLog();
    
    [pool drain];
    return 0;
}

