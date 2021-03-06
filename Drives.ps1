function Get-SFDriveRoot {
param (	$ShelfName
	  )
process{
	$disks = ( Get-NSDisk )
	$Shelf = (Get-NSShelf | where {$_.serial -like $ShelfName })
	$DrivesObj=@()
	foreach ($disk in $disks)
		{	if ($Shelf.serial -like $disk.shelf_serial )
			{	$localDiskname="DiskShelf"+$($disk.vshelf_id)+"Location"+$($disk.slot)
				$DriveObj=@{ '@odata.id'	= 	"/redfish/v1/Chassis/"+$Shelf.serial+"/Drives/"+$localDiskname
						   }
				$DrivesObj+=$DriveObj
			}
		}
	$Drives=[ordered]@{	'@Redfish.Copyright'	= 	$RedfishCopyright;
						'@odata.type'			= 	"#DriveCollection.DriveCollection";
						'@odata.id'				= 	"/redfish/v1/Chassis/"+$Shelf.serial+"/Drives";
						Id						= 	"Drives";
						Name					= 	"HPENimbleDrives";
						Members					=	$DrivesObj;
			 		  }
	if ($Shelf) 
		{	return $Drives
		}
}
}
	
function Get-SFdrive {
param(	$diskname,
		$ShelfSer
	 )
process{
	$result = ""
	$DriveObj=@{}
	Write-Host "DiskName = $diskname"
	write-host "ShelfSer = $ShelfSer"
	$Shelf = ( Get-nsShelf | where { $_.serial -like $ShelfSer } )
	foreach ( $rawdisk in Get-NSDisk )
	{	$Loc = "DiskShelf"+$($rawdisk.vshelf_id)+"Location"+$($rawdisk.slot)
		if ($diskname -like $Loc)
		{	$disk = $rawdisk
			if ($disk.state -eq "in use" -and $Disk.raid_state -eq "okay")
				{	$DriveStatus = @{	State	=	'Enabled';
										Health 	=	'OK'
			  						};
				} else 
				{	$DriveStatus = @{	State	=	'Disabled';
										Health 	=	'Warning'
			  						};	
				}
		}
	}
	# Valid States for Redfish are; Enabled, Disabled, StandbyOffline, StandbySpare, InTest, Starting, Absent, UnavailableOffline, Deferring, Quiesced, Updating, Qualified
	# Value Health for Redfish are; OK, Critical, Warning, 
	# Nimble Drive object is Object.state = valid, in use, failed, absent, removed, void, t_fail, foreign
	# Nimble Drive object is Object.raid_state = N/A, okay, resynchronizing, spare, faulty
	if 
	if ($Shelf.serial -like $disk.shelf_serial )
		{	$localDiskname="DiskShelf"+$($disk.vshelf_id)+"Location"+$($disk.slot)
			if ( $disk.state -eq "in use")
				{	$LocalLED="Lit"	
				} else
				{	$LocalLED="Off"
				}
			$DriveObj=[ordered]@{ 	'@Redfish.Copyright'	= 	$RedfishCopyright;
						 			'@odata.id'				= 	"/redfish/v1/Chassis/"+$Shelf.Serial+"/Drives/"+$localDiskname;
						 			'@odata.type'			= 	"#Drive.v1_6_0.Drive";
						 			Id						= 	$disk.id;
								 	Name					= 	"HPENimbleDrives";
						 			IndicatorLED			=	$LocalLED;
						 			Model					=	$disk.model;
						 			Revision				=	$disk.firmware_version;
						 			Status					=	$DriveStatus;
									CapacityBytes			=	$disk.size;
							 		FailurePredicted		=	$disk.raid_state;
							 		Protocol				=	"SAS";
							 		MediaType				=	($disk.type).ToUpper();
							 		Manufacturer			=	$disk.vendor;
							 		SerialNumber			=	$disk.serial;
							 		PartNumber				=	$disk.vendor+"_"+$disk.model;	 
						 	 		AssetTag				=	$disk.serial;
							 		CapableSpeedGbs			=	6;
									NegotiatedSpeedGbs		=	6;
									Multipath				=	$True; 
									StoragePools			=	@( 	@{	'@odata.id'	=	'/redfish/v1/Storage/'+$NimbleSerial+'/StoragePools/Default'
																	 }
																 );
									Chassis					=	@{		'@odata.id' =	'/redfish/v1/Chassis/'+$Shelf.Serial
																 }
									
					   			}
		}
	return $DriveObj
}
}

function Get-SFDriveRootInStorage {
	param (
		  )
	process{
		$disks = ( Get-NSDisk )
		$DrivesObj=@()
		foreach ($disk in $disks)
			{	$localDiskname="DiskShelf"+$($disk.vshelf_id)+"Location"+$($disk.slot)
				$DriveObj=@{ '@odata.id'	= 	"/redfish/v1/Chassis/"+$Disk.shelf_serial+"/Drives/"+$localDiskname
						   }
				$DrivesObj+=$DriveObj
			}
		$Drives=[ordered]@{	'@Redfish.Copyright'	= 	$RedfishCopyright;
							'@odata.type'			= 	"#DriveCollection.DriveCollection";
							'@odata.id'				= 	"/redfish/v1/Storage/"+$NimbleSerial+"/Drives";
							Id						= 	"StorageDriveCollection";
							Name					= 	"HPENimbleDrives";
							Description				=	"A collection of Drive that this storage system uses, may span multiple enclosures";
							Members					=	$DrivesObj;
						   }
		return $Drives
		}
	}