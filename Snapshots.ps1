function Get-SFSnapshotIndex{
    param(	$VolName
         )
    process
    {   $SnapIndex=@()
        $Snapcount=0
        foreach ($snapshot in get-nssnapshot -vol_name $VolName)
            {	$LocalMembers=@{	'@odata.id'	=	'/redfish/v1/StorageSystems/'+$NimbleSerial+'/Volumes'+$VolName+'/SnapShots/'+$Snapshot.name
                               }
                $SnapIndex+=$LocalMembers
                $Snapcount+=1
            }
        $SnapColObj=@{	'@Redfish.Copyright'	= 	$RedfishCopyright;
                        '@odata.context'		=	'/redfish/v1/$metadata#Volumes/'+$NimbleSerial+'/Volumes/'+$VolName+'/Snapshots';
                        '@odata.id'				=	'/redfish/v1//StorageSystems/'+$NimbleSerial+'/Volumes/'+$VolName+'/Snapshots';
                        '@odata.type'			=	'#SnapshotsCollection_1_0_0.SnapshotsCollection';
                        Name					=	'NimbleSnapshotCollection';
                        'Members@odata.count'	=	$SnapCount;
                        Members					=	$SnapIndex		
                     }
        Return $SnapColObj
    }
}
function Get-SFVolumeOrSnap{
    param(	$VolumeOrSnapName
         )
    process
    {   $VolFound=$false
        if ( Get-NSVolume -name ($VolumeOrSnapName) )
        {	$VolFound=$True
            Return (Get-SFVolume -VolumeName $VolumeOrSnapName)
        } else 
        {	ForEach ($Volume in (Get-NSVolume) )
                {	if ( Get-NSSnapshot -$VolID ($Volume.id) -name $VolumeOrSnapName)
                        {	$VolFound=$True
                            Return (Get-SFSnapShot -$VolID ($Volume.id) -name $VolumeOrSnapname) 
                        } 
                }
        }
        if ( $VolFound -eq $False )
            {   Return
            }
    }
}
     
function Get-SFSnapshot {
    param(	$VolName,
            $SnapName
         )
    process
    {   $Volume = Get-NSVolume -Name $VolName
        $ProvidingVol = @{	'@odata,id'		=	'/redfish/v1/StorageSystems/'+$NimbleSerial+'/Volumes/'+$Volume.name 
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
        $Snapshot = ( Get-NSSnapshot -Vol_Name $VolName -Name $SnapName )
        if ( $Snapshot.online)
            {	$SnapStatus_state = 'Enabled'
                $SnapStatus_Health= 'OK'
            } else 
            {	$SnapStatus_state = 'StandbyOffline'
                $SnapStatus_health= 'Warning'	
            }
        $SnapObj =@{    '@Redfish.Copyright'		= 	$RedfishCopyright;
                        '@odata.context'		=	'/redfish/v1/$metadata#Volumes/'+$NimbleSerial+'/Volumes/'+$VolName+'/Snapshots/'+$Snapshot.name;
                        '@odata.id'				=	'/redfish/v1/$metadata#Volumes/'+$NimbleSerial+'/Volumes/'+$VolName+'/Snapshots/'+$Snapshot.name;
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
                        DisplayName				=	$Volume.Full_name+'+'+$Snapshot.name;
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
        return $SnapObj
    }
}