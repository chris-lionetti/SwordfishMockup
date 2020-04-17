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
					$LocalMembers = @{	'@odata.id'		=	'/redfish/v1/Fabrics/'+$NimbleSerial+'/Endpoints/'+$Endpointname 
									 }
					if ($configname -like 'Active')
					{	$Members+=$localMembers
					}
				}
		}
	foreach ( $Initiator in ( Get-NSInitiator ) )
		{	$LocalMembers = @{	'@odata.id'		=	'/redfish/v1/Fabrics/'+$NimbleSerial+'/Endpoints/'+$Initiator.id 
							 }
			$Members+=$localMembers
		}	
	$EPRoot = [ordered]@{
					'@Redfish.Copyright'	= 	$RedfishCopyright;
					'@odata.id'				=	'/redfish/v1/Fabrics/'+$NimbleSerial+'/Endpoints';
					'@odata.type'			=	'#EndpointCollection.EndpointCollection';
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
						{	$EPHealth = 'Warning'
							$EPState  = 'Disabled'
						}	
					$EPRoot = [ordered]@{
									'@Redfish.Copyright'	= 	$RedfishCopyright;
									'@odata.id'				=	'/redfish/v1/Fabrics/'+$NimbleSerial+'/Endpoints/'+$configname+"_"+$EP.name;
									'@odata.type'			=	'#Endpoint.v1_4_0.Endpoint';
									Name					=	$configname+"_"+$EP.name;
									ConnectedEntities		=	@{	EntityRole			=	'Target';
																	EntityType			=	'NetworkController';

																 };
									Description				=	$configname+" configuration, Port named "+$EP.name+". iSCSI Target.";
									EndpointProtocol		=	'iSCSI';
									IPTransportDetails		=	@( 	@{	IPv4Address = 	@{	Address 	= 	$EP.data_ip
																					 	 }
																	 }
																 );
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
		$Initiator = ( Get-NSInitiator -id $EndpointName -ErrorAction SilentlyContinue )
		$EP = [ordered]@{	
							'@Redfish.Copyright'	= 	$RedfishCopyright;
							'@odata.id'				=	'/redfish/v1/Fabrics/'+$NimbleSerial+'/Endpoints/'+$Initiator.id;
							'@odata.type'			=	'#Endpoint.v1_4_0.Endpoint';
							Name					=	$Initiator.label;
							EndpointRole			=	'Initiator';
							ConnectedEntities		=	@{	EntityRole			=	'Initiator';
														 };
							Description				=	$configname+" configuration, Port named "+$EP.name+". iSCSI Target.";
							EndpointProtocol		=	'iSCSI';
							IPv4Address				=	$Initiator.Ip_Address;
							Id						=	$Initiator.id;
							Identifiers				=	@(	@{	DurableNameFormat	=	'iqn';
																DurableName			=	$Initiator.iqn
															 };
														 )
		  				}
		if ( Get-NSInitiator -id $EndpointName )
			{	return $EP
			}
}
}

