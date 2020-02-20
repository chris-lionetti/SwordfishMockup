$username = "admin"                                             
                                                                # This is the Array username
$password = ConvertTo-SecureString "admin" -AsPlainText -Force  
                                                                # This is the Array Password, change admin to YOUR password
$ArrayIP  = '192.168.1.60'                                      
                                                                # This is the Array IP Address
##############################################################################################################################
$psCred = ( New-Object System.Management.Automation.PSCredential($username, $password) )
if ( -not (get-module -ListAvailable -name HPENimblePowerShellToolkit ) )
    {   Write-Error "You must first download the HPENimblePowerShelLToolkit from the Microsoft PSGallery to use this software."
        exit
    }
write-warning "Ensure that Port 5000 is currently not listened to."
([System.Net.Sockets.TcpListener]5000).Stop()
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
$Global:RedfishCopyright    =	"Copyright 2014-2016 Distributed Management Task Force, Inc. (DMTF). For the full DMTF copyright policy, see http://www.dmtf.org/about/policies/copyright."
$Global:SwordfishCopyright  =	"Copyright 2016-2019 Storage Networking Industry Association (SNIA), USA. All rights reserved. For the full SNIA copyright policy, see http://www.snia.org/about/corporate_info/copyright"
. .\Chassis.ps1                                 # These are all of the Subroutines to return the JSON. Subdivided to make troubleshooting simpler.
. .\Drives.ps1
. .\Endpoints.ps1
. .\EndpointGroups.ps1
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
$listener = New-Object System.Net.HttpListener      # Create the Listerer Object
$listener.Prefixes.Add('http://+:5000/')            # Set the listener on port 5000
$listener.Start()
Write-host 'Listening ...Go Swordfish Go.'
$DontEndYet=$True                                   # Break from loop if GET request sent to /end
while ($DontEndYet) 
{   $context    = $listener.GetContext()            # Capture the details about the request
    $request    = $context.Request                  # Setup a place to deliver a response
    $response   = $context.Response                 # Set up my object to allow me to respond
    $PageMissing=$False                             # Used if you request a page that doesnt exist. 
    $Result     = ''                                # The result should be blank until I explicity set it.
    if ($request.Url -match '/end$')                # This is the escape clause that lets you shut down the responder. 
        {   $DontEndYet=$False                      #   simply send a request to http://localhost:5000/end
        } 
    $rvar = ([String]$request.Url).split("/")       # Split request URL to get command and options. RVAR = Request Variables
    if ( -not ( $rvar[3] -eq "redfish" -and $rvar[4] -eq 'v1' ) ) 
        {   $PageMissing=$True                      # The 3rd and 4th split of the request SHOULD be redfish and V1, otherwise throw an error
        }   
    switch ($rvar.count)                            # The number of parts of the request denotes how complex a request it is.
      { 5 { $result = Get-SFRedfishRoot | ConvertTo-JSON -Depth 10      # Return the Redfish root, i.e. the request was HTTP://localhost:5000/redfish/v1 
          }
        6 { switch($rvar[5])                        # The Request has start Redfish/v1, but then must contain the following as the last element of the request
              { "Chassis"         { $result = Get-SFChassisRoot                          | ConvertTo-JSON -Depth 10  }
                "StorageSystems"  { $result = Get-SFStorageSystemRoot                    | ConvertTo-JSON -Depth 10  }
                "Systems"         { $result = Get-SFSystemRoot                           | ConvertTo-JSON -Depth 10  } 
                "AccountService"  { $result = Get-SFAccountServiceRoot                   | ConvertTo-JSON -Depth 10  }
                "EventService"    { $result = Get-SFEventServiceRoot                     | ConvertTo-JSON -Depth 10  }
              }
          }
        7 { switch($rvar[5])                         # The request will look something like HTTP://localhost:5000/redfish/v1/StorageSystem/Serial#
              { "Chassis"         { $Result = Get-SFChassis -ShelfName ($rvar[6])               | ConvertTo-JSON -Depth 10  }
                "StorageSystems"  { $Result = Get-SFStorageSystem -ArrayName ($rvar[6])         | ConvertTo-JSON -Depth 10  }
                "AccountService"  { switch($rvar[6]) # And example of this would be HTTP://localhost:5000/redfish/v1/AccountService/Roles
                                        {   "Roles"     { $result = Get-SFAccountRoleCol        | ConvertTo-JSON -Depth 10  } 
                                            "Accounts"  { $result = Get-SFAccountCol            | ConvertTo-JSON -Depth 10  }
                                        } 
                                  }  
                "EventService"    { switch($rvar[6]) # example https://localhost:5000/redfish/v1/EventService/Events
                                        {   "Events"    { $result = Get-SFEventCol              | ConvertTo-JSON -depth 10  }
                                        }
                                  }
              }
          }
        8 { switch($rvar[5])                        # THis reqest will add a subquery under the individual serial name listed in the above request
              { "Chassis"         { switch($rvar[7])# And example of this would be HTTP://localhost:5000/redfish/v1/StorageSystem/Serial#/Volumes    
                                      { "Power"     {  $result = Get-SFChassisPower -ShelfName ($rvar[6])    | ConvertTo-JSON -Depth 10 }
                                        "Thermal"   {  $result = Get-SFChassisThermal -ShelfName ($rvar[6])  | ConvertTo-JSON -Depth 10 }
                                        "Drives"    {  $result = Get-SFDriveRoot -ShelfName ($rvar[6])       | ConvertTo-JSON -Depth 10 }
                                      }
                                  }
                "AccountService"  { switch($rvar[6])# And example of this would be HTTP://localhost:5000/redfish/v1/AccountService/Roles/Guest
                                      { "Roles"     { $result = Get-SFAccountRole -RoleName ($rvar[7])       | ConvertTo-JSON -depth 10 }
                                        "Accounts"  { $result = Get-SFAccount  -AccountName ($rvar[7])       | ConvertTo-JSON -depth 10 }
                                      }
                                  }
                "EventService"    { switch($rvar[6]) # i.e. https://localhost:5000/redfish/v1/EventService/Events/1234
                                      { "Events"    { $result = Get-SFEvent -EventId ($rvar[7])              | ConvertTo-JSON -depth 10 }
                                      }
                                  }
                "StorageSystems"  { if ( (Get-NSArray).serial -like $rvar[6] )
                                      { switch($rvar[7])
                                          { "Endpoints"                     { $result = Get-SFEndpointRoot            | ConvertTo-JSON -Depth 10 }
                                            "EndpointGroups"                { $result = Get-SFEndpointGroupRoot       | ConvertTo-JSON -Depth 10 }
                                            "Volumes"                       { $result = Get-SFVolumeRoot              | ConvertTo-JSON -Depth 10 }
                                            "StorageGroups"                 { $result = Get-SFStorageGroupRoot        | ConvertTo-JSON -Depth 10 }
                                            "StoragePools"                  { $result = Get-SFPoolRoot                | ConvertTo-JSON -Depth 10 }
                                            "ConsistencyGroups"             { $result = Get-SFConsistencyGroupRoot    | ConvertTo-JSON -Depth 10 } 
                                            "LineOfService"                 { write-host "asking for LOS"
                                                                              $result = Get-SFLineOfServiceRoot       | ConvertTo-JSON -Depth 10 }                   
                                          } 
                                      }
                                }
              }
          }
        9 { switch($rvar[5])                      # This reqest will add a subquery under the individual serial name listed in the above request
                { "Chassis"         { switch($rvar[7])
                                        { "Drives"                   { $result = Get-SFDrive -shelfser ($rvar[6]) -diskname ($rvar[8]) | ConvertTo-JSON -Depth 10     }
                                        }       
                                    }               # And example of this would be HTTP://localhost:5000/redfish/v1/StorageSystem/Serial#/Volumes/VolumeID
                  "StorageSystems"  { switch($rvar[7])
                                        { "Endpoints"                   { $result = Get-SFEndpoint -EndpointName ($rvar[8])            | ConvertTo-JSON -Depth 10     }
                                          "EndpointGroups"              { $result = Get-GFEndpointGroup -EndpointGroupName ($rvar[8])  | ConvertTo-JSON -Depth 10     }
                                          "Volumes"                     { $result = Get-SFVolume -VolumeName ($rvar[8])                | ConvertTo-JSON -Depth 10     }
                                          "StorageGroups"               { $result = Get-SFStorageGroup -AccessControlName ($rvar[8])   | ConvertTo-JSON -Depth 10     }
                                          "StoragePools"                { $result = Get-SFPool -Poolname ($rvar[8])                    | ConvertTo-JSON -Depth 10     } 
                                          "ConsistencyGroups"           { $result = Get-SFConsistencyGroup -VolColname ($rvar[8])      | ConvertTo-JSON -Depth 10     }  
                                          "LineOfService"               { switch($rvar[8])
                                                                            { "DataProtectionLineOfService" 
                                                                                      { $result = Get-SFDataProtectionLoSRoot          | ConvertTo-JSON -Depth 10     }
                                                                            }
                                                                        }                   
                                        } 
                                    }
                }
            }
        10{ switch($rvar[5])
              { "StorageSystems"  { switch($rvar[7])
                                    { "Volumes"         { switch($rvar[9])
                                                            { "Snapshots"   { $result = Get-SFSnapshotIndex -VolName ($rvar[8])            | ConvertTo-JSON -depth 10 }
                                                            }
                                                        }
                                      "LineOfService"  { switch($rvar[8])
                                                            { "DataProtectionLineOfService"
                                                                            { $result = Get-SFDataProtectionLOS -PSId ($rvar[9])           | ConvertTo-JSON -depth 10 }
                                                            }
                                                        }
                                    }
                                  }
              }    
          }
        11{ switch($rvar[5])
            { "StorageSystems"  { switch($rvar[7])
                                  { "Volumes"     { switch($rvar[9])
                                                      { "Snapshots"   { $result = Get-SFSnapshot -VolName ($rvar[8]) -SnapId ($rvar[10]) | ConvertTo-JSON -depth 10      }
                                                      }
                                                  }
                                  }
                                }
            }    
        }
      }
    ############################ END Runs ###################################
    if ( $PageMissing -or ( -not $result ) )
        {   $message = "All requests should be made to http://localhost:5000/redfish/v1" # If no matching subdirectory/route is found generate a 404 message
            $response.ContentType = 'text/html'
        } else 
        {   $message = $result
            $response.ContentType = 'application/json'             
        }
    [byte[]]$buffer = [System.Text.Encoding]::UTF8.GetBytes($message)   # Convert the data to UTF8 bytes 
    $response.ContentLength64 = $buffer.length                          # Set length of response
    $output = $response.OutputStream                                    # Write response out and close
    $output.Write($buffer, 0, $buffer.length)
    $output.Close()
}    
$listener.Stop()                                                         # Assuming someone sent the END command, closing listener