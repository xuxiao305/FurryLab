x = #()

for i = 1 to $.verts.count do
(
	local edges = polyop.getEdgesUsingVert $ i
	edges = edges as array

	if edges.count == 2 do 
	(
		append x i
	)
)

polyop.setVertSelection $ x