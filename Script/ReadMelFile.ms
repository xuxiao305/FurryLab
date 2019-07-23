global useCachedMel = true
macros.run "Modifier Stack" "Convert_to_Poly"

all_object = deepcopy (selection as array)

for obj in all_object do
(
	select obj
	-- if hairCurvesList.count != 0 then useCachedMel = true
	msh = (for i in selection where superclassof i == GeometryClass collect i)[1]
	furMeshList = for i in geometry where (MatchPattern i.name pattern:"Queen_FurModel_*") collect i

	outputPath = "D:\\OneDrive\\ToyLabsP4v\\Alice\\Engine\\Alice\\Assets\\Texture\\Queen\\" + msh.name + ".exr"
	melPath = @"C:\Users\User\AppData\Local\Temp\QueenFur01.mel"
	-- melPath = @"C:\Users\User\AppData\Local\Temp\description13.mel"
	clearListener()

	sampleLayerCount = 20
	normalizeFactor = 1.0
	if not useCachedMel then 
	(
		global hairCurvesList = ReadMelFile()
	)

	-- print vertCurveMapping
	fn Maya2Max inputVec = 
	(
		outputVec = point3 inputVec[1] -inputVec[3] inputVec[2]
		return outputVec
	)
	fn Max2Unity inputVec = 
	(
		outputVec = point3 -inputVec[1]	inputVec[3]	-inputVec[2]

	-- 	outputVec = point3 -inputVec[1]	inputVec[2] inputVec[3]
		return outputVec
	)


	struct HairCurveStruct 
	(
		posList = #()
	)

	fn ReadMelFile = 
	(
		outList = #()
		f = openFile melPath
		while not (eof f) do
		(
			newLine = readLine f
			if newLine != undefined then
			(
				if (findString newLine " -p ") != undefined then
				(
					newLine = substituteString newLine " -p " ","
					newLine = substituteString newLine "$xgMelCurve = `curve -degree " ""	
					newLine = substituteString newLine "`;" ""	
					newLine = replace newline 1 2 ""
					curvePointList = filterString newLine ","
					
					newHairCurve = HairCurveStruct()

					for i = 1 to curvePointList.count do
					(
						scriptString = "point3 " + curvePointList[i]
						newPos = (execute scriptString)
						newPos = Maya2Max newPos
						append newHairCurve.posList newPos
					)
					append outList newHairCurve
				)
			)
		)
		close f
		return outList
	)

	fn FindNearestCurve =
	(
		mapping = #()
		msh = (for i in selection where superclassof i == GeometryClass collect i)[1]

		for v = 1 to msh.verts.count do 
		(
			nearestKnotDistance = 1000000
			nearestKnotIndex = -1
			nearestSplineIndex = -1

			for c = 1 to hairCurvesList.count do
			(
				knotPos = hairCurvesList[c].posList[1]
				dist = distance knotPos (msh.verts[v].pos - msh.pos)
				if dist < nearestKnotDistance then
				(
					nearestKnotDistance = dist
					nearestSplineIndex = c
				)			
				if dist < 0.00001 then 
				(
					continue	
				)
			)
			append mapping #(v, nearestSplineIndex)
		)
		return mapping
	)


	fn SetHairDirectionValue = 
	(
		outList = #()
		for i = 1 to vertCurveMapping.count do 
		(
			mapping = vertCurveMapping[i]
			v = mapping[1]
			sp = mapping[2]

			local newVal = #()
			rootKnotPoint = hairCurvesList[sp].posList[1]

			for s = 1 to hairCurvesList[sp].posList.count do 
			(
		-- 		param = s / ((sampleLayerCount - 1) as float)
		-- 		param = pow param 0.5
				curPos = hairCurvesList[sp].posList[s]
				vectorFromRoot = curPos - rootKnotPoint
				
				normVectorFromRoot = (vectorFromRoot / normalizeFactor)
				normVectorFromRoot = Maya2Max normVectorFromRoot
				normVectorFromRoot = Max2Unity normVectorFromRoot

				normVectorFromRoot = normVectorFromRoot * 0.5 + 0.5
				normVectorFromRoot = normVectorFromRoot * 255
				col = color (normVectorFromRoot[1]) (normVectorFromRoot[2]) (normVectorFromRoot[3])
				append newVal col
			)
			append outList newVal
		)
		return outList
	)





	vertCurveMapping = FindNearestCurve()

	-- print vertCurveMapping

	hairDirectionValues = SetHairDirectionValue()
	-- print hairDirectionValues

	width = hairDirectionValues[1].count    
	height = hairDirectionValues.count 

	b = bitmap width height color:red gamma:1.0 hdr:true

	for i = 1 to hairDirectionValues.count do 
	(	
		newLine = point2 0 (hairDirectionValues.count - i)
		linePixels = hairDirectionValues[i]
	-- 	format "new line % \n" linePixels 
		setPixels b newLine linePixels
	)


	b.filename = outputPath	

	save b

	close b
)
