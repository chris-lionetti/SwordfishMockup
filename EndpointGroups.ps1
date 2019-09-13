function Create-EndpointGroupRootiSCSI {	
	param( 	$initiatorGroups
		 )
	$Members=@()
	# First Populate the the InitiatorGroup list with the TargetEndpointGroup
	# There is 1 Endpoint Group for all of the targets and another for each subnet
	foreach($sub in get-nsSubnet)
	{	if ($Sub.allow_iscsi -like 'True')
		{	# This subnet allows iSCSI, it should become a target group
			$LocalMembers = @{	'@odata,id'		=	'/redfish/v1/StorageServices/'+$NimbleSerial+'/EndpointGroups/'+$Sub.name
							 }
			$Members+=$localMembers
	}	}
	$LocalMembers = @{	'@odata,id'		=	'/redfish/v1/StorageServices/'+$NimbleSerial+'/EndpointGroups/'+$NimbleSerial+'_AllSubnets'
					 }
	$Members+=$localMembers
	foreach ($group in $initiatorgroups)
		{	$LocalMembers = @{	'@odata,id'		=	'/redfish/v1/StorageServices/'+$NimbleSerial+'/EndpointGroups/'+$Group.name
							 }
			$Members+=$localMembers
		}
	$EPGRoot = @{	'@Redfish.Copyright'	= 	$RedfishCopyright;
					'@odata.context'		=	'/redfish/v1/$metadata#EndpointGroup/'+$NimbleSerial+'/EndpointGroups';
					'@odata.id'				=	'/redfish/v1/StorageServices/'+$NimbleSerial+'/EndpointGroups';
					'@odata.type'			=	'#EndpointGroups_1_4_0.EndpointGroups';
					Name					=	'Nimble Endpoint Groups';
					'Members@odata.count'	=	($Members).count;
					Members					=	@( $Members )
			   }
	FolderAndFile $EPGRoot  ("\StorageServices\"+$NimbleSerial+"\EndpointGroups\")
}
		

function Create-InitiatorEndpointGroupsIndex {
	param( 	$InitiatorGroups,
			$AccessMaps
		 )
	foreach($InitG in $InitiatorGroups)
	{	$InitEP=@()
		$StorGP=@()
		if ( $InitG.iscsi_initiators -eq '')
			{	$InitCol=$InitG.fc_initiators
			} else 
			{	$InitCol=$InitG.iscsi_initiators
			}
		foreach($IndInit in $InitCol)
			{	$InitID=$IndInit.id
				$InitEP+=@{		'@odata.id'	=	'/redfish/v1/StorageServices/'+$NimbleSerial+'/Endpoints/'+$IndInit.id	
			}			  }
		foreach($Map in $AccessMaps)
			{	if($Map.Initiator_Group_id -like $InitG.id)
				{	$StorGP+=@{	'@odata.id'	=	'/redfish/v1/StorageServices/'+$NimbleSerial+'/StorageGroups/'+$Map.id	
			}	}			 }		
		$EPG = @{	'@Redfish.Copyright'	= 	$RedfishCopyright;
					'@odata.context'		=	'/redfish/v1/$metadata#EndpointGroup/'+$NimbleSerial+'/EndpointGroup';
					'@odata.id'				=	'/redfish/v1/StorageServices/'+$NimbleSerial+'/EndpointGroups/'+$InitG.name;
					'@odata.type'			=	'#EndpointGroup.v1_3_1.EndpointGroup';
					Name					=	$InitG.name;
					Description				=	'Initiator EndpointGroup for '+$InitG.name;
					GroupType				=	"client";
					'Endpoints@odata.count'	=	$InitEP.count;
					'StorageGroups@odata.count'	=	$StorGP.count	
					Endpoints				=	@( $InitEP );
					StorageGroups			=	@( $StorGP );
				}
		FolderAndFile $EPG ("StorageServices\"+$NimbleSerial+"\EndpointGroups\"+$InitG.name)
	}
}

function Create-TargetEndpointGroupsIndex {
	param( 	$InitiatorGroups,
			$AccessMaps,
			$subnets
		 )
	foreach($sub in $subnets)
	{	$TargEP=@()
		$StorGP=@()
		$Active=(get-nsNetworkConfig) | where {$_.name -like 'active'}
		$NicList=$active.array_list.nic_list
		foreach($nic in $NicList)
		{	if ($Sub.name -like $nic.subnet_label)
			{	$TargEP+=@{	'@odata.id'	= 	'/redfish/v1/StorageServices/'+$NimbleSerial+'/Endpoints/'+$active.role+'_'+$nic.name	
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
								$StorGP+=@{'@odata.id'	= 	'/redfish/v1/StorageServices/'+$NimbleSerial+'/StorageGroups/'+$map.id
										  }
		}	}		}	}	}
		$EPG = @{	'@Redfish.Copyright'	= 	$RedfishCopyright;
					'@odata.context'		=	'/redfish/v1/$metadata#EndpointGroup/'+$NimbleSerial+'/EndpointGroup';
					'@odata.id'				=	'/redfish/v1/StorageServices/'+$NimbleSerial+'/EndpointGroups/'+$sub.name;
					'@odata.type'			=	'#EndpointGroup.v1_3_1.EndpointGroup';
					Name					=	$sub.name;
					id						=	$sub.id
					Description				=	'Target EndpointGroup for subnet named '+$sub.name;
					GroupType				=	"server";
					'Endpoints@odata.count'	=	$TargEP.count;
					'StorageGroups@odata.count'	=	$StorGP.count	
					Endpoints				=	@( $TargEP );
					StorageGroups			=	@( $StorGP );
				}
		FolderAndFile $EPG ("StorageServices\"+$NimbleSerial+"\EndpointGroups\"+$Sub.name)
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
					$StorGP+=@{'@odata.id'	= 	'/redfish/v1/StorageServices/'+$NimbleSerial+'/StorageGroups/'+$map.id
							  }
				}
			}
		}
	}
	foreach($sub in $subnets)
	{	$TargEPG+=@{	'@odata.id'	=	'/redfish/v1/StorageServices/'+$NimbleSerial+'/EndpointGroups/'+$sub.name
				   }
	}
	$EPG = @{	'@Redfish.Copyright'	= 	$RedfishCopyright;
				'@odata.context'		=	'/redfish/v1/$metadata#EndpointGroupCollection/'+$NimbleSerial+'/EndpointGroup';
				'@odata.id'				=	'/redfish/v1/StorageServices/'+$NimbleSerial+'/EndpointGroups/'+$NimbleSerial+'_AllSubnets';
				'@odata.type'			=	'#EndpointGroupCollection.v1_3_1.EndpointGroupCollection';
				Name					=	$NimbleSerial+'_AllSubnets';
				Description				=	'Target Group Default, collection of all Target Endpoint Groups';
				GroupType				=	"server";
				'members@odata.count'	=	$TargEPG.count;
				'StorageGroups@odata.count'	=	$StorGP.count	
				Members					=	@( $TargEPG );
				StorageGroups			=	@( $StorGP );
			}
	FolderAndFile $EPG ("StorageServices\"+$NimbleSerial+"\EndpointGroups\"+$NimbleSerial+'_AllSubnets')
}

	


