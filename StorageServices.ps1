function Create-ServiceRootIndex {
	param()
	$ServicesRoot=@{	'@odata.type'		=	'#ServiceRoot.v1_0_2.ServiceRoot';
						'@odata.Copyright'	=	$RedfishCopyright;
						'@odata.context'	=	'/redfish/v1/$metadata#ServiceRoot';
						'@odata.id'			=	'/redfish/v1';
						RedfishVersion		=	'1.0.2';
						AccountService		=	@{	'@odata.id'	=	'/redfish/v1/AccountServices'	};
						Chassis				=	@{	'@odata.id'	=	'/redfish/v1/Chassis'			};
						EventService		=	@{	'@odata.id'	=	'/redfish/v1/EventServices'		};
						Managers			=	@{	'@odata.id'	=	'/redfish/v1/Managers'			};
						SessionService		=	@{	'@odata.id'	=	'/redfish/v1/SessionServices'	};
						Systems				=	@{	'@odata.id'	=	'/redfish/v1/Systems'			};
						TaskService			=	@{	'@odata.id'	=	'/redfish/v1/TaskServices'		};
						StorageServices		=	@{	'@odata.id'	=	'/redfish/v1/StorageServices'	};
						StorageSystems		=	@{	'@odata.id'	=	'/redfish/v1/StorageSystems'	};
					}
	FolderAndFile -FolderNames @("AccountServices","Chassis","EventServices","Managers","SessionServices","Systems","TaskServices","StorageServices","StorageSystems")
	FolderAndFile -OutputText $ServicesRoot -FolderNames('')
}

function Create-StorageServices {
	param(	$array
		 )
	$SSRoot=@{	'@odata.type'		=	'#StorageServiceCollection.1.0.0.StorageServiceCollection';
				'@odata.Copyright'	=	$RedfishCopyright;
				'@odata.context'	=	'/redfish/v1/$metadata#StorageService.StorageService';
				'@odata.id'			=	'/redfish/v1/StorageSystems';
				Name				=	'Storage Service Collection';
				Members				=	@( @{	'@odata.id'	=	'/redfish/v1/StorageServices/'+$NimbleSerial
										 	}
										 )	
			 }
	FolderAndFile $SSRoot ("StorageServices")
}

function Create-StorageServicesArray {
	param(	$Array
		 )
	$SSA=@{		'@odata.type'		=	'#StorageServiceCollection.1.0.0.StorageServiceCollection';
				'@odata.Copyright'	=	$RedfishCopyright;
				'@odata.context'	=	'/redfish/v1/$metadata#StorageService.StorageService'+$NimbleSerial;
				'@odata.id'			=	'/redfish/v1/StorageServices/'+$NimbleSerial;
				Name				=	$Array.name;
				Id					=	$Array.id;
				Description			=	$Array.description;
				Status				=	@{	State 	=	'Enabled';
											Health	=	'OK'
										};
				Drives				=	'/redfish/v1/Chassis/'+$NimbleSerial+'/drives';
				Chassis				=	'/redfish/v1/Chassis/'+$NimbleSerial;
				Endpoints			=	'/redfish/v1/StorageServices/'+$NimbleSerial+'/Endpoints';
				EndpointGroups		=	'/redfish/v1/StorageServices/'+$NimbleSerial+'/EndpointGroups';
				ConsistencyGroups	=	'/redfish/v1/StorageServices/'+$NimbleSerial+'/ConsistencyGroups';
				StorageGroups		=	'/redfish/v1/StorageServices/'+$NimbleSerial+'/StorageGroups';
				StoragePools		=	'/redfish/v1/StorageServices/'+$NimbleSerial+'/StoragePools';
				Volumes				=	'/redfish/v1/StorageServices/'+$NimbleSerial+'/Volumes';
		  }
	FolderAndFile $SSA ("\StorageServices\"+$NimbleSerial+"\")
}

