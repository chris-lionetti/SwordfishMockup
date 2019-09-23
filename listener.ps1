# Create a listener on port 8000
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add('http://+:5000/') 
$listener.Start()
'Listening ...'
 
$Base='C:\SwordfishMockup\Redfish\v1'
# Run until you send a GET request to /end
while ($true) 
{   $context = $listener.GetContext() 
    # Capture the details about the request
    $request = $context.Request
    # Setup a place to deliver a response
    $response = $context.Response
    # Break from loop if GET request sent to /end
    if ($request.Url -match '/end$') 
    {   break 
    } else 
    {   # Split request URL to get command and options
        $requestvars = ([String]$request.Url).split("/");        
        if ($requestvars[3] -eq "redfish" -and $requestvars[4] -eq 'v1') 
        {   # Get the class name and server name from the URL and run get-WMIObject
            if ($requestvars.count -eq 5)
            {   $result = get-content $Base'\index.json' -raw
                $response.ContentType = 'application/json'; 
            }
            if ($requestvars.count -eq 6)
            {   switch($requestvars[5])
                {   "Managers"        {    $direct="Managers"          }
                    "EventService"    {    $direct="EventServices"     }
                    "Systems"         {    $direct="Systems"           }
                    "SessionService"  {    $direct="SessionServices"   }
                    "Chassis"         {    $direct="Chassis"           }
                    "StorageSystems"  {    $direct="StorageSystems"    }
                    "StorageServices" {    $direct="StorageServices"   }
                    "TaskService"     {    $direct="TaskServicse"      }
                    "AccountService"  {    $direct="AccountServices"   }
                }
                $result = get-content $Base'\'$direct'\index.json' -raw
                $response.ContentType = 'application/json'; 
            }
            if ($requestvars.count -eq 7)
            {   switch($requestvars[5])
                {   "Managers"        {    $direct="Managers"          }
                    "EventService"    {    $direct="EventServices"     }
                    "Systems"         {    $direct="Systems"           }
                    "SessionService"  {    $direct="SessionServices"   }
                    "Chassis"         {    $direct="Chassis"           }
                    "StorageSystems"  {    $direct="StorageSystems"    }
                    "StorageServices" {    $direct="StorageServices"   }
                    "TaskService"     {    $direct="TaskServicse"      }
                    "AccountService"  {    $direct="AccountServices"   }
                }
                $Serial=$requestvars[6]
                #$result = get-content 'C:\SwordfishMockup\Redfish\v1\Chassis\AC-109032\index.json' -raw
                $result = get-content $Base'\'$direct'\'$Serial'\index.json' -raw
                $response.ContentType = 'application/json';  
            }
            $message = $result      
        } else 
        {   # If no matching subdirectory/route is found generate a 404 message
            $message = "All requests should be made to http://localhost:5000/redfish/v1";
            $response.ContentType = 'text/html' ;
       }
       # Convert the data to UTF8 bytes
       [byte[]]$buffer = [System.Text.Encoding]::UTF8.GetBytes($message)
       
       # Set length of response
       $response.ContentLength64 = $buffer.length
       
       # Write response out and close
       $output = $response.OutputStream
       $output.Write($buffer, 0, $buffer.length)
       $output.Close()
   }    
}
 
#Terminate the listener
$listener.Stop()
