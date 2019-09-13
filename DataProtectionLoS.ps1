function Create-DPLOS {	
	param( 	$ProtectionSchedules	
		 )
	$Members=@()
	foreach ($PS in $ProtectionSchedules)
		{	$LocalMembers = @( @{	'@odata,id'		=	'/redfish/v1/StorageServices/'+$NimbleSerial+'/DataProtectionLineOfService/'+$PS.id
                                }
                             )
			$Members+=$localMembers
		}
	$PSRoot = @{	'@odata.Copyright'		=	$SwordfishCopyright;
					'@odata.context'		=	'/redfish/v1/$metadata#StorageServices/'+$NimbleSerial+'/DataProtectionLineOfService';
					'@odata.id'				=	'/redfish/v1/StorageServices/'+$NimbleSerial+'/DataProtectionLineOfService';
					'@odata.type'			=	'#DataProtectionLineOfService_1_0_0.DataProtectionLineOfService';
					Name					=	'Nimble Protection Policies';
					'Members@odata.count'	=	($ProtectionSchedules).count;
					Members					=	@( $Members )
			   }	
    FolderAndFile $PSRoot ("StorageServices\"+$NimbleSerial+"\DataProtectionLinesOfService")
}
		
function Create-DPLOSIndex {
    param( 	$VolumeCollections,
			$ProtectionSchedules	
		 )
	foreach ($PS in $ProtectionSchedules)
		{	switch($PS.period_unit)
			{	'minutes'	{	$RPO 		= $PS.period * 60
							}
				'hours'		{	$RPO 		= $PS.period * 60 * 60
							}
				'days'		{	$RPO 		= $PS.period * 60 * 24
								foreach($day in $PS.days)
								{	$DaysOfWeek=@()
									if ($day -eq 'all')
									{	$DaysOfWeek+='Every'
									} else
									{	$DaysOfWeek+=$Day
									}
								}
							}
				'weeks'		{	$RPO 		= $PS.period * 60 * 24 * 7
							}
			}
	
			$RepeatInterval='R'+$PS.num_retain
			# if ($PS.period -eq 'Hours')
			$volset=@()
			foreach($volcol in $VolumeCollections)
			{	if ($volcol.id -eq $PS.volcoll_or_prottmpl_id)
				{	foreach($vol in $volcol.volume_list)
					{	$Volset+=@{		Volume		=	'/redfish/v1/StorageServices/'+$NimbleSerial+'/Volumes/'+$vol.name 	
			}	}	}			  }
		
			$PSG = @{	
						title					= 	"#DataProtectionLoSCapabilities.v1_1_3.DataProtectionLoSCapabilities"
						'@odata.Copyright'    	= 	$SwordfishCopyright;
						'@odata.context'        =	'/redfish/v1/$metadata#StorageGroup/'+$NimbleSerial+'/DataProtectionLineOfService';
						'@odata.id'             =	'/redfish/v1/StorageServices/'+$NimbleSerial+'/DataProtectionLineOfService/'+$PS.id;
						'@odata.type'           =	'#DataProtectionLineOfService.v1_0_0.DataProtectionLineOfService';
						Name                    =	$PS.name;
						Description             =	$PS.description;
						Schedule				=	@{	$PS.period_unit				=	$DaysOfWeek;
													 }
                        MappedVolumes           =   @( $volset
                                                     );
						Id                      =   $PS.id;
						ReplicaType				=	'Snapshot';
						RecoveryPointObjective	=	$RPO;
						RecoveryTimeObjective	=	0

					}
            FolderAndFile $PSG $("StorageServices\"+$NimbleSerial+"\DataProtectionLinesOfService\"+$PS.id)
		}
}