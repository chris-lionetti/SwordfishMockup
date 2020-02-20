function Get-SFConsistencyGroupRoot {	
param()
process{
	$Members=@()
	$VolCols = (Get-NSVolumeCollection)
	foreach ($VolCol in $VolCols)
		{	$LocalMembers = @( @{	'@odata,id'		=	'/redfish/v1/StorageSystems/'+$NimbleSerial+'/ConsistencyGroups/'+($VolCol.name)
                                }
                             )
			$Members+=$localMembers
		}
	$CGRoot = [ordered]@{
					'@Redfish.Copyright'	= 	$RedfishCopyright;
					'@odata.context'		=	'/redfish/v1/$metadata#ConsistencyGroup/'+$NimbleSerial+'/ConsistencyGroups';
					'@odata.id'				=	'/redfish/v1/StorageSystems/'+$NimbleSerial+'/ConsistencyGroups';
					'@odata.type'			=	'#ConsistencyGroup.v1_0_1.ConsistencyGroup';
					Name					=	'Nimble Volume Collection (Consistency Groups)';
					'Members@odata.count'	=	($VolCols).count;
					Members					=	@( $Members )
			   		   }
	return $CGRoot
}
}
		
function Get-SFConsistencyGroup{
param( 	$VolColName
	 )
process{
	$VolCol = ( Get-NSVolumeCollection -name $VolColName )
	$Vols=@()
	foreach ($Vol in ($VolCol.Volume_List) )
		{	$Vols += @{ 	'@odata.id'	=  	'/redfish/v1/StorageServices/'+$NimbleSerial+'/Volumes/'+($Vol.vol_name) }		
		}
	$CGDPLOS=@()
	foreach ($SL in ($VolCol.schedule_list) )
		{	$CGDPLOS+= @{		'@odata.id'	=  	'/redfish/v1/StorageServices/'+$NimbleSerial+'/LineOfService/DataProtectionLineOfService/'+($SL.id) }
		}		
	if ( $VolCol.is_handing_over -eq 'False' )
		{	$IsConsistent = $True
		} else 
		{	$IsConsistent = $False			
		}
	switch($VolCol.app_sync)
		{	'none'		{	$AppSync = "other"	}	
			'vss'		{	$AppSync = "vss"	}
			'vmware'	{	$AppSync = "vasa"	}
			'generic'	{	$AppSync = "other"	}
		}
	if ($VolCol.protection_type -like 'local')
		{	$ReplicaType = 'snapshot' 
		} else 
		{	$ReplicaType = 'mirror'	
		}
	$CG=@()
    $CG = [ordered]@{
				'@Redfish.Copyright'    = 	$RedfishCopyright;
				'@odata.context'        =	'/redfish/v1/$metadata#StorageSystems/'+$NimbleSerial+'/ConsistencyGroup';
				'@odata.id'             =	'/redfish/v1/StorageSystems/'+$NimbleSerial+'/ConsistencyGroups/'+($VolCol.Name);
				'@odata.type'           =	'#ConsistencyGroup.v1_0_1.ConsistencyGroup';
				Name                    =	($VolCol.name);
				Id						=	($VolCol.id);
                Description             =	'Volume Collection (used as a Consistency Group)';
				'Volumes@odata.count'	=	($VolCol.volume_count);
				ConsistencyMethod		=	($AppSync);
				ConsistencyType			=	($VolCol.app_sync);
				IsConsistent			=	($IsConsistent);
				Status					=	'Ok';
				ReplicaInfo				=	($VolCol.replication_partner);
				ReplicaType				=	($ReplicaType);
				Volumes           		=   ($Vols);
				DataProtectonLineOfService=	($CGDPLOS)
		   		  }
	return $CG 
}
}