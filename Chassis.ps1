function Create-ChassisRoot {
	param(	$Shelfs
		 )

	$Members=@{}
	foreach ($Shelf in $Shelfs)
		{	$Members += @{ '@odata.id' = "/redfish/v1/Chassis/"+$Shelf.Serial }
			FolderAndFile -FolderNames ("Chassis\"+$Shelf.Serial)
		}
	$Chassis=@{	'@Redfish.Copyright' 	= 	$RedfishCopyright;
				'@odata.type'			=	"#ChassisCollection.ChassisCollection";
				name					=	"Chassis Collection";
				Members		 			=	$Members ;
				'Members@odata.count' 	= 	$Shelfs.count ;
				'@odata.context'		= 	'/redfish/v1/$metadata#ChassisCollection';
				'@odata.id'				=	'/redfish/v1/Chassis'
			  }
	FolderAndFile $Chassis ("Chassis")
}

function Create-Chassis {
	param(	$Shelf
			)
	process
	{	if ( ($shelf.psu_overall_status -like "OK") -and ($shelf.fan_overall_status -like "OK") -and ($shelf.temp_overall_status -like "OK") )
			{ 	$NimbleShelfLED="OK" 	} else 
			{	$NimbleShelfLED="Fault"	}
		$DriveObj=@{}
		$DriveArray=@{}
		$ShelfObj=@{	"@Redfish.Copyright" 	= $RedfishCopyright;
						"@odata.context" 		= '/redfish/v1/$metadata#Chassis/Members/$entity';
						"@odata.id"				= "/redfish/v1/Chassis/"+$Shelf.serial;
						"@odata.type"			= "#Chassis.1.0.0.Chassis";
						Id						= $Shelf.id;
						Name					= $Shelf.serial;
						ChassisType				= $Shelf.chassis_type;
						Manufacturer			= "HPE-Nimble";
						Model					= $Shelf.model;
						SKU						= $Shelf.model_ext;
						SerialNumber			= $Shelf.serial;
						PartNumber				= $Shelf.model_ext;
						IndicatorLED			= $NimbleShelfLED;
						Status					= @{	State 				= "Enabled";
														Health				= $NimbleShelfLED	
												   };
						Thermal					= @{	'@odata.id'			= "/redfish/v1/Chassis/"+$Shelf.serial+"/Thermal"	
												   };
						Power					= @{	'@odata.id'			= "/redfish/v1/Chassis/"+$Shelf.serial+"/Power"	
												   };
						Drives					= @{	'@odata.id'			= "/redfish/v1/Chassis/"+$Shelf.Serial+"/Drives"
												   };
						Links					= @{	'StorageSystems'	= "/redfish/v1/StorageSystem/"+$Array.serial}
				    }							   		
		FolderAndFile -FolderNames ("Chassis\"+$Shelf.serial+"\Drives")
		FolderAndFile $ShelfObj ("Chassis\"+$Shelf.serial)
}   }

function CreateChassisFolderPower {
	param(	$Shelf
		 )
	if ($NimbleShelfPowerStatus -like 'ok') 
		{	$NimbleShelfEnabled = "Enabled" } 
		else 
		{	$NimbleShelfEnabled = "Faulted" }
	$PowerSupplyObj=@()
	$PSCount=1
	foreach ($PS in ($Shelf).chassis_sensors )
		{	if ( $($PS.status) -like 'OK' ) 
				{ $LocalState="Enabled" } 
				else 
				{ $LocalState="Faulted" }
			$PowerSupply= @{	'@odata.id'			=	"/redfish/v1/Chassis/"+$Shelf.serial+"/Power/PowerSupplies/"+$PSCount;
								'@Redfish.Copyright'= 	$RedfishCopyright;
								'@odata.context'	=	'/redfish/v1/$metadata#Power.Power';
								MemberID			= 	$PSCount;
								Status				= 	@{		State	= $LocalState;
																Health	= $PS.Status
											 	 	 	 };
								Manufacturer		= 	"HPE-Nimble"
						   }
			$PowerSupplyObj+=$PowerSupply
			$PSCount+=1
		}	
	$PowerObj=@{	'@odata.type'			= 	"#Power.v1_1_0.Power";
					'@Redfish.Copyright'	= 	$RedfishCopyright;
					'@odata.context'		= 	'/redfish/v1/$metadata#Power.Power';
					'@odata.id'				= 	"/redfish/v1/Chassis/"+$Shelf.serial+"/Power";
					Id						= 	$Shelf.ID;
					Name					= 	"NimbleShelfPower";
					PowerControl			= 	@{	'@odata.id'	= 	"/redfish/v1/Chassis/"+$Shelf.serial+"/Power#/PowerControl/0";
													MemberID	= 	0;
													Status 		= 	@{	State	=	$NimbleShelfEnabled;
																		Health	=	$NimbleShelfPowerStatus
															 		 }
									   		     };
					PowerSupplies			= 	$PowerSupplyObj
			   }
	FolderAndFile $PowerObj ("Chassis\"+$Shelf.serial+"\Power")
}

function CreateChassisFolderThermal {
	param(	$Shelf
		 )
	$TempsObj=@()
	$FansObj=@()
	$TmemberID=0
	$FmemberID=1
	foreach ($ctrlrs in $Shelf.ctrlrs )
	{	foreach ($sensor in $ctrlrs.ctrlr_sensors)
		{	if ( $sensor.type -like "temperature" )
			{	if ( $sensor.status -eq 'OK' ) 
					{	$LocalState="Enabled"	} else
					{	$LocalState="Disabled"	}
				$TempObj=	@{	'@odata.id'		=	"/redfish/v1/Chassis/"+$Shelf.Serial+"/Thermal#/Temperatures/"+$TMemberID;
								MemberId		=	$TMemberID;
								Name			=	$Sensor.name
								Status			=	@{	State	=	$LocalState;
														Health	=	$Sensor.Status
												 	 };
								ReadingCelsius	=	$Sensor.value;
								PhysicalContext	=	"ChassisSocket"+$Sensor.cid+"_"+$Sensor.Location
							 }
				$TMemberID+=1
				$TempsObj+=$TempObj
			}
			if 	( $sensor.type -like "fan" )
			{	if ( $sensor.status -eq 'OK' ) 
					{	$LocalState="Enabled"	} else
					{	$LocalState="Disabled"	}
				$FanObj=	@{	'@odata.id'		=	"/redfish/v1/Chassis/"+$Shelf.serial+"/Thermal#/Fans/$FMemberID"
								MemberId		=	$FMemberID
								Name			=	$Sensor.name
								Status			=	@{	State	=	$LocalState;
														Health	=	$Sensor.Status
												 	 };
								ReadingCelsius	=	$Sensor.value;
								PhysicalContext	=	"ChassisSocket"+$Sensor.cid+"_"+$Sensor.Location
							 }
				$FansObj+=$FanObj
				$FMemberID+=1
			}	
		}
	}
	$ThermalObj=@{	'@odata.type'			= 	"#Thermal.1.0.0.Thermal";
					'@Redfish.Copyright'	= 	$RedfishCopyright;
					'@odata.context'		= 	'/redfish/v1/$metadata#Chassis/Members/'+$Shelf.serial+'/Thermal';
					'@odata.id'				= 	"/redfish/v1/Chassis/"+$Shelf.serial+"/Thermal";
					Id						= 	"Thermal";
					Name					= 	"NimbleShelfThermal";
					Temperatures			=	$TempsObj;
					Fans					=	$FansObj
				 }
	FolderAndFile $ThermalObj ("Chassis\"+$Shelf.serial+"\Thermal")
}