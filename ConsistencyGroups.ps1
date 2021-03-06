function Get-SFConsistencyGroupRoot {	
param()
process{
	$Members=@()
	$VolCols = (Get-NSVolumeCollection)
	foreach ($VolCol in $VolCols)
		{	$LocalMembers = @( @{	'@odata.id'		=	'/redfish/v1/Storage/'+$NimbleSerial+'/ConsistencyGroups/'+($VolCol.name)
                                }
                             )
			$Members+=$localMembers
		}
	$CGRoot = [ordered]@{	'@Redfish.Copyright'	= 	$RedfishCopyright;
							'@odata.id'				=	'/redfish/v1/Storage/'+$NimbleSerial+'/ConsistencyGroups';
							'@odata.type'			=	'#ConsistencyGroupCollection.ConsistencyGroupCollection';
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
		{	$Vols += @{ 	'@odata.id'	=  	'/redfish/v1/Storage/'+$NimbleSerial+'/Volumes/'+($Vol.vol_name) }		
		}
	$CGDPLOS=@()
	foreach ($SL in ($VolCol.schedule_list) )
		{	$CGDPLOS+= @{		'@odata.id'	=  	'/redfish/v1/Storage/'+$NimbleSerial+'/LineOfService/DataProtectionLineOfService/'+($SL.id) }
		}		
	if ( $VolCol.is_handing_over -eq 'False' )
		{	$IsConsistent = $True
		} else 
		{	$IsConsistent = $False			
		}
	switch($VolCol.app_sync)
		{	'none'		{	$AppSync = "Other"	
							$ConType = "CrashConsistent"
						}	
			'vss'		{	$AppSync = "VSS"	
							$ConType = "ApplicationConsistent"
						}
			'vmware'	{	$AppSync = "VASA"	
							$ConType = "ApplicationConsistent"
						}
			'generic'	{	$AppSync = "Other"	
							$ConType = "CrashConsistent"
						}
		}
	if ($VolCol.protection_type -like 'local')
		{	$ReplicaType = 'snapshot' 
		} else 
		{	$ReplicaType = 'mirror'	
		}
	$CG=@()
    $CG = [ordered]@{
				'@Redfish.Copyright'    = 	$RedfishCopyright;
				'@odata.id'             =	'/redfish/v1/Storage/'+$NimbleSerial+'/ConsistencyGroups/'+($VolCol.Name);
				'@odata.type'           =	'#ConsistencyGroup.v1_0_1.ConsistencyGroup';
				Name                    =	($VolCol.name);
				Id						=	($VolCol.id);
                Description             =	'Volume Collection (used as a Consistency Group)';
				ConsistencyMethod		=	$AppSync;
				ConsistencyType			=	$ConType;
				IsConsistent			=	($IsConsistent);
				Status					=	'OK';
				ReplicaInfo				=	($VolCol.replication_partner);
				ReplicaType				=	($ReplicaType);
				Volumes           		=   ($Vols);
				DataProtectonLineOfService=	($CGDPLOS)
		   		  }
	return $CG 
}
}