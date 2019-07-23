fn dotBigVector v1 v2 vectorSize = 
(
	local dotOut = 0

	for i = 1 to vectorSize do 
	(
		dotOut += v1[i] * v2[i]
	)

	return dotOut
)

fn mulMatrixVector m v = 
(
	local outVec = BigMatrix 1 m.columns

	for i = 1 to m.columns do 
	(
		outVec[1][i] = dotBigVector m[i] v m.columns
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

-- test 
clearListener()
v1 = [1, 2, 3, 1]
vv1 = BigMatrix 1 4
vv1[1][1] = v1[1]
vv1[1][2] = v1[2]
vv1[1][3] = v1[3]
vv1[1][4] = v1[4]

print (translate  $.transform v1) 

bigM = BigMatrix 4 4

for i = 1 to 4 do 
(
	for k = 1 to 3 do 
	(
		bigM[i][k] = $.transform[i][k]
	)
	bigM[i][4] = 0.0
)

bigM[4][4] = 1.0
invBigM = copyBigMatrix bigM
invBigM = invert invBigM


x = mulMatrixVector (transpose bigM) vv1[1]



x = mulBigMatrix  invBigM bigM
x

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


fn SolveRBF distanceMatrix sourcePos = 
(
	local distanceVec = BigMatrix 1 samplePosList.count 

	for i = 1 to samplePosList.count do 
	(
		dist = distance samplePosList[i] sourcePos
		distanceVec[1][i] = dist
	)

	format "distanceVec\n%\n" distanceVec
	local rbfWeight = mulMatrixVector (transpose distanceMatrix) distanceVec[1]

	return rbfWeight
)
samplePosList = for o in helpers where (MatchPattern o.name pattern:"Point*") collect o.pos
DistanceMatrix = CreateDistanceMatrix samplePosList
print distanceMatrix

rbfWeight = SolveRBF distanceMatrix $.pos
