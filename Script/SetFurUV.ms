-- global sampleCount = 20
global MaxCountPerCol = 80000
macros.run "Modifier Stack" "Convert_to_Mesh"

for sel in selection do 
(
	for i = 0 to ((getNumTVerts sel) - 1) do 
	(
		col = (i / MaxCountPerCol) as integer
		indexPerCol = mod i MaxCountPerCol
		
		x = col
		
		y = indexPerCol
		setTVert sel.baseobject.mesh (i+1) (point3 x y 0)	
	)	
)


