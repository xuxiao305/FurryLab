clearListener()

try 
( 
close tex
free LUT
)

catch()

pth = @"D:\OneDrive\ToyLabsP4v\Alice\Engine\Alice\Assets\Texture\Girl\FurTextureSheet\Cape_FurProxy_Quater_1.exr"
tex = openBitMap  pth

compactedUVArr = #()

progressStart "compactedUVArr"

for y = 1 to tex.height do 
(
	local arr = #()

	c = point2 0 y
	pixelRow = getPixels tex c tex.width 

	for x = 1 to pixelRow.count do 
	(
		if (pixelRow[x] != black) do 
		(
			append arr [(x as float) / pixelRow.count , (y as float) / tex.height]
		)
	)

	progressUpdate ((y as float) / (tex.height as float))
	join compactedUVArr arr
) 

close tex
free tex


progressEnd()


progressStart "Create Map"

width = 64
height = (ceil (compactedUVArr.count / (width as float) )) as integer

LUT = bitmap width height color:red gamma:1.0 hdr:true
outputPath = @"D:\OneDrive\ToyLabsP4v\Alice\Engine\Alice\Assets\Texture\Girl\FurTextureSheet\LUT.exr"

for i = 0 to height - 1 do 
(	
	newLine = point2 0 i
	linePixels = #()

	for j = 1 to width do 
	(
		uv = compactedUVArr[j + i * width] 

		if (uv != undefined) then
		(
			uvInColor = color (uv[1] * 255) (uv[2] * 255) 0
-- 			uvInColor = color uv[1] uv[2] 0
			append linePixels uvInColor
		)
		else
		(
			print "reach end"
		)
	)
	
-- 	format "new line % \n" linePixels 
	setPixels LUT newLine linePixels

	progressUpdate ((i as float) / (tex.height as float))
)

progressEnd()

LUT.filename = outputPath

save LUT

close LUT
free LUT




-- pth = @"D:\OneDrive\ToyLabsP4v\Alice\Engine\Alice\Assets\Texture\Girl\FurTextureSheet\LUT.exr"
-- texLoad = openBitMap  pth


-- progressStart "Reading Map"

-- for y = 1 to texLoad.height do 
-- (
-- 	local arr = #()

-- 	c = point2 0 y
-- 	pixelRow = getPixels texLoad c texLoad.width 

-- 	for x = 1 to pixelRow.count do 
-- 	(
-- 		point pos:pixelRow[x] size:0.2

-- 	)
-- 	progressUpdate ((y as float) / (texLoad.height as float))
-- ) 

-- progressEnd()


-- close texLoad
-- free texLoad