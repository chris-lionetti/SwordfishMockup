function Get-SFDriveRoot {
param (	$ShelfName
	  )
process{
	$disks = ( Get-NSDisk )
	$Shelf = (Get-NSShelf | where {$_.serial -like $ShelfName })
	$DrivesObj=@()
	foreach ($disk in $disks)
		{	if ($Shelf.serial -like $disk.shelf_serial )
			{	$localDiskname="Disk.Shelf_"+$($disk.vshelf_id)+".Location_"+$($disk.slot)
				$DriveObj=@{ '@odata.id'	= 	$localDiskname
						   }
				$DrivesObj+=$DriveObj
			}
		}
	$Drives=@{	'@odata.type'			= 	"#Drive.1.6.0.Drive";
				'@Redfish.Copyright'	= 	$RedfishCopyright;
				'@odata.context'		= 	'/redfish/v1/$metadata#Chassis/Members/'+$Shelf.serial+'/Drives';
				'@odata.id'				= 	"/redfish/v1/Chassis/"+$Shelf.serial+"/Drives";
				Id						= 	"Drives";
				Name					= 	"HPENimbleDrives";
				Drives					=	$DrivesObj;
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
	write-host "DiskName = $diskname"
	write-host "ShelfSer = $ShelfSer"
	$Shelf = ( Get-nsShelf | where { $_.serial -like $ShelfSer } )
	foreach ( $rawdisk in Get-NSDisk )
	{	$Loc = "Disk.Shelf_"+$($rawdisk.vshelf_id)+".Location_"+$($rawdisk.slot)
		if ($diskname -like $Loc)
		{	$disk = $rawdisk
		}
	}
	if ($Shelf.serial -like $disk.shelf_serial )
		{	$localDiskname="Disk.Shelf_"+$($disk.vshelf_id)+".Location_"+$($disk.slot)
			if ( $disk.state -eq "in use")
				{	$LocalLED="Lit"	
				} else
				{	$LocalLED="Off"
				}
			$DriveObj=@{ 	'@Redfish.Copyright'	= 	$RedfishCopyright;
						 	'@odata.id'				= 	"/redfish/v1/Chassis/"+$Shelf.Serial+"/Drives/"+$localDiskname;
						 	'@odata.type'			= 	"#Drive.1.6.0.Drive";
						 	'@odata.context'		= 	'/redfish/v1/$metadata#Chassis/Members/'+$Shelf.serial+'/Drives/Members/$entity';
						 	Id						= 	$disk.id;
						 	Name					= 	"HPENimbleDrives";
						 	IndicatorLED			=	$LocalLED;
						 	Model					=	$disk.model;
						 	Revision				=	$disk.firmware_version;
						 	Status					=	@{	State	=	$disk.state;
															Health 	=	$disk.raid_state
							 							 };
							 CapacityBytes			=	$disk.size;
							 FailurePredicted		=	$disk.raid_state;
							 Protocol				=	"SAS";
							 MediaType				=	$disk.type;
							 Manufacturer			=	$disk.vendor;
							 SerialNumber			=	$disk.serial;
							 PartNumber				=	$disk.vendor+"_"+$disk.model;	
							 Identifiers			= 	@(	@{	DurableNameFormat	=	"NimbleID";
																DurableName			=	$disk.id
															 }
							 							 );
						 	AssetTag				=	$disk.serial;
							CapableSpeedGbs			=	6;
							NegotiatedSpeedGbs		=	6
					   }
		}
	return $DriveObj
}
}