function Get-SFStorageGroupRoot {	
param( 	
	 )
process{
	$Members=@()
	$AccessControlMaps = ( Get-NSAccessControlRecord )
	foreach ($Map in $AccessControlMaps)
		{	$LocalMembers = @( @{	'@odata.id'		=	'/redfish/v1/Fabrics/'+$NimbleSerial+'/Connections/'+$Map.id
                                }
                             )
			$Members+=$localMembers
		}
	$SGRoot = @{	'@Redfish.Copyright'	= 	$RedfishCopyright;
					'@odata.id'				=	'/redfish/v1/Fabrics/'+$NimbleSerial+'/Connections';
					'@odata.type'			=	'#ConnectionsCollection.ConnectionsCollection';
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
		{	$ServerEPG += @{ 	'@odata.id'	= 	'/redfish/v1/Fabrics/'+$NimbleSerial+'/Zones/'+$NimbleSerial+'_AllSubnets'	}
		}
    $SG = [ordered]@{	
				'@Redfish.Copyright'    = 	$RedfishCopyright;
				'@odata.id'             =	'/redfish/v1/Fabrics/'+$NimbleSerial+'/Connections/'+$Map.id;
				'@odata.type'           =	'#Connections.v1_0_0.Connections';
				Name                    =	$Map.id;
                Description             =	'Access Control Group connecting Endpoints to Volumes';
                'ClientEndpointGroups@odata.count'	=	1;	
				Zones    				=	@(	@{ 	'@odata.id' 	=	'/redfish/v1/Fabrics/'+$NimbleSerial+'/Zones/'+$Map.Initiator_Group_id 		};
												$ServerEPG
											 ); 
                Volumes           		=   @( @{   LogicalUnitNumber   =   $Map.lun;
                                            		Volume              =   '/redfish/v1/Storage/'+$NimbleSerial+'/StoragePools/Default/Volumes/'+$Map.vol_name;  
                                                }
                                             );
                Id                      =   $map.id
		   }
	if ($Map.Chap_User)
		{	$SG+=@{	AuthenticationMethod    =   $AuthMethod;
					CHAPInformation         =   @{  CHAPUser   		= $Map.Chap_user_name;
													CHAPPassword	= $null
								 				 };
				  }
				}	
	return $SG 
}
}