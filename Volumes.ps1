function Get-SFVolumeRoot {	
  param()
  process
  	{ 	$VolCount=0
		$Members=@()
		$Pool=Get-NSPool
		foreach ( $Volume in (Get-NSVolume) )
			{	$LocalMembers = @{	'@odata.id'		=	'/redfish/v1/Storage/'+$NimbleSerial+'/StoragePools/'+$Pool.name+'/Volumes/'+$Volume.name 
								 }
				$VolCount=$VolCount+1
				$Members+=$LocalMembers
			}
		$VolFolder =[ordered]@{	
						'@Redfish.Copyright'	= 	$RedfishCopyright;
						'@odata.id'				=	'/redfish/v1//Storage/'+$NimbleSerial+'/StoragePools/'+$Pool.name+'/Volumes';
						'@odata.type'			=	'#VolumeCollection.VolumesCollection';
						Name					=	'NimbleVolumeCollection';
						'Members@odata.count'	=	$VolCount;
						Members					=	$Members
					 		 }
		return $VolFolder
	}
}

function Get-SFVolumeRootCore {	
	param()
	process
		{ $Members=@()
		  $Pool=Get-NSPool
		  foreach ( $Volume in (Get-NSVolume) )
			  {	$LocalMembers = @{	'@odata.id'		=	'/redfish/v1/Storage/'+$NimbleSerial+'/StoragePools/'+$Pool.name+'/Volumes/'+$Volume.name 
								   }
				  $Members+=$LocalMembers
			  }
		  $VolFolder =[ordered]@{	
						  '@Redfish.Copyright'	= 	$RedfishCopyright;
						  '@odata.id'			=	'/redfish/v1//Storage/'+$NimbleSerial+'/StoragePools/'+$Pool.name+'/Volumes';
						  '@odata.type'			=	'#VolumeCollection.VolumesCollection';
						  Name					=	'NimbleVolumeCollection';
						  'Members@odata.count'	=	$Members.count;
						  Members				=	$Members
								}
		  return $VolFolder
	  }
  }

function Get-SFVolume {
   param(	$VolumeName,
			[switch]$Experimental=$false
	    )
   process
   {$ProvidingPools=@()
	$Volume = Get-NsVolume -name $VolumeName
	# $pool = $Volume.pool_name
	$LocalMembers = @{	'@odata,id'		=	'/redfish/v1/Storage/'+$NimbleSerial+'/StoragePools/'+$Volume.pool_name
					 }
	$ProvidingPools+=$localMembers
	if ( $Volume.online)
		{	$VolStatus_state = 'Enabled'
			$VolStatus_Health= 'OK'
		} else 
		{	$VolStatus_state = 'StandbyOffline'
			$VolStatus_health= 'Warning'	
		}
	if ( $Volume.Encryption_cipher -like 'none')
		{	$Vol_Encryption = $False
		} else 
		{	$Vol_Encryption = $True			
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
	$VolObj =[ordered]@{
				'@Redfish.Copyright'	= 	$RedfishCopyright;
				'@odata.id'				=	'/redfish/v1/Storage/'+$NimbleSerial+'/StoragePools/'+$Volume.pool_name+'/Volumes/'+$Volume.name;
				'@odata.type'			=	'#Volume.v1_4_0.Volume';
				Id						=	$Volume.id;
				Name					=	$Volume.name;
				Description				=	$Volume.description;
				CapacityBytes			=	($Volume.Size * 1024);					
				Status					=	@{	State			=	$VolStatus_state;
												Health			=	$VolStatus_health;
											 };
				BlockSizeBytes			=	$Volume.block_size;
				MaxBlockSizeBytes		=	$Volume.block_size;
				Manufacturer			=	'HPENimbleStorage';
				Encrypted				=	$Vol_Encryption;
				EncryptionTypes			=	@('ControllerAssisted');
				ProvisioningPolocy		=	'Thin';	
				Compressed				=	$True;
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
				CapacitySources			=	@(  @{ 	ProvidedCapacity	=	@{	AllocatedCapacity	=	($Volume.Size * 1024);
																				ConsumedBytes		=	$Volume.vol_usage_compressed_bytes
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
	if ( (get-nssnapshot -vol_name $VolumeName) -and $Experimental )
		{	$Snapss = @(	@{	'@odata.id'	=	'/redfish/v1/Storage/'+$NimbleSerial+'/StoragePools/'+$Volume.pool_name+'/Volumes/'+$VolumeName+'/Snapshots'
							 }
					   )
			$VolObj+= @{	Snapshots = $Snapss
					   }
		}
	if ( $Volume.volcoll_name )
        {   $VolColl= @{ ConsistencyGroup    =   '/redfish/v1/Storage/'+$NimbleSerial+'/ConsistencyGroup/'+$Volume.volcoll_name
                       }
            $VolObj+=$VolColl
        }
	if ($Volume) 
		{	Return $VolObj
		}
  }
}


