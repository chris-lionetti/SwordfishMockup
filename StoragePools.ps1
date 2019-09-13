
function Create-PoolFolderRoot {	
	param( 	$Pools
		 )
	$Members=@()
	foreach ($pool in $Pools)
		{	$LocalMembers = @{	'@odata,id'		=	'/redfish/v1/StorageServices/'+$NimbleSerial+'/StoragePools/'+$Pool.name 
							 }
			$Members+=$localMembers
		}
	$PoolFolder =@{	'@Redfish.Copyright'	= 	$RedfishCopyright;
					'@odata.context'		=	'/redfish/v1/$metadata#StorageServices/'+$NimbleSerial+'/StoragePools';
					'@odata.id'				=	'/redfish/v1/StorageServices/'+$NimbleSerial+'/StoragePools';
					'@odata.type'			=	'#StoragePoolsCollection_1_0_0.StoragePoolsCollection';
					Name					=	'NimblePoolCollection';
					'Members@odata.count'	=	$Pools.count;
					Members					=	$Members
				  }
	FolderAndFile $PoolFolder ("StorageServices\"+$NimbleSerial+"\StoragePools")
}

function Create-PoolsIndex {
	param(	$Pool,
			$Volumes,
			$Disks
	)
	$DObj=@()
	foreach ($disk in $disks)
		{	$localDiskname="Disk.Shelf_"+$($disk.vshelf_id)+".Location_"+$($disk.slot)
			$DriveObj =	@{ '@odata.id'	= 	'/redfish/v1/Chassis/'+$NimbleSerial+'/Drives/'+$localdiskname
					   	 }
			$DObj+=$DriveObj
		}
	$VolsObj=@()
	foreach ($Vol in $Pool.vol_list)
		{	$VolObj =	@{ '@odata.id'	= 	'/redfish/v1/StorageServices/'+$NimbleSerial+'/Volumes/'+$Vol.Vol_name
						 }
			$VolsObj+=$VolObj
		}
	$CapacitySources=@{		
					  }
	$PoolObj =@{'@Redfish.Copyright'	= 	$RedfishCopyright;
				'@odata.context'		=	'/redfish/v1/$metadata#StorageServices/'+$NimbleSerial+'/StoragePools/'+$Pool.name;
				'@odata.id'				=	'/redfish/v1/$metadata#StorageServices/'+$NimbleSerial+'/StoragePools/'+$Pool.name;
				'@odata.type'			=	'#StoragePool_1_0_0.StoragePool';
				Id						=	$Pool.id;
				Name					=	$Pool.name;
				Description				=	$Pool.description;
				Capacity				=	@{	AllocatedBytes	=	$Pool.Capacity;
												ConsumedBytes	=	$Pool.usage	
											 };
				Status					=	@{	State			=	'Enabled';
												Health			=	'OK';
												HealthRollUp	=	'OK'
											 };
				AllocatedVolumes		=	@(	$VolsObj
											 );
				CapacitySources			=	@(  @{ 	ProvidedCapacity	=	@{	AllocatedCapacity	=	$Pool.Capacity;
																				ConsumedBytes		=	$Pool.usage
				 															 };	
													ProvidingDrives		=	@{	Drives				=	@( $DObj )
																			  }
												 }
											 );
				Compressed				=	'true';
				Deduplicated			=	$Pool.dedupe_capable;
				Encryption				=	'true'	
				SupportedRAIDTypes		=	'RAID6TP'
				}
	FolderAndFile $PoolObj ("StorageServices\"+$NimbleSerial+"\StoragePools\"+$Pool.name)
}


