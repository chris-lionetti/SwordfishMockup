function FolderAndFile {
	param ( $OutputText,
			$FolderNames
	)

	$supress = make-folder $FolderNames
	if ( $OutputText )
		{	write-index $OutputText $FolderNames
		} 
}

function Make-Folder {
	param(	$ManyFoldername
		 )
	foreach ($Foldername in $ManyFolderName)
	{	$Foldername=$RedfishFolder+'\'+$Foldername
		if (!(test-path $Foldername))
			{	write-host "Creating Directory for the $Foldername"
				$Supress=New-Item -ItemType Directory -force -path $Foldername
			} else 
			{	write-verbose "Base directory already exists $Foldername"
			}
	}	
}
function Write-Index {
	param(	$OutputText,
			$Folder
		 )
	$Outputformatted = $OutputText | convertto-json -Depth 10
	$BgFilename=$RedfishFolder+'\'+$Folder+'\'+$BaseFileName
	write-verbose "The folder is $Folder"
	if (!(test-path $BgFilename))
		{	write-verbose "Creating the file $BgFilename"
		} else 
		{	write-verbose "Base File already exists, overwriting $BgFilename"
		}
	$Outputformatted > $($BgFilename)
}

. .\Chassis.ps1
. .\Drives.ps1
. .\StoragePools.ps1
. .\Volumes.ps1
. .\StorageServices.ps1
. .\Endpoints.ps1
. .\EndpointGroups.ps1
. .\StorageGroups.ps1
. .\DataProtectionLoS.ps1
# Load the external Functions

# MAIN ############################################
$Global:NimbleSerial	=	(Get-nsArray).serial
$Global:RedfishCopyright=	"Copyright 2014-2016 Distributed Management Task Force, Inc. (DMTF). For the full DMTF copyright policy, see http://www.dmtf.org/about/policies/copyright."
$Global:SwordfishCopyright=	"Copyright 2016-2019 Storage Networking Industry Association (SNIA), USA. All rights reserved. For the full SNIA copyright policy, see http://www.snia.org/about/corporate_info/copyright"
$Global:BaseFileName	=	"index.json"
$Global:RedfishFolder	=	"C:\SwordfishMockup\Redfish\v1"

$username = "admin"
$password = ConvertTo-SecureString "admin" -AsPlainText -Force
$psCred = New-Object System.Management.Automation.PSCredential -ArgumentList ($username, $password)
connect-nsgroup -Group 192.168.1.60 -Credential $psCred -IgnoreServerCertificate
write-host "Test1"
New-Item -ItemType Directory -force -path 'C:\SwordfishMockup'
New-Item -ItemType Directory -force -path 'C:\SwordfishMockup\Redfish'
New-Item -ItemType Directory -force -path 'C:\SwordfishMockup\Redfish\v1'
FolderAndFile -ManyFoldername @("AccountServices","Chassis","EventServices","Managers","SessionServices","Systems","TaskServices","StorageServices","StorageSystems")
Create-ServiceRootIndex
Create-StorageServices 		-array (Get-NSArray)
Create-StorageServicesArray -array (get-nsarray)
# ######################################################
# # Create Chassis
# ######################################################
write-host "Chassis"
Create-ChassisRoot -Shelfs (Get-NSShelf)
foreach ($NimbleShelf in Get-NSShelf)
	{	Create-Chassis -Shelf $NimbleShelf -array (Get-nsarray)
		CreateChassisFolderPower -shelf $NimbleShelf
		CreateChassisFolderThermal -shelf $NimbleShelf
		Create-DriveRoot -disks (get-nsdisk) -shelf $NimbleShelf
	}
# #####################################################
# # Create Drives
# #####################################################
create-drive 	 -disks (get-nsdisk) -shelf $NimbleShelf	
# #####################################################
# # Create Pools
# #####################################################
Create-PoolFolderRoot 	-pool (Get-NSPool) 	
foreach( $NPool in $(Get-nsPool) )
{	Create-PoolsIndex 	-pool $NPool 	-volumes (Get-NSVolume)	-disks (Get-NSDisk)
}
# #####################################################
# # Create Volumes
# #####################################################
Create-VolumeFolderRoot -volumes (Get-NSVolume)
foreach ($Volume in $(Get-NSVolume ))
{	Create-VolumesIndex -volume $volume -pools (Get-nsPool)
}
foreach ($Volume in $(Get-NSVolume ))
{	foreach ($Snapshot in $(Get-NsSnapshot -vol_name $($Volume).name) )
	{	Create-VolumesSnapshotIndex -volume $volume -snapshot $Snapshot
	}
}
# #####################################################
# # Create Endpoints
# #####################################################
Create-EndpointsRootiSCSI 		-networkconfig (Get-NSNetworkConfig) 	-initiators (Get-nsInitiator) 
Create-EndpointsTargetsIndex	-networkconfig (Get-NSNetworkConfig) 	
Create-EndpointsInitiatorIndex 	-initiators (Get-nsInitiator) 			
# #####################################################
# # Endpoint Groups
# #####################################################
Create-EndpointGroupRootiSCSI 		-InitiatorGroups (Get-NSInitiatorGroup)
Create-InitiatorEndpointGroupsIndex -InitiatorGroups (Get-NSInitiatorGroup)	-AccessMaps (Get-NSAccessControlRecord)
Create-TargetEndpointGroupsIndex -InitiatorGroups (Get-NSInitiatorGroup)	-AccessMaps (Get-NSAccessControlRecord) -subnets (Get-NSSubnet)
# #####################################################
# # Endpoint Groups
# #####################################################
Create-StorageGroupRoot 			-AccessControlMaps (Get-NSAccessControlRecord)
Create-StorageGroupsIndex 			-AccessControlMaps (Get-NSAccessControlRecord)
# #####################################################
# # Data Protection Lines of Service
# #####################################################
Create-DPLOS						-VolumeCollections (Get-NSVolumeCollection)		-ProtectionSchedules (Get-NSProtectionSchedule)
Create-DPLOSIndex					-VolumeCollections (Get-NSVolumeCollection)		-ProtectionSchedules (Get-NSProtectionSchedule)
