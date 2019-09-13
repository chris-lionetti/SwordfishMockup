function Create-EndpointsRootiSCSI {	
	param( 	$NetworkConfig,
			$Initiators,
			$Array	
		 )
	$Members=@()
	foreach ($set in $NetworkConfig)
		{	$configname = $Set.name
			$AL = $set.array_list
			$NL = $AL.Nic_list
			foreach ( $EP in $NL)
				{	$Endpointname=$configname+"_"+$EP.name
					$LocalMembers = @{	'@odata,id'		=	'/redfish/v1/StorageServices/'+$NimbleSerial+'/Endpoints/'+$Endpointname 
									 }
					$Members+=$localMembers
				}
			if ($configname -like 'Active')
			{	foreach ( $Initiator in $Initiators )
				{	$LocalMembers = @{	'@odata,id'		=	'/redfish/v1/StorageServices/'+$NimbleSerial+'/Endpoints/'+$Initiator.id 
									 }
					$Members+=$localMembers
		}	}	}
	$EPRoot = @{	'@Redfish.Copyright'	= 	$RedfishCopyright;
					'@odata.context'		=	'/redfish/v1/$metadata#Endpoint/'+$NimbleSerial+'/Endpoints';
					'@odata.id'				=	'/redfish/v1/StorageServices/'+$NimbleSerial+'/Endpoints';
					'@odata.type'			=	'#EndpointsCollection_1_4_0.EndpointsCollection';
					Name					=	'Nimble Endpoints Collection';
					'Members@odata.count'	=	(($NetworkConfig.array_list).nic_list).count;
					Members					=	$Members
			   }
	FolderAndFile $EPRoot ("StorageServices\"+$NimbleSerial+"\Endpoints")
}
		
function Create-EndpointsTargetsIndex {
	param( 	$NetworkConfig,
			$Array	)
	foreach ($set in $NetworkConfig)
		{	$configname = $Set.name
			$AL = $set.array_list
			$NL = $AL.Nic_list
			foreach ( $EP in $NL)
				{	$TheNic=( $Networkinterface | where { $_.name -like $EP.name -and $_.controller_name -like 'A' } )
					$EPID = $TheNic.id
					if ( $EPID.link_status -like 'link_status_up')
						{	$EPHealth = 'OK'
							$EPState  = 'Enabled'
						} else
						{	$EPHealth = 'Degraded'
							$EPState  = 'Disabled'
						}	
					$EPRoot = @{	'@Redfish.Copyright'	= 	$RedfishCopyright;
									'@odata.context'		=	'/redfish/v1/$metadata#Endpoint/'+$NimbleSerial+'/Endpoint';
									'@odata.id'				=	'/redfish/v1/StorageServices/'+$NimbleSerial+'/Endpoints/'+$configname+"_"+$EP.name;
									'@odata.type'			=	'#Endpoint.v1_3_1.Endpoint';
									Name					=	$configname+"_"+$EP.name;
									EndpointRole			=	'Target';
									Description				=	$configname+" configuration, Port named "+$EP.name+". iSCSI Target.";
									EndpointProtocol		=	'iSCSI';
									IPv4Address				=	$EP.data_ip;
									Id						=	$EPid;
									Status					=	@{	Health 	=	$EPHealth ;
																	State 	= 	$EPState
							   }								 }
					FolderAndFile $EPRoot ("StorageServices\"+$NimbleSerial+"\Endpoints\"+$configname+"_"+$EP.name)
}		}		}

function Create-EndpointsInitiatorIndex {
	param( 	$Initiators
		 )
	foreach ($initiator in $initiators)
		{	$EP = @{	'@Redfish.Copyright'	= 	$RedfishCopyright;
						'@odata.context'		=	'/redfish/v1/$metadata#Endpoint/'+$NimbleSerial+'/Endpoint';
						'@odata.id'				=	'/redfish/v1/StorageServices/'+$NimbleSerial+'/Endpoints/'+$Initiator.id;
						'@odata.type'			=	'#Endpoint.v1_3_1.Endpoint';
						Name					=	$Initiator.label;
						EndpointRole			=	'Initiator';
						Description				=	$configname+" configuration, Port named "+$EP.name+". iSCSI Target.";
						EndpointProtocol		=	'iSCSI';
						IPv4Address				=	$Initiator.Ip_Address;
						Id						=	$Initiator.id;
						Identifiers				=	@(	@{	DurableNameFormat	=	'iqn';
															DurableName			=	$Initiator.iqn
														 };
														@{	DurableNameFormat	=	'Nimble ID';
															DurableName			=	$Initiator.id
														 }
													 )
				   }
			FolderAndFile $EP $("StorageServices\"+$NimbleSerial+"\Endpoints\"+$Initiator.id)
}		}