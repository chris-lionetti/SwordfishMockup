function Get-SFEndpointGroupRoot {	
	param( 	$ShouldReturnObj=$True
		 )
	$InitiatorGroups = ( Get-NSInitiatorGroup )
	$Members=@()
	# First Populate the the InitiatorGroup list with the TargetEndpointGroup
	# There is 1 Endpoint Group for all of the targets and another for each subnet
	foreach($sub in get-nsSubnet)
	{	if ($Sub.allow_iscsi -like 'True')
		{	# This subnet allows iSCSI, it should become a target group
			$LocalMembers = @{	'@odata.id'		=	'/redfish/v1/Storage/'+$NimbleSerial+'/EndpointGroups/'+$Sub.name
							 }
			$Members+=$localMembers
	}	}
	$LocalMembers = @{	'@odata,id'		=	'/redfish/v1/Storage/'+$NimbleSerial+'/EndpointGroups/'+$NimbleSerial+'_AllSubnets'
					 }
	$Members+=$localMembers
	foreach ($group in $initiatorGroups)
		{	$LocalMembers = @{	'@odata.id'		=	'/redfish/v1/Storage/'+$NimbleSerial+'/EndpointGroups/'+$group.name
							 }
			$Members+=$localMembers
		}
	$EPGRoot = [ordered]@{
					'@Redfish.Copyright'	= 	$RedfishCopyright;
					'@odata.id'				=	'/redfish/v1/Storage/'+$NimbleSerial+'/EndpointGroups';
					'@odata.type'			=	'#EndpointGroupCollection.EndpointGroupCollection';
					Name					=	'Nimble Endpoint Groups';
					'Members@odata.count'	=	($Members).count;
					Members					=	@( $Members )
			   }
	return $EPGRoot
}	

function Get-SFEndpointGroup {
	param(	$EndpointGroupName
		 )
	$result=''
	$Result1 = Get-SFInitiatorEndpointGroup -EndpointGroupName $EndpointGroupName -erroraction SilentlyContinue
	$Result2 = Get-SFTargetEndpointGroup 	-EndpointGroupName $EndpointGroupName -erroraction SilentlyContinue
	if ($result1) { $result = $result1 } else { $result=$result2 }
	return $result
}

function Get-SFInitiatorEndpointGroup {
	param( 	$EndpointGroupName
		 )
	$InitG = ( Get-NSInitiatorGroup -name $EndpointGroupName -erroraction SilentlyContinue )
	write-host "Getting Hosname $EndpointGroupName"
	$AccessMaps = ( Get-NSAccessControlRecord )
	$InitEP=@()
	$StorGP=@()
	if ( $InitG.iscsi_initiators -eq '')
			{	$InitCol=$InitG.fc_initiators
			} else 
			{	$InitCol=$InitG.iscsi_initiators
			}
	foreach($IndInit in $InitCol)
			{	$InitID=$IndInit.id
				$InitEP+=@{		'@odata.id'	=	'/redfish/v1/Fabric/'+$NimbleSerial+'/Endpoints/'+$IndInit.id	
			}			  }
	foreach($Map in $AccessMaps)
			{	if($Map.Initiator_Group_id -like $InitG.id)
				{	$StorGP+=@{	'@odata.id'	=	'/redfish/v1/Storage/'+$NimbleSerial+'/StorageGroups/'+$Map.id	
			}	}			 }		
		$EPG = [ordered]@{	'@Redfish.Copyright'	= 	$RedfishCopyright;
							'@odata.id'				=	'/redfish/v1/Storage/'+$NimbleSerial+'/EndpointGroups/'+$InitG.name;
							'@odata.type'			=	'#EndpointGroup.v1_2_0.EndpointGroup';
							Name					=	$InitG.name;
							Description				=	'Initiator EndpointGroup for '+$InitG.name;
							GroupType				=	"Client";
							'Endpoints@odata.count'	=	$InitEP.count;
							'StorageGroups@odata.count'	=	$StorGP.count	
							Endpoints				=	@( $InitEP );
							StorageGroups			=	@( $StorGP );
						}
	return $EPG
}

function Get-SFTargetEndpointGroup {
	param( 	$EndpointGroupName	
		 )
	$InitiatorGroups = ( Get-NSInitiatorGroup )
	$AccessMaps = ( Get-NSAccessControlRecord )
	$Subnets = ( Get-NSSubnet )
	foreach($sub in $subnets)
	{	$TargEP=@()
		$StorGP=@()
		$Active=(get-nsNetworkConfig) | where {$_.name -like 'active'}
		$NicList=$active.array_list.nic_list
		foreach($nic in $NicList)
		{	if ($Sub.name -like $nic.subnet_label)
			{	$TargEP+=@{	'@odata.id'	= 	'/redfish/v1/Fabrics/'+$NimbleSerial+'/Endpoints/'+$active.role+'_'+$nic.name	
						  }
			}
		}
		# Now I need to find the accesscontrolrecords for each volume, and then detect the initiator groups to find the allowed subnets
		# I also want to ignore any initiatorGroup that is set to all, only if this initiator group explicitly specified
		# step 1----find any initiatorgroup that uses THIS subnet specifically
		foreach($initgroup in $InitiatorGroups)
		{	foreach($TargSub in $initgroup.target_subnets)
			{	if($TargSub.label -like $sub.name )
					{	# This initiatorgroup uses this specific subnet. now search for all accessmaps that used this initiatorgroup
						foreach($map in $accessMaps)
						{	if ($map.initiator_group_id -like $initgroup.id)
							{	# found one
								$StorGP+=@{'@odata.id'	= 	'/redfish/v1/Storage/'+$NimbleSerial+'/StorageGroups/'+$map.id
										  }
		}	}		}	}	}
		$EPG = [ordered]@{	'@Redfish.Copyright'	= 	$RedfishCopyright;
							'@odata.id'				=	'/redfish/v1/Storage/'+$NimbleSerial+'/EndpointGroups/'+$sub.name;
							'@odata.type'			=	'#EndpointGroup.v1_2_0.EndpointGroup';
							Name					=	$sub.name;
							id						=	$sub.id
							Description				=	'Target EndpointGroup for subnet named '+$sub.name;
							GroupType				=	"Server";
							'Endpoints@odata.count'	=	$TargEP.count;
							'StorageGroups@odata.count'	=	$StorGP.count	
							Endpoints				=	@( $TargEP );
							StorageGroups			=	@( $StorGP );
						}
		if ( $Sub.name -like $EndpointGroupName )
				{	return $EPG
				}
	}
	# This code creates the ALL_Group
	$TargEPG=@()
	$StorGP=@()
	foreach($InitGroup in $InitiatorGroups)
	{	if ( -not $InitGroup.target_subnets)
		{	# none specified, so belongs to the 'all' group
			foreach($map in $accessmaps)
			{	if($Map.initiator_group_id -like $InitGroup.id)
				{	#found a match
					$StorGP+=@{'@odata.id'	= 	'/redfish/v1/Storage/'+$NimbleSerial+'/StorageGroups/'+$map.id
							  }
				}
			}
		}
	}
	foreach($sub in $subnets)
	{	$TargEPG+=@{	'@odata.id'	=	'/redfish/v1/Storage/'+$NimbleSerial+'/EndpointGroups/'+$sub.name
				   }
	}
	$EPG = [ordered]@{	'@Redfish.Copyright'	= 	$RedfishCopyright;
						'@odata.id'				=	'/redfish/v1/Storage/'+$NimbleSerial+'/EndpointGroups/'+$NimbleSerial+'_AllSubnets';
						'@odata.type'			=	'#EndpointGroup.v1.2.0.EndpointGroup';
						Name					=	$NimbleSerial+'_AllSubnets';
						Description				=	'Target Group Default, collection of all Target Endpoint Groups';
						GroupType				=	"server";
						'members@odata.count'	=	$TargEPG.count;
						'StorageGroups@odata.count'	=	$StorGP.count	
						Members					=	@( $TargEPG );
						StorageGroups			=	@( $StorGP );
					 }
	if ( ($NimbleSerial+'_AllSubnets') -like $EndpointGroupName )
		{	return $EPG
		}
}