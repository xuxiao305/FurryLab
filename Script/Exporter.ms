

fn FBX_Export sel =
(
	fbxFilename = sel.name + ".fbx"

-- 	maxExportPath = "D:\OneDrive\ToyLabsP4v\Alice\3DSMax\Queen\_Export\\" + fbxFilename  
-- 	enginePath = "D:\OneDrive\ToyLabsP4v\Alice\Engine\Alice\Assets\Mesh\Queen\\Fur\\" + fbxFilename
enginePath = "D:\OneDrive\ToyLabsP4v\Alice\Engine\Alice\Assets\Mesh\\" + fbxFilename

	--Geometry------------------------------------------------------------------------
	FBXExporterSetParam "SmoothingGroups" true
	FBXExporterSetParam "NormalsPerPoly" false
	FBXExporterSetParam "TangentSpaceExport" true
	FBXExporterSetParam "SmoothMeshExport" true
	FBXExporterSetParam "Preserveinstances" false
	FBXExporterSetParam "SelectionSetExport" false
	FBXExporterSetParam "GeomAsBone" false
	FBXExporterSetParam "ColladaTriangulate" true
	FBXExporterSetParam "PreserveEdgeOrientation" false
	--Animation------------------------------------------------------------------------
	FBXExporterSetParam "Animation" false
	--Cameras------------------------------------------------------------------------
	FBXExporterSetParam "Cameras" false
	--Lights------------------------------------------------------------------------
	FBXExporterSetParam "Lights" false
	--Embed Media--------------------------------------------------------------------
	FBXExporterSetParam "EmbedTextures" false
	--Units----------------------------------------------------------------------------
	--Axis Conversion-----------------------------------------------------------------
	FBXExporterSetParam "AxisConversionMethod" "None"
	FBXExporterSetParam "UpAxis" "Y" 
	--UI----------------------------------------------------------------
	FBXExporterSetParam "ShowWarnings" true
	FBXExporterSetParam "GenerateLog" false
	--FBX File Format----------------------------------------------------------------
	FBXExporterSetParam "ASCII" false
	FBXExporterSetParam "FileVersion" "FBX201200"
	-- Path and file name stuff


-- 	exportFile maxExportPath #noPrompt selectedOnly:true using:FBXEXP 
	exportFile enginePath #noPrompt selectedOnly:true using:FBXEXP 
)

x = deepCopy (selection as array)

for i in x do 
(
	select i
	FBX_Export i
)
