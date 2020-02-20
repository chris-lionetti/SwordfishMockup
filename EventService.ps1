function Get-SFEventServiceRoot {	
    param()
    process{
        $EventRoot = [ordered]@{
                        '@Redfish.Copyright'	= 	$RedfishCopyright;
                        '@odata.context'		=	'/redfish/v1/$metadata#EventService.EventService';
                        '@odata.id'				=	'/redfish/v1/EventService';
                        '@odata.type'			=	'#EventService.v1_0_0.EventService';
                        Name					=   'Event Service';
                        Id                      =   'Event Service';
                        ServiceEnabled          =   'True';
                        Status                  =   @{  State   =  'Enabled';
                                                        Health  =  'OK' 
                                                     };
                        Events                  =   @{  '@odata.id' =   '/redfish/v1/EventService/Events'   }
                               }
        return $EventRoot
    }
}

function Get-SFEventCol {	
    param()
    process{
        $Members=@()
        $Events=( Get-NsEvent -severity 'warning' ) + ( Get-NSEvent -severity 'critical') + ( Get-NSEvent -severity 'notice')
        foreach ($Event in $Events)
            {	$LocalMembers = @{	'@odata,id'		=	'/redfish/v1/EventService/Events/'+$event.id
                                 }
                $Members+=$localMembers
            }
        $EventCol = [ordered]@{
                        '@Redfish.Copyright'	= 	$RedfishCopyright;
                        '@odata.context'		=	'/redfish/v1/$metadata#Event.Event';
                        '@odata.id'				=	'/redfish/v1/EventService/Event';
                        '@odata.type'			=	'#Event.Event';
                        Name					=   'Event Collection';
                        Id                      =   'Event Collection';
                        Events                  =   $Members
                             }
        if ( $Events )  { return $EventCol 
                        } else 
                        { return 
                        }
    }
}

function Get-SFEvent {
    param ( $EventId 
          )
    process{   
        $event= ( Get-NSEvent -id $EventId )
        if (Get-NSEvent -id $EventId)
            {   $Event =  [ordered]@{   '@Redfish.Copyright'	= 	$RedfishCopyright;
                                        '@odata.context'		=	'/redfish/v1/$metadata#Event.Event';
                                        '@odata.id'				=	'/redfish/v1/EventService/Event/'+$event.id;
                                        '@odata.type'			=	'#Event.Event';
                                        Name					=   'Event Array';
                                        Id                      =   $event.id;
                                        Events                  =   @{  EventType   =   $event.category;
                                                                        EventId     =   $event.type;
                                                                        Severity    =   $event.severity;
                                                                        Message     =   $event.activity;
                                                                        EventTimestamp = $event.timestamp;
                                                                     }
                                    }
                return $Event
            } else 
            {   return
            }
    }
}
