function Get-SFZoneRoot {	
	param( 	$ShouldReturnObj=$True
		 )
	$InitiatorGroups = ( Get-NSInitiatorGroup )
	$Members=@()
	# First Populate the the InitiatorGroup list with the TargetEndpointGroup
	# There is 1 Endpoint Group for all of the targets and another for each subnet
	foreach($sub in get-nsSubnet)
	{	if ($Sub.allow_iscsi -like 'True')
		{	# This subnet allows iSCSI, it should become a target group
			$LocalMembers = @{	'@odata.id'		=	'/redfish/v1/Fabrics/'+$NimbleSerial+'/Zones/'+$Sub.name
							 }
			$Members+=$LocalMembers
	}	}
	$LocalMembers = @{	'@odata.id'		=	'/redfish/v1/Fabrics/'+$NimbleSerial+'/Zones/'+$NimbleSerial+'-AllSubnets'
					 }
	$Members+=$LocalMembers
	foreach ($group in $initiatorGroups)
		{	$LocalMembers = @{	'@odata.id'		=	'/redfish/v1/Fabrics/'+$NimbleSerial+'/Zones/'+$group.name
							 }
			$Members+=$LocalMembers
		}
	$EPGRoot = [ordered]@{
					'@Redfish.Copyright'	= 	$RedfishCopyright;
					'@odata.id'				=	'/redfish/v1/Fabrics/'+$NimbleSerial+'/Zones';
					'@odata.type'			=	'#ZonesCollection.ZonesCollection';
					Name					=	'Nimble Initiator Groups (zones)';
					'Members@odata.count'	=	($Members).count;
					Members				=	@( $Members )
			   }
	return $EPGRoot
}	

function Get-SFZone {
	param(	$ZoneName
		 )
	Remove-Variable -name Result 	-ErrorAction SilentlyContinue
	Remove-Variable -name ResultI 	-ErrorAction SilentlyContinue
	Remove-Variable -name ResultT 	-ErrorAction SilentlyContinue
	$ResultI = Get-SFInitiatorZone 	-ZoneName $ZoneName -erroraction SilentlyContinue
	$ResultT = Get-SFTargetZone 	-ZoneName $ZoneName -erroraction SilentlyContinue
	if ($ResultI) { return $ResultI } 
	if ($ResultT) { return $ResultT }
	return
}

function Get-SFInitiatorZone {
	param( 	$ZoneName
		 )
	Process{
		Remove-Variable -name InitG	 		-ErrorAction SilentlyContinue
		Remove-Variable -name InitCol 		-ErrorAction SilentlyContinue
		Remove-Variable -name AccessMaps 	-ErrorAction SilentlyContinue
		Remove-Variable -name EPG 			-ErrorAction SilentlyContinue
		Remove-Variable -name InitG			-ErrorAction SilentlyContinue		
		$StorGP=@()
		$InitG = ( Get-NSInitiatorGroup -name $ZoneName -erroraction SilentlyContinue )
		$InitZone=@()
		write-host "Getting Hosname $ZoneName"
		$AccessMaps = ( Get-NSAccessControlRecord )
		if ( $InitG.iscsi_initiators -eq '')
				{	$InitCol=$InitG.fc_initiators
				} else 
				{	$InitCol=$InitG.iscsi_initiators
				}
		foreach($IndInit in $InitCol)
				{	$InitID=$IndInit.id
					$InitZone+=@{		'@odata.id'	=	'/redfish/v1/Fabrics/'+$NimbleSerial+'/Endpoints/'+$IndInit.id	
				}			    }
		foreach($Map in $AccessMaps)
				{	if($Map.Initiator_Group_id -like $InitG.id)
					{	$StorGP+=@{	'@odata.id'	=	'/redfish/v1/Fabrics/'+$NimbleSerial+'/Connections/'+$Map.id	
				}	}			  }		
		$Zone = [ordered]@{	'@Redfish.Copyright'		= 	$RedfishCopyright;
								'@odata.id'					=	'/redfish/v1/Fabric/'+$NimbleSerial+'/Zones/'+$ZoneName;
								'@odata.type'				=	'#Zones.v1_4_0.Zones';
								Name						=	$ZoneName;
								Description					=	'Initiator EndpointGroup (Zone) for '+$ZoneName;
								GroupType					=	"Client";
								'Endpoints@odata.count'		=	$InitZone.count;
								'Connections@odata.count'	=	$StorGP.count	
								Endpoints					=	@( $InitZone );
								Connections					=	@( $StorGP );
							}
		if ($InitG)
			{	return $Zone
			} else 
			{ 	return	
			}
	}
}

function Get-SFTargetZone {
	param( 	$ZoneName	
		 )
	# $AccessMaps = ( Get-NSAccessControlRecord )
	if ($ZoneName -like $NimbleSerial+'-AllSubnets') 
	{	return (Get-SFTargetZoneAllSubnets)
	} else
	{	$Subnet = ( Get-NSSubnet -name $ZoneName )
		$TargEP=@()
		$StorGP=@()
		$Active=(get-nsNetworkConfig) | where {$_.name -like 'active'}
		$NicList=$active.array_list.nic_list
		foreach($nic in $NicList)
			{	if ( ( $Subnet.name -like $nic.subnet_label ) )
				{	$TargEP+=@{	'@odata.id'	= 	'/redfish/v1/Fabrics/'+$NimbleSerial+'/Endpoints/'+$active.role+'-'+$nic.name	
						      }
				}
			}
		$InitiatorGroups = ( Get-NSInitiatorGroup | where{ $_.target_subnets } )
		foreach($initgroup in $InitiatorGroups )
		{	foreach( $TargSub in $initgroup.target_subnets )
			{	if( $TargSub.label -like $ZoneName )
					{	# This initiatorgroup uses this specific subnet. now search for all accessmaps that used this initiatorgroup
						foreach( $map in ( Get-NSAccessControlRecord ) )
						{	if ( ( $map.initiator_group_id -like $initgroup.id ) )
							{	# found one
								$StorGP+=@{'@odata.id'	= 	'/redfish/v1/Fabrics/'+$NimbleSerial+'/Connections/'+$map.id
										  }
		}	}		}	}	}
		$EPG = [ordered]@{	'@Redfish.Copyright'	= 	$RedfishCopyright;
							'@odata.id'				=	'/redfish/v1/Fabrics/'+$NimbleSerial+'/Zones/'+$ZoneName;
							'@odata.type'			=	'#Zones.v1_4_0.Zones';
							Name					=	$ZoneName;
							id						=	$subnet.id;
							Description				=	'Target EndpointGroup (Zone) for subnet named '+$ZoneName;
							GroupType				=	"Target";
							'Endpoints@odata.count'	=	$TargEP.count;
							'Connections@odata.count'=	$StorGP.count;	
							Endpoints				=	@( $TargEP );
							Connections				=	@( $StorGP );
						}
		if ( ($Subnet.name -like $ZoneName) )
				{	return $EPG
				}
		}
}	

function Get-SFTargetZoneAllSubnets {
	param( 		
		 )
	foreach($subnet in ( Get-NSSubnet ) )
	{	$TargEP=@()
		$StorGP=@()
		$Active=(get-nsNetworkConfig) | where {$_.name -like 'active'}
		$NicList=$active.array_list.nic_list
		foreach($nic in $NicList)
		{	if ( ( $Subnet.name -like $nic.subnet_label ) -or ( $ZoneName -eq $NimbleSerial+"-AllSubnets") )
			{	$TargEP+=@{	'@odata.id'	= 	'/redfish/v1/Fabrics/'+$NimbleSerial+'/Endpoints/'+$active.role+'-'+$nic.name	
	} 	}	}			  }
	foreach( $initgroup in (Get-NSInitiatorGroup) )
		{	if ( $initgroup.target_subnets -like '' )
				{	foreach( $map in ( Get-NSAccessControlRecord ) )
						{	if ( ( $map.initiator_group_id -like $Initgroup.id ) )
								{	$StorGP+=@{'@odata.id'	= 	'/redfish/v1/Fabrics/'+$NimbleSerial+'/Connections/'+$map.id
										  	  }
		}		}		}		}
	$EPG = [ordered]@{	'@Redfish.Copyright'	= 	$RedfishCopyright;
						'@odata.id'				=	'/redfish/v1/Fabrics/'+$NimbleSerial+'/Zones/'+$ZoneName;
						'@odata.type'			=	'#Zones.v1_4_0.Zones';
						Name					=	$ZoneName;
						id						=	1;
						Description				=	'Target EndpointGroup (Zone) for subnet named '+$ZoneName;
						GroupType				=	"Target";
						'Endpoints@odata.count'	=	$TargEP.count;
						'Connections@odata.count'=	$StorGP.count;	
						Endpoints				=	@( $TargEP );
						Connections				=	@( $StorGP );
			 		 }
		return $EPG
}	