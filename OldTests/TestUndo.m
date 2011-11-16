/**
 
 Relationships: the choice of which side we store affects undo:
 
 e.g. if we implement composition relationships by storing the parent
 pointer in child objects, adding objects to containers/removing them
 is logged in the child objets' undo logs.
 
 this sounds undesirable at first glance - motivates storing composition
 relationships in the parent as a list of children.
 
 
 ==== 

 just pasting this here:
 
 I’m still not sure how to model a QuArK (3D game level editor) project-like document with various revision control possibilities: revision control graph per map, for the entire project, and undo over all changes. What about undo in the editor vs undo in the project? What about two editor windows open on the same map, and undo for each? What about undo of editor (view) data (scrollbar position, selection, etc, that shouldn’t be stored directly in the model? ) What about branching the project vs branching a map? Linking and embedding cross map and cross project? That about covers all the problems I can think of right now...

 
 
 
 
 
*/