function Get-SFSnapshotIndex{
    param(	$VolName
         )
    process
    {   $SnapIndex=@()
        $Snapcount=0
        foreach ($snapshot in get-nssnapshot -vol_name $VolName)
            {	$LocalMembers=@{	'@odata.id'	=	'/redfish/v1/Storage/'+$NimbleSerial+'/StoragePools/Default/Volumes/'+$VolName+'/SnapShots/'+$Snapshot.id
                               }
                $SnapIndex+=$LocalMembers
                $Snapcount+=1
            }
        $SnapColObj=[ordered]@{	    '@Redfish.Copyright'	= 	$RedfishCopyright;
                                    '@odata.id'				=	'/redfish/v1//Storage/'+$NimbleSerial+'/StoragePools/Default/Volumes/'+$VolName+'/Snapshots';
                                    '@odata.type'			=	'#SnapshotsCollection.v1_0_0.SnapshotsCollection';
                                    Name					=	'NimbleSnapshotCollection';
                                    'Members@odata.count'	=	$SnapCount;
                                    Members					=	$SnapIndex		
                              }
        Return $SnapColObj
    }
}
     
function Get-SFSnapshot {
    param(	$VolName,
            $SnapId
         )
    process
    {   $Volume = (Get-NSVolume -Name $VolName)
        $ProvidingVol = @{	'@odata.id'		=	'/redfish/v1/Storage/'+$NimbleSerial+'/StoragePools/Default/Volumes/'+$Volume.name 
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
        $VolID=$Volume.id
        $Snapshot = ( Get-NSSnapshot -Vol_Name $VolName | where { $_.id -eq $SnapId } )
        if ( $Snapshot.online)
            {	$SnapStatus_state = 'Enabled'
                $SnapStatus_Health= 'OK'
            } else 
            {	$SnapStatus_state = 'StandbyOffline'
                $SnapStatus_health= 'Warning'	
            }
        $SnapObj = [ordered]@{
                        '@Redfish.Copyright'	= 	$RedfishCopyright;
                        '@odata.id'				=	'/redfish/v1/Storage/'+$NimbleSerial+'/StoragePools/Default/Volumes/'+$VolName+'/Snapshots/'+$Snapshot.id;
                        '@odata.type'			=	'#Volume.v1_4_0.Volume';
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
        if ( $Volume.volcoll_name )
            {   $VolColl= @{ ConsistencyGroup    =   '/redfish/v1/Storage/'+$NimbleSerial+'/ConsistencyGroup/'+$Volume.volcoll_name
                           }
                $SnapObj+=$VolColl
            }
        return $SnapObj
    }
}