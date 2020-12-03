


function Get-SFController {
	param(	$ControllerName
	 	 )
	process{
		$MyArray 	= Get-NSArray
		$Controller	= Get-NSController | where { $_.name -like $ControllerName }
		$MyGroup	= Get-NSGroup
		$FirmwareVersion = (Get-NSGroup).version_current
		if ( $Controller.state -like 'standby' )
			{	$ControllerState = 'StandbyOffline'
			} else
			{	$ControllerState = 'Enabled'
			}
		$CtrlA = Get-NSController | where {$_.name -like 'A'}
		$CtrlB = Get-NSController | where {$_.name -like 'B'}
		$OverallState = 'Warning'
		if ( $CtrlA.state -like 'standby' -or $CtrlA.state -like 'active' )
			{	if ( $CtrlB.state -like 'standby' -or $CtrlB.state -like 'active' )
					{ $OverallState = 'OK'
					}
			}
		$SSA=[ordered]@{
				'@odata.Copyright'			=	$RedfishCopyright;
				'@odata.type'				=	'#Storage.v1_8_1.Storage';
				'@odata.id'					=	'/redfish/v1/Storage/'+$NimbleSerial+'/StorageControllers/'+$NimbleSerial+'-'+$ControllerName;
				Name						=	$Controller.hostname;
				Id							=	$Controller.id;
				MemberId					=	$Controller.name;
				Model						=	$MyArray.model;
				PartNumber					=	$MyArray.extended_model;
				Location					=	$MyGroup.snmp_sys_location;
				SerialNumber				=	$Controller.serial
				Description					=	'Controller '+$NimbleSerial+' controller '+$controllerName;
				Status						=	@{	State 	=	$ControllerState;
													Health	=	'OK'
												};
				Manufacturer				=	'HPE Nimble Storage';
				FirmwareVersion				=	$MyGroup.version_current;
				SupportedRAIDTypes			=	'RAID6TP'
				Redundancy					=	@{ 	MaxNumSupported	=	2;
													MemberId		=	$Controller.name;
													MinNumNeeded	=	1;
													Mode			=	'Failover';
													RedundancySet	=	@(	@{	'@odata.id'	=	'/redfish/v1/Storage/'+$NimbleSerial+'/StorageControllers/A'	
																			 };
																			@{	'@odata.id'	=	'/redfish/v1/Storage/'+$NimbleSerial+'/StorageControllers/B'	
																			 }
																		 )
													RedundancyEndabled = $True;
													Status			=	$OverallState
												 }
				}
				
		if ($ControllerName -like $Controller.name) 
			{	Return $SSA
			}
	}
	<#	CacheSummary	PersistentCacheSizeMiB
						Status
						TotalCacheSize
		ControllerRates	ConsstencyCheckRatePercent
						RebuildRatePercent
						TransformationRatePercent
		links			Endpoints
				PCIeFunctions
				StorageServices []
		Ports 
		SupportedControllerProtocols[]
		SupportedDeviceProtocols[]
		StorageGroups-->Connections[]
		StoragePools
		Volumes
	#>
}

function Get-SFControllerRoot {
	param(	
		 )
	process{
		$SSRoot=[ordered]@{	
				'@odata.Copyright'	=	$RedfishCopyright;
				'@odata.type'		=	'#StorageControllerCollection.StorageControllerCollection';
				'@odata.id'			=	'/redfish/v1/Storage/'+$NimbleSerial+'/StorageControllers';
				Name				=	'Storage System Collection';
				Members				=	@( @{	'@odata.id'	=	'/redfish/v1/Storage/'+$NimbleSerial+'/StorageControllers/A'
											};
										   @{	'@odata.id'	=	'/redfish/v1/Storage/'+$NimbleSerial+'/StorageControllers/B'
										 	}
										 )	
			 		  }
		Return $SSRoot
	}
}
