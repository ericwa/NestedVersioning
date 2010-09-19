#import "COObjectContext.h"

@implementation COObjectContext


- (id) initWithHistoryGraphNode: (COHistoryGraphNode*)node
{
  self = [self initWithStoreCoordinator: [node storeCoordinator]];
  ASSIGN(_baseHistoryGraphNode, node);
  return self;
}

- (id) initWithStoreCoordinator: (COStoreCoordinator*)store
{
  SUPERINIT;
  ASSIGN(_storeCoordinator, store);
  _changedObjectUUIDs = [[NSMutableSet alloc] init];
  _instantiatedObjects = [[NSMutableDictionary alloc] init];
  return self;
}

- (void) dealloc
{
  DESTROY(_baseHistoryGraphNode);
  DESTROY(_storeCoordinator);
  DESTROY(_changedObjectUUIDs);
  DESTROY(_instantiatedObjects);
  [super dealloc];
}

- (id) init
{
  return [self initWithHistoryGraphNode: nil];
}

- (void) commit
{
  COHistoryGraphNode *newNode = [[self storeCoordinator]
                    commitChangesInObjectContext: self
                                       afterNode: [self baseHistoryGraphNode]];
  [self setBaseHistoryGraphNode: newNode];
  [_changedObjectUUIDs removeAllObjects];
}

- (COStoreCoordinator *) storeCoordinator
{
  return _storeCoordinator;
}

- (COHistoryGraphNode *) baseHistoryGraphNode
{
  return _baseHistoryGraphNode;
}

- (void) setBaseHistoryGraphNode: (COHistoryGraphNode*)node
{
  ASSIGN(_baseHistoryGraphNode, node);
}

- (BOOL) hasChanges
{
  return ![_changedObjectUUIDs isEmpty];
}

- (COObjectGraphDiff *) changes
{
  COObjectContext *temp = [[COObjectContext alloc] initWithHistoryGraphNode: [self baseHistoryGraphNode]];
  COObjectGraphDiff *diff = [COObjectGraphDiff diffObjectContext: self with: temp];
  [temp release];
  return diff;
}

- (BOOL) objectHasChanges: (ETUUID*)uuid
{
  return [_changedObjectUUIDs containsObject: uuid];
}

- (COObject*) objectForUUID: (ETUUID*)uuid
{
  COObject *result = [_instantiatedObjects objectForKey: uuid];
  
  if (result == nil)
  {
    result = [[[COObject alloc] initFaultedObjectWithContext: self uuid: uuid] autorelease];
    
    // Save the COObject instance in our map
    [_instantiatedObjects setObject: result forKey: uuid];
  }
  
  return result;
}

@end


@implementation COObjectContext (Private)

- (void) markObjectUUIDChanged: (ETUUID*)uuid
{
  [_changedObjectUUIDs addObject: uuid];
}
- (void) markObjectUUIDUnhanged: (ETUUID*)uuid
{
  [_changedObjectUUIDs removeObject: uuid];
}
- (NSArray *) changedObjects
{
  NSMutableArray *result = [NSMutableArray arrayWithCapacity: [_changedObjectUUIDs count]];
  for (ETUUID *uuid in _changedObjectUUIDs)
  {
    [result addObject: [self objectForUUID: uuid]];
  }
  return result;
}
- (void) recordObject: (COObject*)object forUUID: (ETUUID*)uuid
{
  [_instantiatedObjects setObject: object forKey: uuid];
}
@end


@implementation COObjectContext (Rollback)


- (void) revert
{
  [self revertObjects: [self changedObjects]];
}

- (void) rollbackToRevision: (COHistoryGraphNode *)node
{
  //FIXME: ??
  [self revert];
  ASSIGN(_baseHistoryGraphNode, node);
}

- (void)selectiveUndoChangesMadeInRevision: (COHistoryGraphNode *)ver
{
  COHistoryGraphNode *priorToVer = [[ver parents] objectAtIndex: 0]; // FIXME:..
  
  COObjectContext *o = [[COObjectContext alloc] initWithHistoryGraphNode: ver];
  COObjectContext *a = [[COObjectContext alloc] initWithHistoryGraphNode: priorToVer];
  
  COObjectGraphDiff *oa = [COObjectGraphDiff diffObjectContext:o with: a];
  COObjectGraphDiff *ob = [COObjectGraphDiff diffObjectContext:o with: self];
  COObjectGraphDiff *merged = [COObjectGraphDiff mergeDiff: oa withDiff: ob];
  
  [merged applyToContext: self];
}

- (void) revertObjects: (NSArray*)objects
{
  for (COObject *object in objects)
  {
    [object revert];
  }
}

- (void) commitObjects: (NSArray*)objects
{
  // FIXME: commit owned children of objects
  COHistoryGraphNode *newNode = [[self storeCoordinator] commitChangesInObjects: objects
                                                           afterNode: [self baseHistoryGraphNode]];
  [self setBaseHistoryGraphNode: newNode];
}
- (void) rollbackObjects: (NSArray*)objects toRevision: (COHistoryGraphNode *)ver
{
}
- (void) threeWayMergeObjects: (NSArray*)objects withObjects: (NSArray*)otherObjects bases: (NSArray*)bases
{
}
- (void) twoWayMergeObjects: (NSArray*)objects withObjects: (NSArray*)otherObjects
{
}
- (void) selectiveUndoChangesInObjects: (NSArray*)objects madeInRevision: (COHistoryGraphNode *)ver
{
}



@end