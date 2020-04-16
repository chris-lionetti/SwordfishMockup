function Get-SFFabricRoot {
	param()
	process{
		$SRoot=[ordered]@{
				'@odata.Copyright'	=	$RedfishCopyright;
				'@odata.type'		=	'#FabricCollection.FabricCollection';
				'@odata.id'			=	'/redfish/v1/Fabrics';
                Name				=	'Fabrics Collection';
                'Members@odata.count'=	1;                
				Members				=	@( @{	'@odata.id'	=	'/redfish/v1/Fabrics/'+$NimbleSerial
										 	}
										 )	
			 		 	 }
		Return $SRoot
	}
}

function Get-SFFabric {
	param(	$ArrayName
	 	 )
	process{
		$Array= Get-NSArray
		$SSA=[ordered]@{
				'@odata.Copyright'			=	$RedfishCopyright;
				'@odata.type'				=	'#Fabric.v1_1_0.Fabric';
				'@odata.id'					=	'/redfish/v1/Fabrics/'+$NimbleSerial;
				Name						=	$Array.name;
				Id							=	$Array.id;
				Description					=	"Fabric for "+$Array.description;
				Status						=	@{	State 	=	'Enabled';
													Health	=	'OK'
												};
				Endpoints					=	'/redfish/v1/Fabrics/'+$NimbleSerial+'/Endpoints';
					  }
		if ($Array.serial -like $ArrayName) 
			{	Return $SSA
			}
	}
}