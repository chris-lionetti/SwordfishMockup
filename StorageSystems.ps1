
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
				'@odata.type'				=	'#Storage.v1_8_0.System';
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
				Connections					=	'/redfish/v1/Fabrics/'+$NimbleSerial+'/Connections';
				Zones						=	'/redfish/v1/Fabrics/'+$NimbleSerial+'/Zones';
				ConsistencyGroups			=	'/redfish/v1/Storage/'+$NimbleSerial+'/ConsistencyGroups';
				StoragePools				=	'/redfish/v1/Storage/'+$NimbleSerial+'/StoragePools';
				StorageControllers			=	'/redfish/v1/Storage/'+$NimbleSerial+'/StorageControllers';
				Volumes						=	'/redfish/v1/Storage/'+$NimbleSerial+'/Volumes';
				LineOfService				= 	'/redfish/v1/Storage/'+$NimbleSerial+'/LineOfService'	
			  		  }
		if ($Array.serial -like $ArrayName) 
			{	Return $SSA
			}
	}
}

function Get-SFStorageController {
	param(	$ControllerName
	 	 )
	process{
		$Controller= Get-NSArray | where {$_.name -like ( $NimbleSerial+'-'+$ControllerName ) }
		$FirmwareVersion = (Get-NSGroup).version_current
		$SSA=[ordered]@{
				'@odata.Copyright'			=	$RedfishCopyright;
				'@odata.type'				=	'#StorageController.v1_8_0.StorageController';
				'@odata.id'					=	'/redfish/v1/Storage/'+$NimbleSerial+'/StorageControllers/'+$NimbleSerial+'-'+$ControllerName;
				Name						=	$Controller.hostname;
				Id							=	$Controller.id;
				Description					=	'Controller '+$NimbleSerial+' controller '+$controllerName;
				Status						=	@{	State 	=	'Enabled';
													Health	=	'OK'
												};
				Manufacturer				=	'HPE Nimble Storage';
				FirmwareVersion				=	$FirmwareVersion
			  		  }
		if ($Array.serial -like $ArrayName) 
			{	Return $SSA
			}
	}
}

function Get-SFStorageControllerRoot {
	param(	
		 )
	process{
		$SSRoot=[ordered]@{	
				'@odata.Copyright'	=	$RedfishCopyright;
				'@odata.type'		=	'#StorageControllerCollection.StorageControllerCollection';
				'@odata.id'			=	'/redfish/v1/Storage/'+$NimbleSerial+'/StorageControllers';
				Name				=	'Storage System Collection';
				Members				=	@( @{	'@odata.id'	=	'/redfish/v1/Storage/'+$NimbleSerial+'/StorageControllers/'+$NimbleSerial+'-A'
											};
										   @{	'@odata.id'	=	'/redfish/v1/Storage/'+$NimbleSerial+'/StorageControllers/'+$NimbleSerial+'-B'
										 	}
										 )	
			 		  }
		Return $SSRoot
	}
}
