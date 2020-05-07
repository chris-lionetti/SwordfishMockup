# This file when run will walk through the protocol and create a Mockup in the dedicated folder.
$MyMockupDir = 'C:\MyMockups\Mockup1'
$username = "admin"                                            # This is the Array username
$password = ConvertTo-SecureString "admin" -AsPlainText -Force # This is the Array Password, change admin to YOUR password
$ArrayIP  = '192.168.1.60'                                     # This is the Array IP Address
##############################################################################################################################
$psCred = ( New-Object System.Management.Automation.PSCredential($username, $password) )
if ( -not (get-module -ListAvailable -name HPENimblePowerShellToolkit ) )
    {   Write-Error "You must first download the HPENimblePowerShelLToolkit from the Microsoft PSGallery to use this software."
        exit
    }
import-module -name HPENimblePowerShellToolkit
connect-nsgroup -Group "$ArrayIP" -Credential $psCred -IgnoreServerCertificate
if ( get-nsarray )
    {   Write-warning "Connected to Array"
    }
    else 
    {   Write-Error "You must modify this script to specify the correct IP address, username and Password to a Nimble Array"
        exit
    }
$Global:NimbleSerial	    =	(Get-nsArray).serial
$Global:RedfishCopyright    =	"Copyright 2014-2016 HPE and DMTF"
$Global:SwordfishCopyright  =	"Copyright 2016-2019 HPE and SNIA"
. .\Chassis.ps1                                 # These are all of the Subroutines to return the JSON. Subdivided to make troubleshooting simpler.
. .\Drives.ps1
. .\Endpoints.ps1
. .\Zones.ps1
. .\StoragePools.ps1
. .\StorageGroups.ps1
. .\StorageSystems.ps1
. .\AccountService.ps1
. .\Systems.ps1
. .\Volumes.ps1
. .\Snapshots.ps1
. .\ConsistencyGroups.ps1
. .\DataProtectionLoS.ps1
. .\EventService.ps1
. .\Fabrics.ps1

# Only need to change the above folder.
if ( -not ( test-path $MyMockupDir -pathtype container ) )
    {   write-error "The folder $MyMockupDir does not exist. Please create this folder and run it again" 
        Exit
    }

function MakeA-Folder
{   Param(  [Parameter(Mandatory = $True)]
            [String] $DirToMake
         )
    if (-not (Test-Path -LiteralPath $DirToMake)) 
        {   try     {   New-Item -Path $DirToMake -ItemType Directory -ErrorAction Stop | Out-Null #-Force
                    }
            catch   {   Write-Error -Message "Unable to create directory '$DirToMake'. Error was: $_" -ErrorAction Stop
                    }
            Write-host "Successfully created directory '$DirToMake'."
        } else 
        {   Write-warning "Directory $DirToMake already existed"
        }
}

function WriteA-File
{   param(  [Parameter(Mandatory = $True)]
            [String] $FileData,
            
            [Parameter(Mandatory = $True)]
            [String] $Folder    
         )
    MakeA-Folder $Folder
    if (Test-Path -LiteralPath ($Folder+'\index.json') -pathtype leaf ) 
         {   try     {   Remove-Item -LiteralPath ($Folder+'\index.json') -Force -ErrorAction Stop | Out-Null
                     }
             catch   {   Write-Error -Message "Unable to overwrite/delete $Folder\index.json file. Error was: $_" -ErrorAction Stop
                     }
             Write-host "Successfully removed existing index.json file at $Folder."
         } 
    # write-host $FileData
    $suppressoutput = New-Item -path $Folder -name 'index.json' -value $FileData     

}

# Initial Hardcoded root folders (System, Core, Root)
    MakeA-Folder ( $MyMockupDir )                                   # C:\MyMockups\Mockup1
    $Data=(Get-SFSystemCore | convertTo-JSON -depth 10)
    WriteA-File -FileData $Data -Folder ($MyMockupDir+'\redfish')
    $RedfishRoot = $MyMockupDir+'\redfish\v1'

    $Data=( Get-SFRedfishRoot | convertTo-JSON -depth 10) 
    WriteA-File -FileData $Data -Folder $RedfishRoot

#    $Data=( Get-SFSystemRoot | convertTo-JSON -depth 10) 
#    WriteA-File -FileData $Data -Folder ( $RedfishRoot+'\Systems' )


# ACCOUNTS ####
    $Data=( Get-SFAccountServiceRoot | convertTo-JSON -depth 10) 
    WriteA-File -FileData $Data -Folder ( $RedfishRoot+'\AccountService' )

    $Data=( Get-SFAccountCol | convertTo-JSON -depth 10) 
    WriteA-File -FileData $Data -Folder ( $RedfishRoot+'\AccountService\Accounts' )

    $MyAccounts = $(Get-SFAccountCol).Members
    foreach ($MyAccount in $MyAccounts)
    {   $PathRaw=$MyAccount.'@odata.id'
        $PathFull=$MyMockupDir+( $PathRaw.replace('/','\') )
        $AccountRaw=$PathRaw.split('/')
        $AccountFull=$AccountRaw[$AccountRaw.count-1]   # Get the last serial number from the item
        write-host "The path is $PathFull and the Accountname is $AccountFull"
        $Data = ( Get-SFAccount $AccountFull | convertTo-JSON -depth 10) 
        WriteA-File -FileData $Data -Folder $PathFull
    }

    $Data=( Get-SFAccountRoleCol | convertTo-JSON -depth 10) 
    WriteA-File -FileData $Data -Folder ( $RedfishRoot+'\AccountService\Roles' )
    
    $MyRoles = $(Get-SFAccountRoleCol).Members
    foreach ($MyRole in $MyRoles)
    {   $PathRaw=$MyRole.'@odata.id'
        $PathFull=$MyMockupDir+( $PathRaw.replace('/','\') )
        $RoleRaw=$PathRaw.split('/')
        $RoleFull=$RoleRaw[$RoleRaw.count-1]   # Get the last serial number from the item
        write-host "The path is $PathFull and the Rolename is $RoleFull"
        $Data = ( Get-SFAccountRole $RoleFull | convertTo-JSON -depth 10) 
        WriteA-File -FileData $Data -Folder $PathFull
    }
    
# EVENTS ####
    $Data=( Get-SFEventServiceRoot | convertTo-JSON -depth 10) 
    WriteA-File -FileData $Data -Folder ( $RedfishRoot+'\EventService' )

    $Data=( Get-SFEventCol | convertTo-JSON -depth 10) 
    WriteA-File -FileData $Data -Folder ( $RedfishRoot+'\EventService\Events' )
    
    $MyEvents = $(Get-SFEventCol).Members
    foreach ($MyEvent in $MyEvents)
    {   $PathRaw=$MyEvent.'@odata.id'
        $PathFull=$MyMockupDir+( $PathRaw.replace('/','\') )
        $EventRaw=$PathRaw.split('/')
        $EventFull=$EventRaw[$EventRaw.count-1]   # Get the last serial number from the item
        write-host "The path is $PathFull and the Event is $EventFull"
        $Data = ( Get-SFEvent $EventFull | convertTo-JSON -depth 10) 
        WriteA-File -FileData $Data -Folder $PathFull
    }

# CHASSIS ####
    $Data=( Get-SFChassisRoot | convertTo-JSON -depth 10) 
    WriteA-File -FileData $Data -Folder ( $RedfishRoot+'\Chassis' )

    $MyChassisCollection=$(Get-SFChassisRoot).Members
    foreach ($MyChassis in $MyChassisCollection)
    {   $PathRaw=$MyChassis.'@odata.id'
        $PathNew=$PathRaw.replace('/','\')
        $PathFull=$MyMockupDir+( $PathRaw.replace('/','\') )
        $Split=$PathRaw.split('/')
        $SplitFull=$Split[$Split.count-1]   # Get the last serial number from the item
        write-host "The path is $PathFull and the Serial is $SplitFull"
        $Data= ( Get-SFChassis $SplitFull | convertTo-JSON -depth 10) 
        WriteA-File -FileData $Data -Folder $PathFull

        $Data = ( Get-SFChassisPowerRoot $SplitFull | convertTo-JSON -depth 10)
        WriteA-File -FileData $Data -Folder ( $PathFull+'\Power' )

        $MyPS = ( Get-SFChassisPowerSupplyRoot $SplitFull | convertTo-JSON -depth 10)
        WriteA-File -FileData $MyPS -Folder ( $PathFull+'\Power\PowerSupplies' )
        
        $MyPSs = ( Get-SFChassisPowerSupplyRoot -Shelfname $NimbleSerial ).members
        foreach($MyPS in $MyPSs)
        {   $PathDRaw=$MyPS.'@odata.id'
            $PathDFull=$MyMockupDir+($PathDRaw.replace('/','\') ) 
            $DSplit=$PathDRaw.split('/')
            $ItemNum=$DSplit[$DSplit.count-1]   # Get the item name from the item
            write-host "The path is $PathDFull and the PS Number  is $ItemNum"
            $Data= ( Get-SFChassisPowerSupplies -Shelfname $NimbleSerial -PSNum $ItemNum | convertTo-JSON -depth 10) 
            WriteA-File -FileData $Data -Folder $PathDFull
        }

        $Data = ( Get-SFChassisThermal $SplitFull | convertTo-JSON -depth 10)
        WriteA-File -FileData $Data -Folder ( $PathFull+'\Thermal' )
    
        $Data = ( Get-SFDriveRoot $SplitFull | convertTo-JSON -depth 10)
        WriteA-File -FileData $Data -Folder ( $PathFull+'\Drives' )
        write-host "MySplitname = $SplitFull"
        $MyDrives = $(Get-SFDriveRoot $SplitFull).Members
        write-host "My Drives = "
        $MyDrives | out-string
        foreach ($MyDrive in $MyDrives)
        {   $PathDRaw=$MyDrive.'@odata.id'
            $PathDFull=$MyMockupDir+($PathDRaw.replace('/','\') ) 
            $DSplit=$PathDRaw.split('/')
            $DSplitFull=$DSplit[$DSplit.count-1]   # Get the last drive name from the item
            write-host "The path is $PathDFull and the Serial is $DSplitFull"
            $Data= ( Get-SFdrive -shelfser $SplitFull -DiskName $DSplitFull | convertTo-JSON -depth 10) 
            WriteA-File -FileData $Data -Folder $PathDFull
        }
    }

# Fabrics
    $Data=( Get-SFFabricRoot | convertTo-JSON -depth 10) 
    WriteA-File -FileData $Data -Folder ( $RedfishRoot+'\Fabrics' )

    $MyArrays = $(Get-SFFabricRoot).Members
    foreach($MyArray in $MyArrays)
    {   $PathRaw=$MyArray.'@odata.id'
        $MyArrayPath=$MyMockupDir+( $PathRaw.replace('/','\') )
        $Split=$PathRaw.split('/')
        $MyArraySerial=$Split[$Split.count-1]   # Get the last drive name from the item
        write-host "The path is $MyArrayPath and the Serial is $MyArraySerial"
        $Data= ( Get-SFFabric $MyArraySerial | convertTo-JSON -depth 10) 
        WriteA-File -FileData $Data -Folder $MyArrayPath
    
        # Endpoints
        Remove-Variable -name Data -erroraction silentlycontinue  
        $Data= ( Get-SFEndpointRoot | convertTo-JSON -depth 10) 
        WriteA-File -FileData $Data -Folder ( $MyArrayPath+'\Endpoints' )

        $MyEndpoints= $(Get-SFEndpointRoot).Members
        foreach($MyEndpoint in $MyEndpoints)
        {   $PathRaw=$MyEndpoint.'@odata.id'
            $MyEPPath=$MyMockupDir+( $PathRaw.replace('/','\') )
            $Split=$PathRaw.split('/')
            $MyEP=$Split[$Split.count-1]   # Get the last drive name from the item
            write-host "The path is $MyEPPath and the Endpoint is $MyEP"
            $Data = ( Get-SFEndpoint $MyEP | convertTo-JSON -depth 10) 
            WriteA-File -FileData $Data -Folder $MyEPPath
        }
        # Zones (Initiator Groups)
        $Data= ( Get-SFZoneRoot | convertTo-JSON -depth 10) 
        WriteA-File -FileData $Data -Folder ( $MyArrayPath+'\Zones' )
        $MyZones= $(Get-SFZoneRoot).Members
        foreach($MyZone in $MyZones)
        {   $PathRaw=$MyZone.'@odata.id'
            $MyZonePath=$MyMockupDir+( $PathRaw.replace('/','\') )
            $Split=$PathRaw.split('/')
            $MyZoneName=$Split[$Split.count-1]   # Get the last drive name from the item
            write-host "The path is $MyZonePath and the Endpoint is $MyZoneName"
            $Data = ( Get-SFZone $MyZoneName | convertTo-JSON -depth 10)
            if ($Data) 
                {   WriteA-File -FileData $Data -Folder $MyZonePath
                }
        }

        # Connections (Acccess Maps)
        $Data= ( Get-SFStorageGroupRoot | convertTo-JSON -depth 10) 
        WriteA-File -FileData $Data -Folder ( $MyArrayPath+'\Connections' )
        $MySGs= $(Get-SFStorageGroupRoot).Members
        foreach($MySG in $MySGs)
                {   $PathRaw=$MySG.'@odata.id'
                    $MySGPath=$MyMockupDir+( $PathRaw.replace('/','\') )
                    $Split=$PathRaw.split('/')
                    $MySG=$Split[$Split.count-1]   # Get the last drive name from the item
                    $Data = ( Get-SFStorageGroup $MySG | convertTo-JSON -depth 10) 
                    write-host "The path is $MySGPath and the Endpoint is $MySG"
                    WriteA-File -FileData $Data -Folder $MySGPath
                }
    }

# StorageSystem ####
    $Data=( Get-SFStorageSystemRoot | convertTo-JSON -depth 10) 
    WriteA-File -FileData $Data -Folder ( $RedfishRoot+'\Storage' )

    $MyArrays = $(Get-SFStorageSystemRoot).Members
    foreach($MyArray in $MyArrays)
    {   $PathRaw=$MyArray.'@odata.id'
        $MyArrayPath = $MyMockupDir+( $PathRaw.replace('/','\') )
        $Split=$PathRaw.split('/')
        $MyArraySerial=$Split[$Split.count-1]   # Get the last drive name from the item
        write-host "The path is $MyArrayPath and the Serial is $MyArraySerial"
        $Data= ( Get-SFStorageSystem $MyArraySerial | convertTo-JSON -depth 10) 
        WriteA-File -FileData $Data -Folder $MyArrayPath

        # Storage Controllerss
        $Data=( Get-SFStorageControllerRoot | convertTo-JSON -depth 10) 
        WriteA-File -FileData $Data -Folder ( $MyArrayPath+'\StorageControllers' )
        
        $MyPools= $(Get-SFStorageControllerRoot).Members
        foreach($MyPool in $MyPools)
        {   $PathRaw=$MyPool.'@odata.id'
            $MySPGPath=$MyMockupDir+( $PathRaw.replace('/','\') )
            $Split=$PathRaw.split('/')
            $MySPG=$Split[$Split.count-1]   # Get the last drive name from the item
            write-host "The path is $MySPGPath and the StoragePool is $MySPG"
            $Data = ( Get-SFStorageController $MySPG | convertTo-JSON -depth 10) 
            WriteA-File -FileData $Data -Folder $MySPGPath
        }

        # Storage Pools
        $Data=( Get-SFPoolRoot | convertTo-JSON -depth 10) 
        WriteA-File -FileData $Data -Folder ( $MyArrayPath+'\StoragePools' )
        
        $MyPools= $(Get-SFPoolRoot).Members
        foreach($MyPool in $MyPools)
        {   $PathRaw=$MyPool.'@odata.id'
            $MySPGPath=$MyMockupDir+( $PathRaw.replace('/','\') )
            $Split=$PathRaw.split('/')
            $MySPG=$Split[$Split.count-1]   # Get the last drive name from the item
            write-host "The path is $MySPGPath and the StoragePool is $MySPG"
            $Data = ( Get-SFPool $MySPG | convertTo-JSON -depth 10) 
            WriteA-File -FileData $Data -Folder $MySPGPath
        }
        # Volumes
        $Data=( Get-SFVolumeRoot | convertTo-JSON -depth 10) 
        WriteA-File -FileData $Data -Folder ( $MyArrayPath+'\Volumes' )
        
        $MyVols= $(Get-SFVolumeRoot).Members
        foreach($MyVol in $MyVols)
        {   $PathRaw=$MyVol.'@odata.id'
            $MyVolPath=$MyMockupDir+( $PathRaw.replace('/','\') )
            $Split=$PathRaw.split('/')
            $MyVolSplit=$Split[$Split.count-1]   # Get the last drive name from the item
            write-verbose "The path is $MyVolPath and the Volume is $MyVolSplit"
            $Data = ( Get-SFVolume $MyVolSplit -Experimental $True | convertTo-JSON -depth 10) 
            WriteA-File -FileData $Data -Folder $MyVolPath

            # Snapshots
            $Data= ( Get-SFVolume $MyVolSplit -Experimental $True)
            if ( $Data.Snapshots )
            {   $Data= ( Get-SFSnapshotIndex $MyVolSplit | ConvertTo-JSON -depth 10 )
                WriteA-File -FileData $Data -Folder ($MyVolPath+'\snapshots')
                   
                $MySnaps = ( Get-SFSnapshotIndex $MyVolSplit).Members
                foreach( $MySnap in $MySnaps)
                {   $PathRaw=$MySnap.'@odata.id'
                    $MySnapPath=$MyMockupDir+( $PathRaw.replace('/','\') )
                    $Split=$PathRaw.split('/')
                    $MySnapSplit=$Split[$Split.count-1]   # Get the last drive name from the item
                    write-verbose "The path is $MySnapPath and the Snapshot is $MySnapSplit in volume $MyVolSplit"
                    $Data = ( Get-SFSnapshot -VolName $MyVolSplit -SnapId $MySnapSplit | convertTo-JSON -depth 10) 
                    WriteA-File -FileData $Data -Folder $MySnapPath
                }
            }
        }

        # Consistency Groups
        $Data=( Get-SFConsistencyGroupRoot | convertTo-JSON -depth 10) 
        WriteA-File -FileData $Data -Folder ( $MyArrayPath+'\ConsistencyGroups' )
        
        $MyCGs= $(Get-SFConsistencyGroupRoot).Members
        foreach($MyCG in $MyCGs)
        {   $PathRaw=$MyCG.'@odata.id'
            $MyCGPath=$MyMockupDir+( $PathRaw.replace('/','\') )
            $Split=$PathRaw.split('/')
            $MyCG=$Split[$Split.count-1]   # Get the last drive name from the item
            write-host "The path is $MyCGPath and the ConsistencyGroupRoot is $MyCG"
            $Data = ( Get-SFConsistencyGroup $MyCG | convertTo-JSON -depth 10) 
            WriteA-File -FileData $Data -Folder $MyCGPath
        }
        
        # Lines of Service
        $Data=( Get-SFLinesOfServiceRoot | convertTo-JSON -depth 10) 
        WriteA-File -FileData $Data -Folder ( $MyArrayPath+'\LinesOfService' )
        
        $Data=( Get-SFDataProtectionLoSRoot | convertTo-JSON -depth 10) 
        WriteA-File -FileData $Data -Folder ( $MyArrayPath+'\LinesOfService\DataProtectionLinesOfService' )
        
        $MyDPLOSs= $(Get-SFDataProtectionLoSRoot).Members
        foreach($MyDPLOS in $MyDPLOSs)
        {   $PathRaw=$MyDPLOS.'@odata.id'
            $MyDPLOSPath=$MyMockupDir+( $PathRaw.replace('/','\') )
            $Split=$PathRaw.split('/')
            $MyDPLOSSplit=$Split[$Split.count-1]   # Get the last drive name from the item
            write-host "The path is $MyDPLOSPath and the Data Protection Lines of Service is $MyDPLOSSplit"
            $Data = ( Get-SFDataProtectionLoS $MyDPLOSSplit | convertTo-JSON -depth 10) 
            WriteA-File -FileData $Data -Folder $MyDPLOSPath
        }
    }