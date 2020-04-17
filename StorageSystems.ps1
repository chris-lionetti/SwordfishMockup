
function Get-SFStorageSystemRoot {
	param(	
		 )
	process{
		$SSRoot=[ordered]@{	
				'@odata.Copyright'	=	$RedfishCopyright;
				'@odata.type'		=	'#StorageCollection.StorageCollection';
				'@odata.id'			=	'/redfish/v1/Storage';
				Name				=	'Storage System Collection';
				Members				=	@( @{	'@odata.id'	=	'/redfish/v1/Storage/'+$NimbleSerial
										 	}
										 )	
			 		  }
		Return $SSRoot
	}
}

function Get-SFStorageSystem {
	param(	$ArrayName
	 	 )
	process{
		$Array= Get-NSArray
		$SSA=[ordered]@{
				'@odata.Copyright'			=	$RedfishCopyright;
				'@odata.type'				=	'#Storage.v1_0_0.System';
				'@odata.id'					=	'/redfish/v1/Storage/'+$NimbleSerial;
				Name						=	$Array.name;
				Id							=	$Array.id;
				Description					=	$Array.description;
				Status						=	@{	State 	=	'Enabled';
													Health	=	'OK'
												};
				Drives						=	'/redfish/v1/Chassis/'+$NimbleSerial+'/drives';
				Chassis						=	'/redfish/v1/Chassis/'+$NimbleSerial;
				Endpoints					= 	'/redfish/v1/Fabrics/'+$NimbleSerial+'/Endpoints';
				EndpointGroups				=	'/redfish/v1/Storage/'+$NimbleSerial+'/EndpointGroups';
				ConsistencyGroups			=	'/redfish/v1/Storage/'+$NimbleSerial+'/ConsistencyGroups';
				StorageGroups				=	'/redfish/v1/Storage/'+$NimbleSerial+'/StorageGroups';
				StoragePools				=	'/redfish/v1/Storage/'+$NimbleSerial+'/StoragePools';
				Volumes						=	'/redfish/v1/Storage/'+$NimbleSerial+'/Volumes';
				LineOfService				= 	'/redfish/v1/Storage/'+$NimbleSerial+'/LineOfService'	
			  		  }
		if ($Array.serial -like $ArrayName) 
			{	Return $SSA
			}
	}
}