function Get-SFEndpointRoot {	
param()
process{
	$Members=@()
	$NetworkConfig=( Get-NSNetworkConfig )
	foreach ($set in $NetworkConfig )
		{	$configname = $Set.name
			$AL = $set.array_list
			$NL = $AL.Nic_list
			foreach ( $EP in $NL)
				{	$Endpointname=$configname+"_"+$EP.name
					$LocalMembers = @{	'@odata.id'		=	'/redfish/v1/StorageSystems/'+$NimbleSerial+'/Endpoints/'+$Endpointname 
									 }
					if ($configname -like 'Active')
					{	$Members+=$localMembers
					}
				}
		}
	foreach ( $Initiator in ( Get-NSInitiator ) )
		{	$LocalMembers = @{	'@odata.id'		=	'/redfish/v1/StorageSystems/'+$NimbleSerial+'/Endpoints/'+$Initiator.id 
							 }
			$Members+=$localMembers
		}	
	$EPRoot = [ordered]@{
					'@Redfish.Copyright'	= 	$RedfishCopyright;
					'@odata.id'				=	'/redfish/v1/StorageSystems/'+$NimbleSerial+'/Endpoints';
					'@odata.type'			=	'#EndpointsCollection.v1_4_0.EndpointsCollection';
					Name					=	'Nimble Endpoints Collection';
					'Members@odata.count'	=	(($NetworkConfig.array_list).nic_list).count;
					Members					=	$Members
			   }
	return $EPRoot
}
}

function Get-SFEndpoint {
param(	$EndpointName
	 )
process{
	$result1 = Get-SFEndpointTarget 	-EndpointName $EndpointName
	$result2 = Get-SFEndpointInitiator 	-EndpointName $EndpointName
	if ($result1)	{	write-host 'Endpoint Target Found' 
						return $result1 
					} else 
					{	write-host 'Endpoint Host Found' 
						return $result2
					}
}
}

function Get-SFEndpointTarget {
	param(	$EndpointName		
		 )
	$NetworkConfig = (Get-NSNetworkConfig)
	foreach ($set in $NetworkConfig)
		{	$configname = $Set.name
			$AL = $set.array_list
			$NL = $AL.Nic_list
			foreach ( $EP in $NL)
				{	$TheNic=( $Networkinterface | where-object { $_.name -like $EP.name -and $_.controller_name -like 'A' } )
					$EPID = $TheNic.id
					if ( $EPID.link_status -like 'link_status_up')
						{	$EPHealth = 'OK'
							$EPState  = 'Enabled'
						} else
						{	$EPHealth = 'Degraded'
							$EPState  = 'Disabled'
						}	
					$EPRoot = [ordered]@{
									'@Redfish.Copyright'	= 	$RedfishCopyright;
									'@odata.id'				=	'/redfish/v1/StorageSystems/'+$NimbleSerial+'/Endpoints/'+$configname+"_"+$EP.name;
									'@odata.type'			=	'#Endpoint.v1_3_1.Endpoint';
									Name					=	$configname+"_"+$EP.name;
									EndpointRole			=	'Target';
									Description				=	$configname+" configuration, Port named "+$EP.name+". iSCSI Target.";
									EndpointProtocol		=	'iSCSI';
									IPv4Address				=	$EP.data_ip;
									Id						=	$EPid;
									Status					=	@{	Health 	=	$EPHealth ;
																	State 	= 	$EPState
																 }
							   }
					if ( ( $configname+"_"+$EP.name ) -like $EndpointName)
					{ 	return $EPRoot
					}
}		}		}

function Get-SFEndpointInitiator {
param( 	$EndpointName	
	 )
process{
	if ( Test-SFID($EndpointName) )
	{	$Initiator = ( Get-NSInitiator -id $EndpointName -ErrorAction SilentlyContinue )
		$EP = [ordered]@{
					'@Redfish.Copyright'	= 	$RedfishCopyright;
					'@odata.id'				=	'/redfish/v1/StorageSystems/'+$NimbleSerial+'/Endpoints/'+$Initiator.id;
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
		if ($Initiator)
			{	return $EP
			}
	} else
	{	return	
	}
}
}