msh = $Cape_FurProxy_Quater_UV
rm = RayMeshGridIntersect () --create an instance of the Reference Target
rm.Initialize 10 --init. the voxel grid size to 10x10x10
rm.addNode msh --add the sphere to the grid
rm.buildGrid () --build the grid data (collecting faces into the grid voxels)
size = 512


select msh
macros.run "Modifier Stack" "Convert_to_Mesh"

fn SolveBarycentricCoord pos trianglePosArr = 
(
	x1 = trianglePosArr[1][1]
	y1 = trianglePosArr[1][2]
	z1 = trianglePosArr[1][3]

	x2 = trianglePosArr[2][1]
	y2 = trianglePosArr[2][2]
	z2 = trianglePosArr[2][3]

	x3 = trianglePosArr[3][1]
	y3 = trianglePosArr[3][2]
	z3 = trianglePosArr[3][3]

	x = pos[1]
	y = pos[2]
	z = pos[3]

	denominator = (y2 - y3) * (x1 - x3) + (x3 - x2) * (y1 - y3)

	lamda1 = ((y2 - y3) * (x - x3) + (x3 - x2) * (y - y3)) / denominator
	lamda2 = ((y3 - y1) * (x - x3) + (x1 - x3) * (y - y3)) / denominator
	lamda3 = 1 - lamda1 - lamda2

	return (point3 lamda1 lamda2 lamda3)
)

AllVertsIDXY = #()
AllBaryCoordsXY = #()
AllUVCoordsXY = #()

startPoint = point3 0 0 0
endPoint = point3 100 100 0
step = ((endPoint.x - startPoint.x) as float) / (size as float)

for i = 1 to size do 
(
	AllVertsIDX = #()
	AllBaryCoordsX = #()
	AllUVCoordsX = #()

	for k = 1 to size do 
	(
		rayPos = point3 (k * step) (i * step) 1 
		rayPos = rayPos + msh.pos
		rayPos = rayPos - (point3 0.5 0.5 0.0)
-- 		point pos:rayPos size:1
		rayDir = point3 0 0 -1
		theHitsCount = rm.intersectRay rayPos rayDir true

		faceVertID = point3 0 0 0 
-- 		uvCoordArr = #(point3 0 0 0, point3 0 0 0, point3 0 0 0)
		uvCoord = rayPos
		baryCoord = point3 0 0 0

		if theHitsCount > 0 then 
		(
			theIndex = rm.getClosestHit()
			f = rm.getHitFace theIndex
-- 			baryCoord = rm.getHitBary theIndex


			faceVertID = (meshop.getVertsUsingFace msh f) as array

			local currentPos = point3 rayPos.x rayPos.y 0.0
			local trianglePosArr = #(msh.verts[faceVertID[1]].pos, msh.verts[faceVertID[2]].pos, msh.verts[faceVertID[3]].pos)
			baryCoord = SolveBarycentricCoord currentPos trianglePosArr
		)
		else
		(
			print "missed"
		)
		append AllVertsIDX (point3 faceVertID[1] faceVertID[2] faceVertID[3])
		append AllBaryCoordsX baryCoord
		append AllUVCoordsX uvCoord
	)            

	append	AllVertsIDXY 		AllVertsIDX
	append	AllBaryCoordsXY 	AllBaryCoordsX
	append	AllUVCoordsXY 		AllUVCoordsX
)

rm.free() 


AllVertsIDMap = bitmap size size color:red gamma:1.0 hdr:true
AllBaryCoordsMap = bitmap size size color:red gamma:1.0 hdr:true
AllUVCoordsMap = bitmap size size color:red gamma:1.0 hdr:true

AllVertsIDMapPath = "D:\\OneDrive\\ToyLabsP4v\\Alice\\Engine\\Alice\\Assets\\Texture\\Girl\\" + msh.name + "_ID.exr"
AllBaryCoordsMapPath = "D:\\OneDrive\\ToyLabsP4v\\Alice\\Engine\\Alice\\Assets\\Texture\\Girl\\" + msh.name + "_Bary.exr"
AllUVCoordsMapPath = "D:\\OneDrive\\ToyLabsP4v\\Alice\\Engine\\Alice\\Assets\\Texture\\Girl\\" + msh.name + "_UV.exr"

VERT_ID_NOMRALIZE_FACTOR = 0.025

AllVertsIDXY_Normalized 	= deepCopy AllVertsIDXY
AllBaryCoordsXY_Normalized 	= deepCopy AllBaryCoordsXY
AllUVCoordsXY_Normalized 	= deepCopy AllUVCoordsXY


for i = 1 to AllVertsIDXY.count do 
(
	for k = 1 to AllVertsIDXY[1].count do 
	(
		AllVertsIDXY_Normalized[i][k] = AllVertsIDXY[i][k] * VERT_ID_NOMRALIZE_FACTOR	
	)
) 

for i = 1 to AllBaryCoordsXY.count do 
(
	for k = 1 to AllBaryCoordsXY[1].count do 
	(
		AllBaryCoordsXY_Normalized[i][k] = AllBaryCoordsXY[i][k] * 255.0	
	)
) 

for i = 1 to AllUVCoordsXY.count do 
(
	for k = 1 to AllUVCoordsXY[1].count do 
	(
		AllUVCoordsXY_Normalized[i][k] = AllUVCoordsXY[i][k]	
	)
) 


fn CreateMap  dataArr pathString = 
(
	size 	= point2 dataArr.count dataArr[1].count 
	mapObj 	= bitmap size.x size.y color:red gamma:1.0 hdr:true
	for i = 1 to size.x do 
	(
		newLineCoord = point2 0 (size.y - i)
		linePixels = dataArr[i]
		format "new line % \n" linePixels 
		setPixels mapObj newLineCoord linePixels
	)
	mapObj.filename = pathString

	save mapObj

	close mapObj
) 

clearListener()  
CreateMap AllVertsIDXY_Normalized 		AllVertsIDMapPath
CreateMap AllBaryCoordsXY_Normalized	AllBaryCoordsMapPath
CreateMap AllUVCoordsXY_Normalized		AllUVCoordsMapPath

