
function Get-SFStorageSystemRoot {
	param(	
		 )
	process{
		$SSRoot=[ordered]@{	
				'@odata.type'		=	'#StorageSystemCollection.1.1.0.StorageSystempCollection';
				'@odata.Copyright'	=	$RedfishCopyright;
				'@odata.context'	=	'/redfish/v1/$metadata#StorageSystem.StorageSystem';
				'@odata.id'			=	'/redfish/v1/StorageSystems';
				Name				=	'Storage System Collection';
				Members				=	@( @{	'@odata.id'	=	'/redfish/v1/StorageSystems/'+$NimbleSerial
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
				'@odata.type'				=	'#StorageSystemCollection.1.0.0.StorageSystemCollection';
				'@odata.Copyright'			=	$RedfishCopyright;
				'@odata.context'			=	'/redfish/v1/$metadata#StorageSystem.StorageSystem'+$NimbleSerial;
				'@odata.id'					=	'/redfish/v1/StorageSystems/'+$NimbleSerial;
				Name						=	$Array.name;
				Id							=	$Array.id;
				Description					=	$Array.description;
				Status						=	@{	State 	=	'Enabled';
													Health	=	'OK'
												};
				Drives						=	'/redfish/v1/Chassis/'+$NimbleSerial+'/drives';
				Chassis						=	'/redfish/v1/Chassis/'+$NimbleSerial;
				Endpoints					=	'/redfish/v1/StorageSystems/'+$NimbleSerial+'/Endpoints';
				EndpointGroups				=	'/redfish/v1/StorageSystems/'+$NimbleSerial+'/EndpointGroups';
				ConsistencyGroups			=	'/redfish/v1/StorageSystems/'+$NimbleSerial+'/ConsistencyGroups';
				StorageGroups				=	'/redfish/v1/StorageSystems/'+$NimbleSerial+'/StorageGroups';
				StoragePools				=	'/redfish/v1/StorageSystems/'+$NimbleSerial+'/StoragePools';
				Volumes						=	'/redfish/v1/StorageSystems/'+$NimbleSerial+'/Volumes';
				LineOfService				= 	'/redfish/v1/StorageSystems/'+$NimbleSerial+'/LineOfService'	
			  		  }
		if ($Array.serial -like $ArrayName) 
			{	Return $SSA
			}
	}
}