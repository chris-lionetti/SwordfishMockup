function Get-SFChassisRoot {
	param(	
		 )
	$Members=@{}
	$Shelfs = (Get-NSShelf)
	foreach ($Shelf in $Shelfs)
		{	$Members += @{ '@odata.id' = "/redfish/v1/Chassis/"+($Shelf.Serial) 
					     }
		}
	$Chassis=[ordered]@{	'@Redfish.Copyright' 	= 	$RedfishCopyright;
							'@odata.type'			=	"#ChassisCollection.ChassisCollection";
							'@odata.id'				=	'/redfish/v1/Chassis';
							Name					=	"Chassis Collection";
							'Members@odata.count' 	= 	1;
							Members		 			=	@( $Members )
					   }
	return $Chassis	
}

function Get-SFChassis{
param(	$ShelfName
	 )
process	{	$Shelf = ( Get-NSShelf | where-object {$_.serial -like $ShelfName } )
			if ( ($shelf.psu_overall_status -like "OK") -and ($shelf.fan_overall_status -like "OK") -and ($shelf.temp_overall_status -like "OK") )
				{ 	$NimbleShelfLED="Lit" 	
				} else 
				{	$NimbleShelfLED="Off"	
				}
			if ( $NimbleShelfLED -eq "Lit" )
				{	$NimbleHealthStatus = "OK" 
				} else 
				{	$NimbleHealthStatus = "Warning" 
				}
			# Valid States for Redfish are; Enabled, Disabled, StandbyOffline, StandbySpare, InTest, Starting, Absent, UnavailableOffline, Deferring, Quiesced, Updating, Qualified
			# Value Health for Redfish are; OK, Critical, Warning
			if ( ($Shelf.chassis_sensors)[0].status -eq 'OK' -and ($Shelf.chassis_sensors)[1].status -eq "OK")
				{	$ShelfStatus = @{	State	=	'Enabled';
										Health 	=	'OK'
			  						};
				} else 
				{	$ShelfStatus = @{	State	=	'Disabled';
										Health 	=	'Warning'
			  						};	
				}
			$ShelfObj=[ordered]@{
							"@Redfish.Copyright" 	= $RedfishCopyright;
							"@odata.id"				= '/redfish/v1/Chassis/'+($Shelf.serial);
							"@odata.type"			= '#Chassis.v1_11_0.Chassis';
							Id						= ($Shelf.serial);
							Name					= ($Shelf.id);
							ChassisType				= "Shelf";
							Manufacturer			= "HPE-Nimble";
							Model					= ($Shelf.model);
							SKU						= ($Shelf.model_ext);
							SerialNumber			= ($Shelf.serial);
							PartNumber				= ($Shelf.model_ext);
							IndicatorLED			= $NimbleShelfLED;
							PowerState				= 'On';
							EnvironmentalClass		= 'A2';
							Status					= $ShelfStatus;
							Thermal					= @{	'@odata.id'	= '/redfish/v1/Chassis/'+($Shelf.serial)+'/Thermal'	
													   };
							Power					= @{	'@odata.id'	= '/redfish/v1/Chassis/'+($Shelf.serial)+'/Power'	
													   };
							Drives					= @{	'@odata.id'	= '/redfish/v1/Chassis/'+($Shelf.Serial)+'/Drives'
													   };
							Links					= @{	Storage	= @{	'@odata.id'	=	'/redfish/v1/Storage/'+ $NimbleSerial
																	   }
						 							   }
						}	
			if ($Shelf)
				{	return $ShelfObj
				}
		}
}


function Get-SFChassisPowerRoot{
	param(	$Shelfname
		 )
	process{
		$Shelf = (Get-NSShelf | where-object {$_.serial -like $ShelfName })
		$NimbleShelfPowerStatus = $Shelf.psu_overall_status
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
				$PSData=(Get-NSController)
				$PowerSupply= @{	
									'@odata.id'			=	"/redfish/v1/Chassis/"+($Shelf.serial)+"/Power/PowerSupplies/"+$PSCount;
									
							   }
				$PowerSupplyObj+=$PowerSupply
				$PSCount+=1
			}	
		$PowerObj=[ordered]@{	'@Redfish.Copyright'	= 	$RedfishCopyright;
								'@odata.type'			= 	"#Power.v1_1_0.Power";
								'@odata.id'				= 	"/redfish/v1/Chassis/"+($Shelf.serial)+"/Power";
								Id						= 	($Shelf.ID);
								Name					= 	"NimbleShelfPower";
								PowerControl			= 	@( 	@{	'@odata.id'	= 	"/redfish/v1/Chassis/"+($Shelf.serial)+"/Power#/PowerControl/0";
																	MemberID	= 	"0";
																	Status 		= 	@{	State	=	$NimbleShelfEnabled;
																						Health	=	$NimbleShelfPowerStatus
																					  }
																}
															 )
								PowerSupplies			= 	$PowerSupplyObj
							   }
		if ($Shelf)
			{	return $PowerObj
			}
	}
}

function Get-SFChassisPowerSupplyRoot{
	param(	$Shelfname
		 )
	process{
		$Shelf = (Get-NSShelf | where-object {$_.serial -like $ShelfName })
		$PowerSupplyObj=@()
		$PSCount=0
		foreach ($PS in ($Shelf).chassis_sensors )
			{	$PSCount+=1
				$PowerSupply= @{	
									'@odata.id'			=	"/redfish/v1/Chassis/"+($Shelf.serial)+"/Power/PowerSupplies/"+$PSCount;									
							   }
				$PowerSupplyObj+=$PowerSupply
			}	
		$PowerObj=[ordered]@{	'@Redfish.Copyright'	= 	$RedfishCopyright;
								'@odata.type'			= 	"#PowerSupplyCollection..PowerSupplyCollection";
								'@odata.id'				= 	"/redfish/v1/Chassis/"+($Shelf.serial)+"/Power/PowerSupplies";
								Name					= 	"Power Supplies Collection";
								'Members@odata.count'	=	$PSCount;
								Members					= 	$PowerSupplyObj;
							}
		if ($Shelf)
			{	return $PowerObj
			}
	}
}

function Get-SFChassisPowerSupplies{
	param(	$Shelfname,
			$PSNum
		 )
	process{
		$Shelf 				= 	(Get-NSShelf | where-object {$_.serial -like $ShelfName })
		$RedundancySet		=	@()
		$PSCount			=	1
		foreach ($PS in ($Shelf).chassis_sensors )
			{	$RedundancySet+= 	@{ '@odata.id'	="/redfish/v1/Chassis/"+($Shelf.serial)+"/Power/PowerSupplies/"+$PSCount	
									 };
				$PSCount+=1
			}
		if ( $($PS.status) -like 'OK' ) 
			{ $LocalState="Enabled" 
			} else 
			{ $LocalState="Faulted" 
			}
		$TotalPSCount		= 	( ($Shelf).chassis_sensors).count
		$RedundancyObject	=	@{ 	MaxNumSupported		=	$TotalPSCount ;
									MinNumNeeded		=	$TotalPSCount-1;
									Mode				=	'N+1';
									Name				=	$PSNum;
									RedundancyEnabled	=	$True;
									RedundancySet		=	$RedundancySet;
									Status				= 	@{		State	= $LocalState;
																	Health	= ($PS.Status)
															 }
								 }
		$PSCount			=	1
		foreach ($PS in ($Shelf).chassis_sensors )
			{	
				if ( $($PS.status) -like 'OK' ) 
					{ $LocalState="Enabled" } 
					else 
					{ $LocalState="Faulted" }
				$PowerSupply= @{	'@Redfish.Copyright'= 	$RedfishCopyright;
									'@odata.id'			=	"/redfish/v1/Chassis/"+($Shelf.serial)+"/Power/PowerSupplies/"+$PSCount;
									MemberID			= 	"$PSCount";
									Status				= 	@{		State	= $LocalState;
																	Health	= ($PS.Status)
															 };
									Manufacturer		= 	"HPE-Nimble";
									Name				=	$PS.Name;
									Description			=	$PS.name+" Located in "+$PS.location+" of Chassis";
									InputRanges			=	@(	@{	InputType		=	"AC";
																	MinimumVoltage	=	100;
																	MaximumVoltage	=	120;
																	OutputWattage	=	900;
																	MinimumFrequency=	50;
																	Maximumfrequency=	60
																 };
																@{ 	InputType		=	"AC";
																	MinimumVoltage	=	200;
																	MaximumVoltage	=	240;
																	OutputWattage	=	900;
																	MinimumFrequency=	50;
																	Maximumfrequency=	60
																 }
															 );
									RedundancySet		=	$RedundancyObject							 
							   }
				if ( $Shelf -and ( $PSNum -like $PSCount ) )
					{	return $PowerSupply
					}
				$PSCount+=1
			}			
	}
}

function Get-SFChassisThermal {
	param(	$ShelfName
		 )
	$TempsObj=@()
	$FansObj=@()
	$TmemberID=0
	$FmemberID=1
	$Shelf = (Get-NSShelf | where-object {$_.serial -like $ShelfName })
	foreach ($ctrlrs in $Shelf.ctrlrs )
	{	foreach ($sensor in $ctrlrs.ctrlr_sensors)
		{	if ( $sensor.type -like "temperature" )
			{	if ( $sensor.status -eq 'OK' ) 
					{	$LocalState="Enabled"	} else
					{	$LocalState="Disabled"	}
				$TempObj=[ordered]@{	'@odata.id'		=	"/redfish/v1/Chassis/"+($Shelf.Serial)+"/Thermal#/Temperatures/"+$TMemberID;
										'@odata.type'	=	"#Thermal.v1_6_0.Thermal"
										MemberId		=	$TMemberID;
										Name			=	($Sensor.name);
										Status			=	@{	State	=	$LocalState;
																Health	=	($Sensor.Status)
														 	 };
										ReadingCelsius	=	($Sensor.value);
										PhysicalContext	=	"ChassisSocket"+($Sensor.cid)+"_"+($Sensor.Location)
							 		}
				$TMemberID+=1
				$TempsObj+=$TempObj
			}
			if 	( $sensor.type -like "fan" )
			{	if ( $sensor.status -eq 'OK' ) 
					{	$LocalState="Enabled"	} else
					{	$LocalState="Disabled"	}
				$FanObj=[ordered]@{	'@odata.id'		=	"/redfish/v1/Chassis/"+($Shelf.serial)+"/Thermal#/Fans/$FMemberID";
									MemberId		=	$FMemberID;
									Name			=	($Sensor.name);
									Status			=	@{	State	=	$LocalState;
															Health	=	($Sensor.Status)
													 	 };
									ReadingCelsius	=	($Sensor.value);
									PhysicalContext	=	"ChassisSocket"+($Sensor.cid)+"_"+($Sensor.Location)
								 }
				$FansObj+=$FanObj
				$FMemberID+=1
			}	
		}
	}
	$ThermalObj=[ordered]@{	'@Redfish.Copyright'	= 	$RedfishCopyright;
							'@odata.type'			= 	"#Thermal.v1_0_0.Thermal";
							'@odata.id'				= 	"/redfish/v1/Chassis/"+($Shelf.serial)+"/Thermal";
							Id						= 	"Thermal";
							Name					= 	"NimbleShelfThermal";
							Temperatures			=	$TempsObj;
							Fans					=	$FansObj
						 }
	if ($Shelf)
		{ Return $ThermalObj
		}
}