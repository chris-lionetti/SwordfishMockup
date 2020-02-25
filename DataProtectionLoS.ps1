function Get-SFLinesOfServiceRoot
{	param()
	process
	{	$LOSObj=[ordered]@{
					'@odata.Copyright'		=	$SwordfishCopyright;	
					'@odata.id'				=	'/redfish/v1/StorageSystems/'+$NimbleSerial+'/LinesOfService';
					'@odata.type'			=	'#LineOfServiceCollection.LineOfServiceCollection';
					description				=	'Container for Subsequent Data Protection Services';
					longDescription			=	'Root Container for Protection Schedules implemented using Data Protection Lines of Service';
					deletable				=	'false';
					insertable				=	'false';
					updatable				=	'false';
					'members@odata.count'	=	1;
					members					=	@(	@{	'@odata.id'	=	'/redfish/v1/StorageSystems/'+$NimbleSerial+'/LinesOfSerice/DataProtectionLinesOfService'
													 }
												 )
				}
		return $LOSObj
	}
}

function Get-SFDataProtectionLoSRoot {	
param( )
process{
	$Members=@()
	$PSs = (Get-NSProtectionSchedule)
	foreach ($PS in $PSs )
		{	$LocalMembers = @( @{	'@odata.id'		=	'/redfish/v1/StorageSystems/'+$NimbleSerial+'/LinesOfService/DataProtectionLinesOfService/'+($PS.id)
                                }
                             )
			$Members+=$localMembers
		}
	$PSRoot = [ordered]@{
					'@odata.Copyright'		=	$SwordfishCopyright;
					'@odata.context'		=	'/redfish/v1/$metadata#StorageSystems/'+$NimbleSerial+'/LinesOfService/DataProtectionLinesOfService';
					'@odata.id'				=	'/redfish/v1/StorageSystems/'+$NimbleSerial+'/LineOfService/DataProtectionLineOfService';
					'@odata.type'			=	'#DataProtectionLinesOfService_1_0_0.DataProtectionLinesOfService';
					Name					=	'Nimble Protection Policies';
					'Members@odata.count'	=	($PSs).count;
					Members					=	@( $Members )
			   }	
    Return $PSRoot
}
}

Function Add-LeadingZero{
param( $InputValue
	 )
process{
	if ( [string]$InputValue.length -lt 1 )
		{	$OutValue = '0' + [string]$InputValue
		} else 
		{	$OutValue = [string]$InputValue			
		}
	return $OutValue
}
}

Function Make-ISODate{
Param(	[int]$UnixDate
	 )
process{
	$WTime=[timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($UnixDate))
	$OutYear	= [string]$WTime.year
	$Outmonth 	= Add-LeadingZero -input ( $WTime.month	) 
	$Outday 	= Add-LeadingZero -input ( $WTime.day	)
	$OutHour 	= Add-LeadingZero -input ( $WTime.hour	)
	$OutMinute 	= Add-LeadingZero -input ( $WTime.minute )
	$ISODate = $OutYear + '-' +$OutMonth + '-'+ $OutDay + 'T' + $OutHour +':' + $OutMinute + ':00'	
	return $ISODate
}
}
 
function Get-SFDataProtectionLoS {
param( 	$PSid	
	 )
process{
	$PS = ( Get-NSProtectionSchedule -id $PSid )
	if ($PS.downstream_partner -or $PS.upstream_partner)
		{	$IsIsolated  = $False
			$ReplicaType = 'Mirror'
			if ($PS.downsteam_partner)
				{	$ReplicaLocation = $PS.downstream_partner 
				} else 
				{	$ReplicaLocation = $PS.upstream_partner					
				}
		} else 
		{	$IsIsolated  = $True
			$ReplicaType = 'Snapshot'
			$ReplicaLocation = 'Local' 
		}
	$days = ($PS.days).split(',')
	$BYDY='SU,MO,TU,WE,TH,FR,SA'
	$Comma=''
	foreach ($day in $days)
	{	if ( $BYDY -ne 'SU,MO,TU,WE,TH,FR,SA' )
			{	$comma=','
			}
		Switch($PS.day)
		{	'all'		{	$BYDY = 'SU,MO,TU,WE,TH,FR,SA'	}
			'sunday'	{	$BYDY += 		'SU' 	}
			'monday'	{	$BYDY += $Comma+'MO'	}
			'tuesday'	{	$BYDY += $Comma+'TU'	}
			'wednesday'	{	$BYDY += $Comma+'WE'	}
			'thursday'	{	$BYDY += $Comma+'TH'	}
			'friday'	{	$BYDY += $Comma+'FR'	}
			'saturday'	{	$BYDY += $Comma+'SA'	}
		}	
	}
	[int]$StartTimeHour = ( $PS.at_time    / 60 ) /60
	[int]$StartTimeMin  = ( $PS.at_time    / 60 ) - $StartTimeHour * 60
	[int]$EndTimeHour 	= ( $PS.until_time / 60 ) /60
	$BYHR="$StartTimeHour"
	$StartLoop=$StartTimeHour+1
	while($StartLoop -lt $EndTimeHour)
	{	$BYHR += ','+[string]$StartLoop
		$StartLoop=$StartLoop+1
	}
	$ISOCreate = Make-ISODate -UnixDate ($PS.creation_time)
	switch($PS.period_unit)
		{	'minutes'	{	$Schedule		= 'R/'+ $ISOCreate + '/PT' + ($PS.period) + 'M/BYDY=' + $BYDY + '/BYHR=' + $BYHR
							$RPO 			= '/PT' + ($PS.period) + ':00' 
						}
			'hours'		{	$Schedule		= 'R/'+ $ISOCreate + '/PT' + ($PS.period) + 'H/BYDY=' + $BYDY + '/BYHR=' + $BYHR + '/BYMI=' +$StartTimeMin
							$RPO 			= '/PT' + ($PS.period) + ':00:00' 
						}
			'days'		{	$Schedule		= 'R/'+ $ISOCreate + '/P' + ($PS.period) + 'D/BYDY=' + $BYDY + '/BYHR=' + $StartTimeHour + '/BYMI=' +$StartTimeMin
							$RPO 			= '/P' + ($PS.period) + 'T00:00:00' 
						}
			'weeks'		{	$Schedule		= 'R/'+ $ISOCreate + '/P' + (($PS.period) * 7) + 'D/BYDY=' + $BYDY + '/BYHR=' + $StartTimeHour + '/BYMI=' +$StartTimeMin
							$RPO 			= '/P' + (($PS.period) * 7) + 'T00:00:00'
						}
		}
	$RepeatInterval='R'+$PS.num_retain
	$PSG = [ordered]@{
				'@odata.Copyright'    	= 	$SwordfishCopyright;
				'@odata.context'        =	'/redfish/v1/$metadata#StorageSystem/'+$NimbleSerial+'/LinesOfService/DataProtectionLineOfService';
				'@odata.id'             =	'/redfish/v1/StorageSystems/'+$NimbleSerial+'/LinesOfSerice/DataProtectionLineOfService/'+($PS.id);
				'@odata.type'           =	'#DataProtectionLineOfService.v1_2_0.DataProtectionLineOfService';
				Id                      =   ($PS.id);
				Name                    =	($PS.name);
				Description             =	($PS.description);
				IsIsolated				=	$IsIsolated;
				ReplicaType				=	$ReplicaType;
				ReplicaAccessLocation	=	$ReplicaLocation;
				RecoveryTimeObjective	=	0
				Schedule				=	$Schedule;
				RecoveryPointObjective	=	$RPO;
					}
	Return $PSG 
}
}