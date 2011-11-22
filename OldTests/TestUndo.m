/**
 
 Relationships: the choice of which side we store affects undo:
 
 e.g. if we implement composition relationships by storing the parent
 pointer in child objects, adding objects to containers/removing them
 is logged in the child objets' undo logs.
 
 this sounds undesirable at first glance - motivates storing composition
 relationships in the parent as a list of children.

*/