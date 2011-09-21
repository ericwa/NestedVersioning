#import <Foundation/Foundation.h>
#import "Common.h"

int main (int argc, const char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    EmbeddedObject *embtest = [EmbeddedObject objectWithContents: [NSArray array] metadata: [NSDictionary dictionary]];
    
    //fixme:  separate into a coreobject constructor, and a repo constructor that takes a co.
    Repository *repo = [Repository repositoryWithEmbeddedObject:embtest
                                       firstHistoryNodeMetadata:[NSDictionary dictionary]];
    
    NSLog(@"repo %@", repo);
    
    
    // simplest test:
    // edit embtest's metadata
    
    EmbeddedObject *edit1 = [embtest copy];
    edit1.metadata = [NSDictionary dictionaryWithObjectsAndKeys: @"Hello world", @"name",
                      nil];
    
    
    //...
    
    [pool drain];
    return 0;
}

