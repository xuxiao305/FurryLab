msh = (for i in selection where superclassof i == GeometryClass collect i)[1]
guideline = (for i in selection where superclassof i == shape collect i)[1]
clearListener()
sampleLayerCount = 10
vertToSplineMapping = #()
hairDirectionValues = #()
normalizeFactor = 20.0

-- outputPath = "D:\\OneDrive\\ToyLabsP4v\\Alice\\Engine\\Alice\\Assets\\Texture\\Generic\\FurDirectionMap.exr"
outputPath = "D:\\OneDrive\\ToyLabsP4v\\Alice\\Engine\\Alice\\Assets\\Texture\\Girl\\" + msh.name + ".exr"
for v = 1 to msh.verts.count do 
(
	nearestKnotDistance = 1000000
	nearestKnotIndex = -1
	nearestSplineIndex = -1

	for s = 1 to (numSplines guideline) do
	(
		knotPos = getKnotPoint guideline s 1
		dist = distance knotPos msh.verts[v].pos
		if dist < nearestKnotDistance then
		(
			nearestKnotDistance = dist
			nearestSplineIndex = s
		)			
		if dist < 0.01 then 
		(
			exit	
		)
	)
	append vertToSplineMapping #(v, nearestSplineIndex)
)


fn Max2Unity inputVec = 
(
	ouputVec = inputVec
	ouputVec[1] = -inputVec[1]	
	return ouputVec
)

print vertToSplineMapping	
for mapping in  vertToSplineMapping do 
(
	v = mapping[1]
	sp = mapping[2]

	local newVal = #()
	rootKnotPoint = interpCurve3D guideline sp 0
-- 	rootKnotPoint = point3 0 0 0

	print v
	for i = 0 to (sampleLayerCount - 1) do 
	(
		param = i / ((sampleLayerCount - 1) as float)
		param = pow param 0.5
		curPos = interpCurve3D guideline sp param
		vectorFromRoot = curPos - rootKnotPoint
		if (distance vectorFromRoot (point3 0 0 0)) > normalizeFactor do
		(
			format "ERROR - The length of hair strand is longger than the normalize factor\n"
			return 0
		)
		format "vectorFromRoot % \n" vectorFromRoot 
		
		normVectorFromRoot = (vectorFromRoot / normalizeFactor)
		normVectorFromRoot = Max2Unity normVectorFromRoot
		normVectorFromRoot = normVectorFromRoot * 0.5 + 0.5
		col = color (normVectorFromRoot[1] * 255) (normVectorFromRoot[2] * 255) (normVectorFromRoot[3] * 255) 255
		append newVal col
	)
	append hairDirectionValues newVal
)



width = hairDirectionValues[1].count    
height = hairDirectionValues.count 

b = bitmap width height color:red gamma:1.0 hdr:true


for i = 1 to hairDirectionValues.count do 
(	
	newLine = point2 0 (hairDirectionValues.count - i)
	linePixels = hairDirectionValues[i]
	format "new line % \n" linePixels 
	setPixels b newLine linePixels
)


b.filename = outputPath

save b

close b