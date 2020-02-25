function Get-SFStorageGroupRoot {	
param( 	
	 )
process{
	$Members=@()
	$AccessControlMaps = ( Get-NSAccessControlRecord )
	foreach ($Map in $AccessControlMaps)
		{	$LocalMembers = @( @{	'@odata.id'		=	'/redfish/v1/StorageSystems/'+$NimbleSerial+'/StorageGroups/'+$Map.id
                                }
                             )
			$Members+=$localMembers
		}
	$SGRoot = @{	'@Redfish.Copyright'	= 	$RedfishCopyright;
					'@odata.context'		=	'/redfish/v1/$metadata#StorageGroup/'+$NimbleSerial+'/StorageGroups';
					'@odata.id'				=	'/redfish/v1/StorageSystems/'+$NimbleSerial+'/StorageGroups';
					'@odata.type'			=	'#StorageGroups_1_4_0.StorageGroups';
					Name					=	'Nimble Storage Groups (Access Control Maps)';
					'Members@odata.count'	=	($AccessControlMaps).count;
					Members					=	@( $Members )
			   }
	return $SGRoot
}
}
		
function Get-SFStorageGroup {
param( 	$AccessControlname
	 )
process{
	$Map = ( Get-NSAccessControlRecord -id $AccessControlName )
	$ServerEPG=@()
	$SG=@()
    if ( $Map.Chap_user )
        {   $AuthMethod = 'CHAP'
        } else
        {   $AuthMethod = 'None'
		}
	$IG = $Map.initiator_group_id
	if ($IG)
		{	$IGroup = Get-nsInitiatorGroup -id $IG
		} else 
		{ 	$Igroup = ''
		}				
	if ( -not $IGroup.target_subnets -and $IGroup)
		{	$ServerEPG += @{ 	'@odata.id'	= 	$NimbleSerial+'_AllSubnets'	}
		}
    $SG = @{	'@Redfish.Copyright'    = 	$RedfishCopyright;
				'@odata.context'        =	'/redfish/v1/$metadata#StorageGroup/'+$NimbleSerial+'/StorageGroup';
				'@odata.id'             =	'/redfish/v1/StorageSystems/'+$NimbleSerial+'/StorageGroups/'+$Map.id;
				'@odata.type'           =	'#StorageGroup.v1_3_1.StorageGroup';
				Name                    =	$Map.id;
                Description             =	'Storage Access Control Group connecting Endpoints to Volumes';
                'ClientEndpointGroups@odata.count'	=	1;	
				ClientEndpointGroups    =	@(	@{ 	'@odata.id' 		=	$Map.Initiator_Group_id 
												 }
											 ); 
				ServerEndpointGroups	=	@( $ServerEPG
											 );
                AuthenticationMethod    =   $AuthMethod;
                CHAPInformation         =   @{  InitiatorCHAPUser   =   $Map.Chap_user_name
                                             };
                MappedVolumes           =   @( @{   LogicalUnitNumber   =   $Map.lun;
                                                    Volume              =   '/redfish/v1/StorageServices/'+$NimbleSerial+'/Volumes/'+$Map.vol_name;  
                                                }
                                             );
                Id                      =   $map.id
		   }
	return $SG 
}
}