
function Create-VolumeFolderRoot {	
	param( 	$Volumes	
		 )
	$Members=@()
	foreach ($Volume in $Volumes)
		{	$LocalMembers = @{	'@odata,id'		=	'/redfish/v1/StorageServices/'+$NimbleSerial+'/Volumes/'+$Volume.name 
							 }
			$Members+=$localMembers
		}
	$VolFolder =@{	'@Redfish.Copyright'	= 	$RedfishCopyright;
					'@odata.context'		=	'/redfish/v1/$metadata#Volumes/'+$NimbleSerial+'/Volumes';
					'@odata.id'				=	'/redfish/v1//StorageServices/'+$NimbleSerial+'/Volumes';
					'@odata.type'			=	'#VolumesCollection_1_4_0.VolumesCollection';
					Name					=	'NimbleVolumeCollection';
					'Members@odata.count'	=	$Volumes.count;
					Members					=	$Members
				  }
	FolderAndFile $VolFolder ("StorageServices\"+$NimbleSerial+"\Volumes")
}

function Create-VolumesIndex {
	param(	$Pools,	
			$Volume
		 )
	$ProvidingPools=@()
	foreach ($pool in $pools)
	{	$LocalMembers = @{	'@odata,id'		=	'/redfish/v1/StorageServices/'+$NimbleSerial+'/StoragePools/'+$pool.name 
						 }
		$ProvidingPools+=$localMembers
	}
	if ( $Volume.online)
		{	$VolStatus_state = 'Enabled'
			$VolStatus_Health= 'OK'
		} else 
		{	$VolStatue_state = 'StandbyOffline'
			$VolStatus_health= 'Warning'	
		}
	if ( $Volume.Encryption_cipher -like 'none')
		{	$Vol_Encryption = 'false'
		} else 
		{	$Vol_Encryption = 'true'			
		}
	if ( $Volume.Thinly_Provisioned )
		{	$Vol_ProvisioningPolicy = 'thin'
		} else
		{	$Vol_ProvisioningPolicy = 'fixed'
		}
	if ( $Volume.Cache_policy -like 'normal' )
		{	$Vol_CachePolicy = 'AdaptiveReadAhead'
		} else 	
		{	$Vol_CachePolicy = 'off'
		}
	$VolObj =@{'@Redfish.Copyright'		= 	$RedfishCopyright;
				'@odata.context'		=	'/redfish/v1/$metadata#Volumes/'+$NimbleSerial+'/Volumes/'+$Volume.name;
				'@odata.id'				=	'/redfish/v1/$metadata#Volumes/'+$NimbleSerial+'/Volumes/'+$Volume.name;
				'@odata.type'			=	'#Volumes_1_4_0.Volume';
				Id						=	$Volume.id;
				Name					=	$Volume.name;
				Description				=	$Volume.description;
				Capacity				=	@{	AllocatedBytes	=	($Volume.Size * 1024) ;
												ConsumedBytes	=	$Volume.vol_usage_compressed_bytes	
											 };
				Status					=	@{	State			=	$VolStatus_state;
												Health			=	$VolStatus_health;
											 };
				BlockSizeBytes			=	$Volume.block_size;
				MaxBlockSizeBytes		=	$Volume.block_size;
				Manufacturer			=	'HPENimbleStorage';
				Encrypted				=	$Vol_Encryption;
				EncryptionTypes			=	'ControllerAssisted';
				ProvisioningPolicy		=	$Vol_ProvisioningPolicy;
				Compressed				=	'true';
				Deduplicated			=	$Volume.dedupe_enabled;
				DisplayName				=	$Volume.Full_name;
				LowSpaceWarningThresholdPercents =	$Volume.warn_level;
				OptimumIOSizeBytes		=	$Volume.block_size;
				VolumeType				=	'SpannedStripesWithParity';
				VolumeUsageType			=	"Data";
				ReadCachePolicyType		=	$Vol_CachePolicy;
				WriteCacheState			=	'Enabled'
				WriteCachePolicyType	=	"ProtectedWriteBack";
				WriteCacheStateType		=	"Protected";
				WriteHoleProtectionPolicyType = "Journaling";
				CapacitySources			=	@(  @{ 	ProvidedCapacity	=	@{	AllocatedCapacity	=	$Pool.Capacity;
																				ConsumedBytes		=	$Pool.usage
				 															 };	
													ProvidingPools		=	@{	Pools				=	@( $ProvidingPools )
												 }							 }
											 );
				Identifiers				=	@(	@{	Manufacturer		=	'NimbleStorage'	
												 };
												@{	DurableNameFormat	=	'UUID';
													DurableName			=	$Volume.id
												 };
												@{	DurableNameFormat	=	'vpd_ieee0';
												 	DurableName			=	$Volume.vpd_ieee0
												 };
												@{	DurableNameFormat	=	'vpd_ieee1';
												 	DurableName			=	$Volume.vpd_ieee1
	  											 };
												@{	DurableNameFormat	=	'vpd_t10';
												   DurableName			=	$Volume.vpd_t10
												 };
												@{	DurableNameFormat	=	'iqn';
													DurableName			=	$Volume.target_name
												 };
											 )				
				}
	FolderAndFile $VolObj ("StorageServices\"+$NimbleSerial+"\Volumes\"+$Volume.name)
}

function Create-VolumesSnapshotIndex {
	param(	$Volume,
			$Snapshot
		 )
	$ProvidingVol = @{	'@odata,id'		=	'/redfish/v1/StorageServices/'+$NimbleSerial+'/Volumes/'+$Volume.name 
					 }
	if ( $Volume.Encryption_cipher -like 'none')
		{	$Vol_Encryption = 'false'
		} else 
		{	$Vol_Encryption = 'true'			
		}
	if ( $Volume.Cache_policy -like 'normal' )
		{	$Vol_CachePolicy = 'AdaptiveReadAhead'
		} else 	
		{	$Vol_CachePolicy = 'off'
		}
	$Snap=$Snapshot
	if ( $Snapshot.online)
		{	$SnapStatus_state = 'Enabled'
			$SnapStatus_Health= 'OK'
		} else 
		{	$SnapStatue_state = 'StandbyOffline'
			$SnapStatus_health= 'Warning'	
		}
			$VolObj =@{'@Redfish.Copyright'		= 	$RedfishCopyright;
						'@odata.context'		=	'/redfish/v1/$metadata#Volumes/'+$NimbleSerial+'/Volumes/'+$Snapshot.name;
						'@odata.id'				=	'/redfish/v1/$metadata#Volumes/'+$NimbleSerial+'/Volumes/'+$Snapshot.name;
						'@odata.type'			=	'#Volumes_1_4_0.Volume';
						Id						=	$Snapshot.id;
						Name					=	$Snapshot.name;
						Description				=	$Snapshot.description;
						Capacity				=	@{	AllocatedBytes	=	($Snapshot.Size * 1024)	
													 };
						Status					=	@{	State			=	$SnapStatus_state;
														Health			=	$SnapStatus_health;
												 	 };
						BlockSizeBytes			=	$Volume.block_size;
						MaxBlockSizeBytes		=	$Volume.block_size;
						OptimumIOSizeBytes		=	$Volume.block_size;
						Manufacturer			=	'HPENimbleStorage';
						Encrypted				=	$Vol_Encryption;
						EncryptionTypes			=	'ControllerAssisted';
						ProvisioningPolicy		=	'thin';
						Compressed				=	'true';
						Deduplicated			=	$Volume.dedupe_enabled;
						DisplayName				=	$Volume.Full_name+'+'+$Snap.name;
						LowSpaceWarningThresholdPercents =	$Volume.warn_level;
						VolumeType				=	'Snapshot';
						VolumeUsageType			=	"Data";
						ReadCachePolicyType		=	$Vol_CachePolicy;
						WriteCacheState			=	'Enabled'
						WriteCachePolicyType	=	"ProtectedWriteBack";
						WriteCacheStateType		=	"Protected";
						WriteHoleProtectionPolicyType = "Journaling";
						CapacitySources			=	@(  @{ 	ProvidedCapacity	=	@{	AllocatedCapacity	=	$Volume.limit;
																						ConsumedBytes		=	$Snapshot.snap_usage_compressed_bytes
				 																 	 };	
															ProvidingVolumes	=	@{	Volumes				=	@( $ProvidingVol )
													 	 }							 }
												 	 );
						Identifiers				=	@(	@{	Manufacturer		=	'NimbleStorage'	
														 };
														@{	DurableNameFormat	=	'UUID';
															DurableName			=	$Snapshot.id
														 };
														@{	DurableNameFormat	=	'vpd_ieee0';
														 	DurableName			=	$Snapshot.vpd_ieee0
														 };
														@{	DurableNameFormat	=	'vpd_ieee1';
														 	DurableName			=	$Snapshot.vpd_ieee1
	  													 };
														@{	DurableNameFormat	=	'vpd_t10';
														   	DurableName			=	$Snapshot.vpd_t10
														 };
														@{	DurableNameFormat	=	'iqn';
															DurableName			=	$Snapshot.target_name
														 };
													 )				
					}
			FolderAndFile $VolObj ("StorageServices\"+$NimbleSerial+"\Volumes\"+$Snapshot.name)
}
