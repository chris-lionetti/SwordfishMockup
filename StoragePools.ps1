function Get-SFPoolRoot {	
param( 	
	 )
process{
	$Members=@()
	$pools=( Get-NsPool )
	foreach ($pool in $Pools)
		{	$LocalMembers = @{	'@odata.id'		=	'/redfish/v1/Storage/'+$NimbleSerial+'/StoragePools/'+$Pool.name 
							 }
			$Members+=$localMembers
		}
	$PoolFolder =[ordered]@{
					'@Redfish.Copyright'	= 	$RedfishCopyright;
					'@odata.id'				=	'/redfish/v1/Storage/'+$NimbleSerial+'/StoragePools';
					'@odata.type'			=	'#StoragePoolCollection.StoragePoolCollection';
					Name					=	'NimblePoolCollection';
					'Members@odata.count'	=	$Members.count;
					Members					=	$Members
				  }
	return $PoolFolder
}
}

function Get-SFPool {
param(	$Poolname
	 )
process{
	$DObj=@()
	$Pool = ( Get-NSPool )
	$disks = ( Get-NSDisk )
	$DiskCount=0
	foreach ($disk in $disks)
		{	$localDiskname="DiskShelf"+$($disk.vshelf_id)+"Location"+$($disk.slot)
			$DriveObj =	@{ '@odata.id'	= 	'/redfish/v1/Chassis/'+$NimbleSerial+'/Drives/'+$localdiskname
							}
			$DiskCount+=1
			$DObj+=$DriveObj
		}
	$VolsObj=@()
	foreach ( $Vol in ($Pool.vol_list) )
		{	# Nimble only has one pool, so assuming that all volumes are listed under that single pool
			$VolObj =	@{ '@odata.id'	= 	'/redfish/v1/Storage/'+$NimbleSerial+'/StoragePools/'+$Pool.name+'/Volumes/'+$Vol.name
						 }
			$VolsObj+=$VolObj
		}
	$CapacitySources=@{}
	$PoolObj =[ordered]@{
				'@Redfish.Copyright'			= 	$RedfishCopyright;
				'@odata.id'						=	'/redfish/v1/Storage/'+$NimbleSerial+'/StoragePools/'+($Pool.name);
				'@odata.type'					=	'#StoragePool.v1_3_1.StoragePool';
				Id								=	($Pool.id);
				Name							=	($Pool.name);
				Description						=	($Pool.description);
				CapacityInfo					=	@{	AllocatedBytes	=	($Pool.Capacity);
														ConsumedBytes	=	($Pool.usage)	
													 };
				Status							=	@{	State			=	'Enabled';
														Health			=	'OK';
														HealthRollUp	=	'OK'
											 		 };
				AllocatedVolumes				=	@(	$VolsObj
											 		 );
				CapacitySources					=	@(  @{ 	ProvidedCapacity	=	@{	AllocatedCapacity	=	($Pool.Capacity);
																						ConsumedBytes		=	($Pool.usage)
				 																	 };	
															ProvidingDrives		=	@{	Drives				=	@( $DObj )
																					 }
												 		 }
													 );
				Compressed						=	$True;
				Deduplicated					=	($Pool.dedupe_capable);
				Encryption						=	$True;	
				SupportedRAIDTypes				=	'RAID6TP'
			   }
	if ($Poolname -like $Pool.name )
		{	return $PoolObj 
		}
}
}