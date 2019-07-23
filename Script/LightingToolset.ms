rollout AliceLightingToolSet "AliceLightingToolSet"
(
	button btn_hideOtherCam "Hide Other Cameras"
	button btn_hideOtherLight "Hide Other Lights"
	button btn_unhideLights "Unhide All Lights"

	on btn_hideOtherCam pressed do
	(
		hide cameras 
		
		if selection.count != 0 then (
			unhide selection
			for i in selection do 
			(
				if superclassof i == camera do unhide (getNodeByName (i.name + ".Target"))
			)
		)
	)
	
	on btn_hideOtherLight pressed do
	(
		hide lights 
		if selection.count != 0 then (
			for i in selection do 
			(
				if superclassof i == light do 
				(
					unhide i
					unhide (getNodeByName (i.name + ".Target"))
				)
			)				
		)
	)
	
	on btn_unhideLights pressed do
	(
		unhide lights
	)
)

createdialog AliceLightingToolSet