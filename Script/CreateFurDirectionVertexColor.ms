struct FurMap
(
	baseMesh,
	guideline,
	sampleLayerCount,
	vertToSplineMapping,
	hairPositionValues,

	normalizeFactor,
	outputPath,

	fn SetPath pathStr = 
	(
		-- outputPath = "D:\\OneDrive\\ToyLabsP4v\\Alice\\Engine\\Alice\\Assets\\Texture\\Generic\\FurDirectionMap.exr"
		outputPath = pathStr + baseMesh.name + ".exr"
	),

	fn Max2Unity inputVec = 
	(
		ouputVec = inputVec
		ouputVec[1] = -inputVec[1]	
		return ouputVec
	),



	fn MapVertToSpline = 
	(
		percent = 0.0
		for v = 1 to baseMesh.verts.count do 
		(
			percent = v / (baseMesh.verts.count as float)

			nearestKnotDistance = 1000000
			nearestKnotIndex = -1
			nearestSplineIndex = -1

			for s = 1 to (numSplines guideline) do
			(
				knotPos = getKnotPoint guideline s 1
				dist = distance knotPos baseMesh.verts[v].pos
				if dist < nearestKnotDistance then
				(
					nearestKnotDistance = dist
					nearestSplineIndex = s
				)			
				if dist < 0.1 then 
				(
					print "skipped"
					continue	
				)
			)
			append vertToSplineMapping #(v, nearestSplineIndex)

			
		)
	),

	fn SampleSpline = 
	(
		percent = 0.0
		iter = 0
		for mapping in  vertToSplineMapping do 
		(
			iter += 1
			v = mapping[1]
			sp = mapping[2]

			local newVal = #()

			rootKnotPoint = baseMesh.verts[v].pos
			tipKnotPoint = interpCurve3D guideline sp 1.0
			vectorFromRoot = tipKnotPoint - rootKnotPoint

			newVal = #(rootKnotPoint, tipKnotPoint)

			/*
			rootKnotPoint = interpCurve3D guideline sp 0

			for i = 0 to (sampleLayerCount - 1) do 
			(
				param = i / ((sampleLayerCount - 1) as float)
				curPos = interpCurve3D guideline sp param
				vectorFromRoot = curPos - rootKnotPoint
				if (distance vectorFromRoot (point3 0 0 0)) > normalizeFactor do
				(
					format "ERROR - The length of hair strand is longger than the normalize factor\n"
				)
				
		-- 		normVectorFromRoot = Max2Unity normVectorFromRoot
				append newVal vectorFromRoot
			)
			*/
			append hairPositionValues newVal


			percent = (iter as float) / (vertToSplineMapping.count as float)

		)	
	),
	
	fn SetVertexColor = 
	(
		for i = 1 to baseMesh.verts.count do 
		(
			pos1 = hairPositionValues[i][1]
			pos2 = hairPositionValues[i][2]
			dir = (pos2 - pos1) / (distance pos2 pos1)
			dir.x = dir.x * 0.5 + 0.5
			dir.y = dir.y * 0.5 + 0.5
			dir.z = dir.z * 0.5 + 0.5

			col = color (dir.x * 255.0 ) (dir.y * 255.0) (dir.z * 255.0)
			meshop.setVertColor baseMesh 0 #(i) col
		
		)
	)
)

try (DestroyDialog FurMapUtilitiy) 
catch()

rollout FurMapUtilitiy "Fur Map Utility"
(
	button btnSampleFlowMap "Sample Flow Spline" 
	button btnSamplePositionMap "Sample Position"
	button btnSampleNormalMap "Sample Normal"

	on btnSampleFlowMap pressed do 
	(
		m =  (for i in selection where superclassof i == GeometryClass collect i)[1]
		l = (for i in selection where superclassof i == shape collect i)[1]

		if (m != undefined and l != undefined) then 
		(
			furMap = FurMap baseMesh:m guideline: l
		
			furMap.sampleLayerCount = 2
			furMap.vertToSplineMapping = #()
			furMap.hairPositionValues = #()

			furMap.normalizeFactor = 200.0

			local pth = "D:\\OneDrive\\ToyLabsP4v\\Alice\\Engine\\Alice\\Assets\\Texture\\Girl\\" 
			furMap.setPath pth

			furMap.mapVertToSpline()
			furMap.SampleSpline()
			furMap.SetVertexColor()
		)
		else
		(
			messageBox "no mesh or guideline specified"
		)
	)

	on btnSamplePositionMap pressed do 
	(
		m =  (for i in selection where superclassof i == GeometryClass collect i)[1]

		if m != undefined then 
		(
			furMap = FurMap baseMesh:m guideline: l
		
			furMap.setPath pth

			furMap.SetPositionToColor()
		)
		else
		(
			messageBox "no mesh specified"
		)	
	)

)

CreateDialog FurMapUtilitiy
