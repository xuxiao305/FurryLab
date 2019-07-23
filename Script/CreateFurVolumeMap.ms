rm = RayMeshGridIntersect () --create an instance of the Reference Target


FUR_SAMPLE_COUNT = 3
NORMALIZE_FACTOR = 40.0
POS_NORMALIZE_FACTOR = 150.0

START_POINT = point3 0 0 0
END_POINT = point3 100 100 0
SIZE_X = 2048
SIZE_Y = 128

CLUMP_TEX_SIZE = 512
FUR_FX_TEMPLATE_SIZE = 32

AllFurBoneChain = #()
AllFurTextureSheets = #()
FurEffectTextureSheet = #()
PositionTextureSheet = #()
SkinDataTextureSheet = #()
PhxBoneSkinDataTextureSheet = #()
PhxBoneIndexDataTextureSheet = #()
PhxBoneIndexDataTextureSheet = #()

ClumpTextureSheet = #()

fn dotBigVector v1 v2 vectorSize = 
(
	local dotOut = 0

	for i = 1 to vectorSize do 
	(
		dotOut += v1[i] * v2[i]
	)

	return dotOut
)

fn mulMatrixVector m v clampValue:false = 
(
	local outVec = BigMatrix 1 m.columns

	for i = 1 to m.columns do 
	(
		outVec[1][i] = dotBigVector m[i] v m.columns
		if clampValue then 
			outVec[1][i] = amax outVec[1][i] 0
	)   

	return outVec[1]
)


fn mulBigMatrix m1 m2 =
(
	local outMat = BigMatrix m1.rows m1.columns

	transM = transpose m1

	for i = 1 to m1.rows do 
	(
		v = m2[i]
		
		local newRow = (mulMatrixVector transM v)
		for k = 1 to m1.columns do 
		(
			outMat[i][k] = newRow[k]
		)
	)

	return outMat
)

fn copyBigMatrix m =
(
	local outMat = BigMatrix m.rows m.columns

	for i = 1 to m.rows do 
	(
		for k = 1 to m.columns do 
		(
			outMat[i][k] = m[i][k]
		)
	)
	return outMat
)

fn CreateDistanceMatrix samplePosList =
(
	local distanceMatrix = BigMatrix samplePosList.count samplePosList.count 


	for i = 1 to samplePosList.count do 
	(
		for k = 1 to samplePosList.count do 
		(		
			dist = distance samplePosList[k] samplePosList[i]  

			distanceMatrix[i][k] = dist
		)
	)
	invert distanceMatrix

	return distanceMatrix
)

Fn NormalizeWeight weightArr num =
(
	local normalizedWeightArr = #()
  	local total = 0

  	for i = 1 to num do
  	(
		total += weightArr[i]
  	)
  	for i = 1 to num do
  	(
    	local weightVal = weightArr[i] / total
    	append normalizedWeightArr weightVal
  	)
  	return normalizedWeightArr
)

fn SolveRBF samplePosList sourcePos = 
(
	distanceMatrix = CreateDistanceMatrix samplePosList

	local distanceVec = BigMatrix 1 samplePosList.count 

	for i = 1 to samplePosList.count do 
	(
		dist = distance samplePosList[i] sourcePos
		distanceVec[1][i] = dist
	)

-- 	format "distanceVec\n%\n" distanceVec
	local rbfWeight = mulMatrixVector (transpose distanceMatrix) distanceVec[1] clampValue:true
	rbfWeight = NormalizeWeight rbfWeight samplePosList.count
	return rbfWeight
)

fn Max2Unity inputVec = 
(
	ouputVec = inputVec
	ouputVec[1] = -inputVec[1]	
	return ouputVec
)




struct FurBoneChain
(
	boneNodeArr = #(),
	rootBn,
	spline,
	spawnUV
)


-------------------------------------------------

Fn CreateBonesAlongSpline furMesh  spline boneNum rootBn =
(
	local newFurBoneChain = FurBoneChain()	
	newFurBoneChain.rootBn = rootBn

	newFurBoneChain.spline = spline

	for i = 1 to boneNum do
	(
		local newName = "Bn_FurPhx_" + spline.name + "_" + (i as string)
		local percent = ((i - 1) as float) / ((boneNum) as float)
		local newPos = interpCurve3D spline 1 percent
		local newBone = point name:newName pos:newPos size:5.0 wirecolor:green cross:on
		
		setUserProp newBone "isFurPhxBone" true

		if (i == 1) then 
		(
			newBone.parent = newFurBoneChain.rootBn

			local closestVert = (kdtree.GetClosestPoint newBone.pos)[1]

			newFurBoneChain.spawnUV = gettvert furMesh.mesh closestVert
		)
		else
		(
			newBone.parent = newFurBoneChain.boneNodeArr[i-1]

		)
		append newFurBoneChain.boneNodeArr newBone
	)




	return newFurBoneChain
)


----------------------------------------------
















fn FindClosestPoint posArr pos = 
(
	nearestDistance = 1000000
	nearestIndex = -1

	for v = 1 to posArr.count do 
	(
		dist = distance pos posArr
		if dist < nearestDistance then
		(
			nearestDistance = dist
			nearestIndex = v
		)			
		if dist < 0.01 then 
		(
			return nearestIndex
		)
	)
	return nearestIndex
)

fn SolveBarycentricCoord pos sourceMsh vertID = 
(
	pos1 = sourceMsh.verts[vertID[1]].pos
	pos2 = sourceMsh.verts[vertID[2]].pos
	pos3 = sourceMsh.verts[vertID[3]].pos

	trianglePosArr = #(pos1, pos2, pos3)

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

fn SampleFurSpline furIndex = 
(
	local furPoints = #()
	local rootKnotPoint = interpCurve3D furSpline furIndex 0

	for i = 1 to FUR_SAMPLE_COUNT do 
	(
		param = i / (FUR_SAMPLE_COUNT as float)
		curPos = interpCurve3D furSpline furIndex param
		vectorFromRoot = curPos - rootKnotPoint
		dist = distance vectorFromRoot (point3 0 0 0)
		if dist > NORMALIZE_FACTOR do
		(
			format "ERROR - The length of hair strand is longger than the normalize factor\n"
			print dist 
			print NORMALIZE_FACTOR
			return 0
		)
-- 		format "vectorFromRoot % \n" vectorFromRoot 
		
		vectorFromRoot = Max2Unity vectorFromRoot
		append furPoints vectorFromRoot
	)
	return furPoints
)



fn CreateFurPoint = 
(
	oldSpawnPointMesh = for o in objects where (getUserProp o "IsFurSpawnPointMesh" == true) collect o

	if oldSpawnPointMesh != undefined then
		delete oldSpawnPointMesh

	local furSpawnPointMesh = Plane  isSelected:on name:"FurPointMesh"
	macros.run "Modifier Stack" "Convert_to_Poly"

	for v = furSpawnPointMesh.verts.count to 1 by -1 do 
	(
		polyop.deleteVerts furSpawnPointMesh v
	)

	setUserProp furSpawnPointMesh "IsFurSpawnPointMesh" true


	if furSpawnPointMesh != undefined and furSpline != undefined then 
	(
		for s = 1 to (numSplines furSpline) do
		(
			knotPos = getKnotPoint furSpline s 1

			newVert = polyop.createVert furSpawnPointMesh knotPos
		)	
	)
	return furSpawnPointMesh
)

fn CreatePhxVertOnUVSpace allFurBoneChain =
(
	oldPhxSplineUVPointMesh = for o in objects where (getUserProp o "IsPhxSplineUVPointMesh" == true) collect o

	if oldPhxSplineUVPointMesh != undefined then
		delete oldPhxSplineUVPointMesh

	local phxSplineUVPointMesh = Plane  isSelected:on name:"FurPhxSplineUVPointMesh"
	macros.run "Modifier Stack" "Convert_to_Poly"

	for v = phxSplineUVPointMesh.verts.count to 1 by -1 do 
	(
		polyop.deleteVerts phxSplineUVPointMesh v
	)

	setUserProp phxSplineUVPointMesh "IsPhxSplineUVPointMesh" true

	for s = 1 to allFurBoneChain.count do
	(
		local uv = allFurBoneChain[s].spawnUV * 100.0
		polyop.createVert phxSplineUVPointMesh uv
	)	
	return phxSplineUVPointMesh
)


fn InitFurData = 
(
	AllFurTextureSheets = #()
	local SingleFurTextureSheet = #()

	for i = 1 to FUR_SAMPLE_COUNT do 
	(
		SingleFurTextureSheet = #()
		for k = 1 to SIZE_Y do 
		(
			SingleFurTextureRow = #() 
			SingleFurTextureRow.count = SIZE_X

			append SingleFurTextureSheet SingleFurTextureRow
		)
		append AllFurTextureSheets SingleFurTextureSheet
	)
)

fn InitFurFXData = 
(
	FurEffectTextureSheet = #()
	local SingleFurTextureSheet = #()

	for i = 1 to FUR_SAMPLE_COUNT do 
	(
		SingleFurTextureSheet = #()
		for k = 1 to FUR_FX_TEMPLATE_SIZE do 
		(
			SingleFurTextureRow = #() 
			SingleFurTextureRow.count = FUR_FX_TEMPLATE_SIZE

			append SingleFurTextureSheet SingleFurTextureRow
		)
		append FurEffectTextureSheet SingleFurTextureSheet
	)
)


fn InitPhxBoneSkinningData = 
(
	PhxBoneSkinDataTextureSheet = #()
	PhxBoneIndexDataTextureSheet = #()

	for k = 1 to SIZE_Y do 
	(
		singleRow = #() 
		singleRow.count = SIZE_X

		append PhxBoneSkinDataTextureSheet singleRow
	)

	for k = 1 to SIZE_Y do 
	(
		singleRow = #() 
		singleRow.count = SIZE_X

		append PhxBoneIndexDataTextureSheet singleRow
	)
)
fn InitSkinningData = 
(
	SkinDataTextureSheet = #()
	for k = 1 to SIZE_Y do 
	(
		singleRow = #() 
		singleRow.count = SIZE_X

		append SkinDataTextureSheet singleRow
	)
)

fn InitPositionData = 
(
	PositionTextureSheet = #()
	for k = 1 to SIZE_Y do 
	(
		singleRow = #() 
		singleRow.count = SIZE_X

		append PositionTextureSheet singleRow
	)
)

fn InitClumpData = 
(
	ClumpTextureSheet = #()
	for k = 1 to CLUMP_TEX_SIZE do 
	(
		singleRow = #() 
		singleRow.count = CLUMP_TEX_SIZE

		append ClumpTextureSheet singleRow
	)
)


fn GetPosOnTriangle msh vertID baryCoord = 
(
	local trianglePos1 = msh.verts[vertID[1]].pos
	local trianglePos2 = msh.verts[vertID[2]].pos
	local trianglePos3 = msh.verts[vertID[3]].pos
	local posOnTriangle = trianglePos1 * baryCoord[1] + trianglePos2 * baryCoord[2] + trianglePos3 * baryCoord[3]

	return posOnTriangle
) 


fn GetSkinningOnTriangle msh vertID baryCoord skinData = 
(
	local skinning1 = skinData[vertID[1]][2]
	local skinning2 = skinData[vertID[2]][2]
	local skinning3 = skinData[vertID[3]][2]


	local maxNum = amax skinning1.count skinning2.count
	maxNum = amax skinning3.count maxNum


	local skinOnTriangle = #(0,0,0,0)
	
	for i = 1 to maxNum do 
	(	
		if skinning1.count >= i do 
			skinOnTriangle[i] += skinning1[i] * baryCoord[1]

		if skinning2.count >= i do 
			skinOnTriangle[i] += skinning2[i] * baryCoord[2]
		
		if skinning3.count >= i do 
			skinOnTriangle[i] += skinning3[i] * baryCoord[3]

	)

-- 	print skinOnTriangle
	
	return skinOnTriangle
)


fn GetSkinData =
(
	SkinMod = modPanel.getCurrentObject()
	boneNameArr = #()
	if (classof SkinMod == Skin) and (skinOps.GetNumberBones SkinMod) > 0 do
	(
		ListofBones = #()
		for i = 1 to (skinOps.GetNumberBones SkinMod) do
			append ListofBones (skinOps.GetBoneName SkinMod i 1)

		boneNameArr = #(ListofBones)
		skinningData = #()
		skinningData.count = skinOps.GetNumberVertices SkinMod
		for v = 1 to skinOps.GetNumberVertices SkinMod do
		(
			BoneArray = #(); WeightArray = #()
			for b = 1 to (skinOps.GetVertexWeightCount SkinMod v) do
			(
				append BoneArray (skinOps.GetVertexWeightBoneID SkinMod v b)
				append WeightArray (skinOps.GetVertexWeight SkinMod v b)
			)
			skinningData[v] = #(BoneArray, WeightArray)
		)
	)
	return #(boneNameArr, skinningData)
)



fn SampleMeshSkinning furMesh uvMesh = 
(
	select furMesh
	SkinMod = modPanel.getCurrentObject()

	local stepX = ((END_POINT.x - START_POINT.x) as float) / (SIZE_X as float)
	local stepY = ((END_POINT.y - START_POINT.y) as float) / (SIZE_Y as float)

	local skinDataAll = (GetSkinData())[2]
	for x = 1 to SIZE_X do 
	(
		for y = 1 to SIZE_Y do 
		(
			rayPos = point3 (x * stepX) (y * stepY) 1 
			rayPos = rayPos + uvMesh.pos
			rayPos = rayPos - (point3 0.5 0.5 0.0)

			rayDir = point3 0 0 -1

			theHitsCount = rm.intersectRay rayPos rayDir true

			uvCoord = rayPos
			local currentPos = point3 rayPos.x rayPos.y 0.0

			if theHitsCount > 0 then 
			(
				theIndex = rm.getClosestHit()
				
				f = rm.getHitFace theIndex	
				vIDs = (meshop.getVertsUsingFace uvMesh f) as array
				
				local baryCoord = SolveBarycentricCoord currentPos uvMesh vIDs
-- 				print skinDataAll
				local skinData = GetSkinningOnTriangle furMesh vIDs baryCoord skinDataAll

-- 				print skinData
				local colorData = color (skinData[1] * 255) (skinData[2] * 255)  (skinData[3] * 255) (skinData[4] * 255) 

				SkinDataTextureSheet[y][x] = colorData
			)
			else
			(
				SkinDataTextureSheet[y][x] = black -- color 127 127 127
			)
		)            
	)	
)

fn SampleMeshPhxBoneSkinning uvMesh phxSplineUVPointMesh = 
(

	kdtree.Initialize phxSplineUVPointMesh 2

	local stepX = ((END_POINT.x - START_POINT.x) as float) / (SIZE_X as float)
	local stepY = ((END_POINT.y - START_POINT.y) as float) / (SIZE_Y as float)

	local allFurPhxBone = for p in helpers where (MatchPattern p.name pattern:"Bn_FurPhx_Line*_1") collect p

	for x = 1 to SIZE_X do 
	(
		for y = 1 to SIZE_Y do 
		(
			rayPos = point3 (x * stepX) (y * stepY) 1 
			rayPos = rayPos + uvMesh.pos
			rayPos = rayPos - (point3 0.5 0.5 0.0)

			rayDir = point3 0 0 -1

			theHitsCount = rm.intersectRay rayPos rayDir true

			local currentPos = point3 rayPos.x rayPos.y 0.0
-- 			format ("x, y -- > %,% \n") x y

			if theHitsCount > 0 then 
			(
				local closestPhxSplinePoint = kdtree.GetNClosestPoints currentPos 4

				local clostestPos = #()
				for p in closestPhxSplinePoint[1] do
				(
					append clostestPos phxSplineUVPointMesh.verts[p].pos
				)
				local rbfWeight = SolveRBF clostestPos currentPos
-- 				format ("closestPhxSplinePoint -- > \n%\n") closestPhxSplinePoint
-- 				format ("clostestPos -- > \n%\n") clostestPos
-- 				format ("rbfWeight -- > \n%\n") rbfWeight

				local colorData = color (rbfWeight[1] * 255) (rbfWeight[2] * 255)  (rbfWeight[3] * 255) (rbfWeight[4] * 255.0) 
				PhxBoneSkinDataTextureSheet[y][x] = colorData


				local factor = floor (255.0 / (allFurPhxBone.count as float))
				local colorData2 = color (closestPhxSplinePoint[1][1] * factor) (closestPhxSplinePoint[1][2] * factor) (closestPhxSplinePoint[1][3] * factor) (closestPhxSplinePoint[1][4] * factor)
				PhxBoneIndexDataTextureSheet[y][x] = colorData2
			)
			else
			(
				PhxBoneSkinDataTextureSheet[y][x] = black -- color 127 127 127
				PhxBoneIndexDataTextureSheet[y][x] = black -- color 127 127 127
			)
		)            
	)	
)

fn SampleMesh furMesh uvMesh = 
(
	local stepX = ((END_POINT.x - START_POINT.x) as float) / (SIZE_X as float)
	local stepY = ((END_POINT.y - START_POINT.y) as float) / (SIZE_Y as float)

	for x = 1 to SIZE_X do 
	(
		for y = 1 to SIZE_Y do 
		(
			rayPos = point3 (x * stepX) (y * stepY) 1 
			rayPos = rayPos + uvMesh.pos
			rayPos = rayPos - (point3 0.5 0.5 0.0)

			rayDir = point3 0 0 -1
			theHitsCount = rm.intersectRay rayPos rayDir true

			local currentPos = point3 rayPos.x rayPos.y 0.0

			if theHitsCount > 0 then 
			(
				theIndex = rm.getClosestHit()
				
				f = rm.getHitFace theIndex	
				vIDs = (meshop.getVertsUsingFace uvMesh f) as array
				
				local baryCoord = SolveBarycentricCoord currentPos uvMesh vIDs
				local interplatePos = GetPosOnTriangle furMesh vIDs baryCoord

				if (interplatePos.z > POS_NORMALIZE_FACTOR) do 
				(
					format "ERROR - The length of fur mesh vertex pos is longger than the normalize factor\n"
					print interplatePos 
					print POS_NORMALIZE_FACTOR
					break()
				)

-- 				if (x < 100) do
-- 				(
-- 					point size:1 wirecolor:green cross:on box:off pos:interplatePos
-- 					point size:1 wirecolor:green cross:on box:off pos:currentPos
-- 				)
				

				local normalizedData = interplatePos / POS_NORMALIZE_FACTOR
				normalizedData = normalizedData * 0.5 + 0.5
-- 				print normalizedData
				local colorData = color (normalizedData[1] * 255) (normalizedData[2] * 255)  (normalizedData[3] * 255) 

				PositionTextureSheet[y][x] = colorData
			)
			else
			(
				PositionTextureSheet[y][x] = black -- color 127 127 127
			)
		)            
	)	
)

fn SampleAllFurs furMesh furSpawnPointMesh uvMesh sampleCount = 
(
	local stepX = ((END_POINT.x - START_POINT.x) as float) / (SIZE_X as float)
	local stepY = ((END_POINT.y - START_POINT.y) as float) / (SIZE_Y as float)

	for x = 1 to SIZE_X do 
	(
		for y = 1 to SIZE_Y do 
		(
			rayPos = point3 (x * stepX) (y * stepY) 1 
			rayPos = rayPos + uvMesh.pos
			rayPos = rayPos - (point3 0.5 0.5 0.0)

			rayDir = point3 0 0 -1
			theHitsCount = rm.intersectRay rayPos rayDir true

			uvCoord = rayPos
			local currentPos = point3 rayPos.x rayPos.y 0.0

			if theHitsCount > 0 then 
			(
				theIndex = rm.getClosestHit()
				
				f = rm.getHitFace theIndex	
				vIDs = (meshop.getVertsUsingFace uvMesh f) as array
				
				local baryCoord = SolveBarycentricCoord currentPos uvMesh vIDs
				local interplatePos = GetPosOnTriangle furMesh 	vIDs 	baryCoord


				-- the closest point and fur index is the same, because the point is created 1 by 1 
				closestPointIndexArr = (kdtree.GetNClosestPoints interplatePos 7)[1]

				for p = 1 to sampleCount do
				(
					local rawData = point3 0 0 0

					for i = 1 to closestPointIndexArr.count do 
					(
						closestPointIndex = closestPointIndexArr[i]

						furPoints = SampleFurSpline closestPointIndex
						rawData += furPoints[p] / (closestPointIndexArr.count as float)
					)
					
					local normalizedData = rawData / NORMALIZE_FACTOR
					normalizedData = normalizedData * 0.5 + 0.5
					local colorData = color (normalizedData[1] * 255) (normalizedData[2] * 255)  (normalizedData[3] * 255) 
					AllFurTextureSheets[p][y][x] = colorData
				)
			)
			else
			(
-- 				print "missed"
				for p = 1 to sampleCount do 
				(
					AllFurTextureSheets[p][y][x] = black -- color 127 127 127
				)
			)
		)            
	)	
)

-- cellNum is the number of cell in row and colume
-- hence the total number of cell is cellNum ^ 2
fn CreateClumpingPoint cellNum = 
(
	allCell = #()


    oldClumpingPointGridMesh = for o in objects where (getUserProp o "IsClumpingPointGridMesh" == true) collect o

	delete oldClumpingPointGridMesh

	newMsh = Plane  isSelected:on name:"ClumpingPointMesh"
	macros.run "Modifier Stack" "Convert_to_Poly"

	for v = newMsh.verts.count to 1 by -1 do 
	(
		polyop.deleteVerts newMsh v
	)

	setUserProp newMsh "IsClumpingPointGridMesh" true


	for y = 0 to (cellNum - 1) do 
	(
		for x = 0 to (cellNum - 1) do 
		(
			randU = (random 0 100) / (100.0 * cellNum) + (x as float) / (cellNum as float)
			randV = (random 0 100) / (100.0 * cellNum) + (y as float) / (cellNum as float)

			randU = randU * 100.0
			randV = randV * 100.0

			newVert = polyop.createVert newMsh (point3 randU randV 0.0)
		)

	)

	return newMsh
)


fn SampleClumpingPointMesh clumpingPointMesh = 
( 
	for x = 1 to CLUMP_TEX_SIZE do 
	(
		for y = 1 to CLUMP_TEX_SIZE do 
		(
			uvCoord = point3 (x * 100.0 / (CLUMP_TEX_SIZE as float)) (y * 100.0 / (CLUMP_TEX_SIZE as float)) 1
			
			p = kdtree.GetClosestPoint uvCoord

			closestIndex = p[1]
			closestPos = clumpingPointMesh.verts[closestIndex].pos
			closestDistance = p[2]

			col = color (closestPos.x * 2.55) (closestPos.y * 2.55) (closestDistance * 2.55)
			ClumpTextureSheet[y][x] = col
		)
	)
)

for i = 1 to ClumpTextureSheet.count do 
(
	format "%\n" (ClumpTextureSheet[i] as string)
)

fn CreateClumpingTexSheet dic = 
(
	textureSheet = bitmap CLUMP_TEX_SIZE CLUMP_TEX_SIZE color:red gamma:1.0 hdr:true

	for y = 1 to CLUMP_TEX_SIZE do 
	(	
		newLine = point2 0 (CLUMP_TEX_SIZE - y)
		linePixels = ClumpTextureSheet[y]
		setPixels textureSheet newLine linePixels
	)

	textureSheet.filename = dic + furMesh.name + "_Clumping" + ".exr"

	save textureSheet

	close textureSheet
	
)


fn CreateVolumeTexSheet dic = 
(
	for b = 1 to AllFurTextureSheets.count do 
	(
		textureSheet = bitmap SIZE_X SIZE_Y color:red gamma:1.0 hdr:true

		for y = 1 to SIZE_Y do 
		(	
			newLine = point2 0 (SIZE_Y - y)
			linePixels = AllFurTextureSheets[b][y]
-- 			format "new line % \n" linePixels 
			setPixels textureSheet newLine linePixels
		)

		textureSheet.filename = dic + furMesh.name + "_" + (b as string) + ".exr"

		save textureSheet

		close textureSheet
	)
)


fn CreateSingleTex dataArray suffix dic =
(
	textureSheet = bitmap SIZE_X SIZE_Y color:red gamma:1.0 hdr:true hasAlpha:true

	for y = 1 to SIZE_Y do 
	(	
		newLine = point2 0 (SIZE_Y - y)
		linePixels = dataArray[y]
		format "new line % \n" linePixels 
		setPixels textureSheet newLine linePixels
	)

	textureSheet.filename = dic + furMesh.name + suffix  + ".exr"

	save textureSheet

	close textureSheet

)

directionary = "D:\\OneDrive\\ToyLabsP4v\\Alice\\Engine\\Alice\\Assets\\Texture\\Girl\\FurTextureSheet\\"

furSpawnPointMesh
phxSplineUVPointMesh
furSpline =  (for o in objects where ((getUserProp o "Spline") == true) collect o)[1]
-- furSpline = $
uvMesh = (for o in objects where ((getUserProp o "UV") == true) collect o)[1]
furMesh = (for o in objects where ((getUserProp o "Fur") == true) collect o)[1]


select uvMesh 
macros.run "Modifier Stack" "Convert_to_Mesh"

clearListener()

try (DestroyDialog FurVolumeMapGenerator)
catch()

rollout FurVolumeMapGenerator "Fur Map Generator"
(
	pickButton pkFurSpline "Pick Fur"  align:#left width:135

	button btnCreateVertex "Create Fur Vertex" align:#left  width:135

	button btnCreateVolMap "Create Fur Volume Map" align:#left  width:135
	button btnCreatePosMap "Create Mesh Position Map" align:#left  width:135


	label lbl0 " "
	label lblSkinning "Skinning Map Setting"
	button btnCreateSkinningMap "Create Skinning Tex"
	button btnSetBoneSpline "Set as Bone Spline"
	button btnCreateBones "Create Bone Along Spline"
	button btnCreatePhxBoneSkinningMap "Create Phx Bone Skinning Tex"
	button btnCreateConstraintBoneMap "Create Attachment Constraint"


	label lbl " "
	label lblClumping "Clumping Map Setting"
	button btnCreateClumpingMap "Create Clump Map" align:#left width:135

	
	

	label lbl1 " "
	label lblBary "Generate Bary Coord"
	button btnCreateBaryArray "Create Bary Array" align:#left width:135

	on pkFurSpline picked obj  do
	(
		furSpline = obj
		setUserProp obj "Spline" true

	)
	on btnCreateVertex pressed do 
	(
		furSpawnPointMesh = CreateFurPoint()

	)

	on btnCreateClumpingMap pressed do
	(
		InitClumpData()
		clumpingPointMesh = CreateClumpingPoint 10

		kdtree.Initialize clumpingPointMesh 5

		SampleClumpingPointMesh clumpingPointMesh

		kdtree.free()	

		CreateClumpingTexSheet directionary
		

	)
	on btnCreateVolMap pressed do 
	(
		InitFurData ()

		rm.Initialize 10 --init. the voxel grid size to 10x10x10
		rm.addNode uvmesh --add the sphere to the grid
		rm.buildGrid () --build the grid data (collecting faces into the grid voxels)

		kdtree.Initialize furSpawnPointMesh 10

		SampleAllFurs furMesh furSpawnPointMesh uvMesh FUR_SAMPLE_COUNT

		rm.free() 

		kdtree.Free()

		CreateVolumeTexSheet directionary
	)

	on btnCreatePosMap pressed do 
	(

		InitPositionData ()

		rm.Initialize 10 --init. the voxel grid size to 10x10x10
		rm.addNode uvmesh --add the sphere to the grid
		rm.buildGrid () --build the grid data (collecting faces into the grid voxels)


		SampleMesh furMesh uvMesh  

		rm.free() 

		CreateSingleTex PositionTextureSheet "_Position" directionary
	)

	on btnCreateSkinningMap pressed do 
	(
		InitSkinningData()

		rm.Initialize 10 --init. the voxel grid size to 10x10x10
		rm.addNode uvmesh --add the sphere to the grid
		rm.buildGrid () --build the grid data (collecting faces into the grid voxels)

		SampleMeshSkinning furMesh uvMesh

		rm.free()

		CreateSingleTex SkinDataTextureSheet "_Skin" directionary
	)

	on btnCreatePhxBoneSkinningMap pressed do 
	(
		InitPhxBoneSkinningData()

		rm.Initialize 10 --init. the voxel grid size to 10x10x10
		rm.addNode uvmesh --add the sphere to the grid
		rm.buildGrid () --build the grid data (collecting faces into the grid voxels)

		phxSplineUVPointMesh = CreatePhxVertOnUVSpace AllFurBoneChain
		SampleMeshPhxBoneSkinning uvMesh phxSplineUVPointMesh
		CreateSingleTex PhxBoneSkinDataTextureSheet "_Phx" directionary
		CreateSingleTex PhxBoneIndexDataTextureSheet "_PhxIndex" directionary
		
		kdtree.free()

		rm.free()
	)

	on btnCreateConstraintBoneMap pressed do 
	(
		skinDataFile = openfile  "d:\\FurBonesConstraint.xml" mode:"w"

		kdtree.Initialize furMesh 5

		select furMesh
		local meshSkinData = GetSkinData()
		local allBones = meshSkinData[1][1]

		format "<Root>\n" to:skinDataFile
		for b in allBones do 
		(
			format "\t<BaseBone Name = \"%\"/>\n" b to:skinDataFile
		) 
		format "\n" to:skinDataFile

		local firstBoneList = for p in helpers where (MatchPattern p.name pattern:"Bn_FurPhx_Line*_1") collect p

		local closestVertList = #()
		local closestSkinList = #()


		for p = 1 to firstBoneList.count do 
		(
			local closestVert = (kdtree.GetClosestPoint firstBoneList[p].pos)[1]
			append closestVertList closestVert

			local skinning = meshSkinData[2][closestVert]
			append closestSkinList skinning

			boneID = skinning[1]
			boneWeight = skinning[2]

			format "\t<FurBone " to:skinDataFile
			format "Name = \"%\" "  firstBoneList[p].name to:skinDataFile
			format "BoneID = \""   to:skinDataFile
			for s = 1 to boneID.count do 
			(
				if s < boneID.count then
					format "%, " (boneID[s] - 1) to:skinDataFile
				else 
					format "%" (boneID[s] - 1) to:skinDataFile
			)
			format "\" " to:skinDataFile


			format "BoneWeight = \""  to:skinDataFile
			for s = 1 to boneWeight.count do 
			(
				if s < boneWeight.count then
					format "%, " boneWeight[s] to:skinDataFile
				else 
					format "%" boneWeight[s] to:skinDataFile
			)
			format "\" " to:skinDataFile

			format "/>\n" to:skinDataFile
		)
		format "</Root>\n" to:skinDataFile
		try 
		(
			flush skinDataFile
			free skinDataFile
			close skinDataFile
			gc()
		)
		catch()
		

		
	)

	on btnCreateBones pressed do 
	(

		local oldBones = for b in objects where (getUserProp b "isFurPhxBone" == true) collect b
		delete oldBones

		local boneSpline = for s in shapes where (getUserProp s "IsBoneSpline" == true) collect s 

		kdtree.Initialize furMesh 5

		for s in boneSpline do 
		(
			local newBoneChain = CreateBonesAlongSpline furMesh s 2 $Bn_Root
			append AllFurBoneChain newBoneChain
		)

		kdtree.free()
		
	)

	on btnSetBoneSpline pressed do 
	(
		for s in shapes do 
		(
			setUserProp s "IsBoneSpline" false
		)
		for s in shapes do
		(
			if classof s == line then 
				setUserProp s "IsBoneSpline" true
		)
	)


	on btnCreateBaryArray pressed do 
	(
		triMesh = $Triangle
		barMesh = $Bary
		vertID = #(1,2,3)

		baryCoordList = #()

		for v in barMesh.verts do 
		(
			local pos = v.pos
			local baryCoord = SolveBarycentricCoord pos triMesh vertID 
			
			format "half3(%,%,%),\n" baryCoord[1] baryCoord[2] baryCoord[3]


		)

		print baryCoordList
	)

)

CreateDialog FurVolumeMapGenerator 