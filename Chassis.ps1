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
							'Members@odata.count' 	= 	($Shelfs).count;
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
			$ShelfObj=[ordered]@{
							"@Redfish.Copyright" 	= $RedfishCopyright;
							"@odata.id"				= '/redfish/v1/Chassis/'+($Shelf.serial);
							"@odata.type"			= '#Chassis.v1_11_0.Chassis';
							Id						= ($Shelf.id);
							Name					= ($Shelf.serial);
							ChassisType				= "Shelf";
							Manufacturer			= "HPE-Nimble";
							Model					= ($Shelf.model);
							SKU						= ($Shelf.model_ext);
							SerialNumber			= ($Shelf.serial);
							PartNumber				= ($Shelf.model_ext);
							IndicatorLED			= $NimbleShelfLED;
							PowerState				= 'On';
							EnviornmentalClass		= 'A2';
							Status					= @{	State 		= "Enabled";
															Health		= $NimbleHealthStatus	
											   		   };
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



function Get-SFChassisPower{
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
				$PowerSupply= @{	'@Redfish.Copyright'= 	$RedfishCopyright;
									'@odata.id'			=	"/redfish/v1/Chassis/"+($Shelf.serial)+"/Power#/PowerSupplies/"+$PSCount;
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
															 )
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
								RelatedItem				=	@(	@{	'@odata.id'	=	"/redfish/v1/Chassis/"+($Shelf.serial)
																 }
															 )
							   }
		if ($Shelf)
			{	return $PowerObj
			}
	}
}
	<#
	param(	$Shelfname
		 )
	process{$Shelf = ( Get-NSShelf | where-object { $_.serial -like $ShelfName } )
   			$NimbleShelfPowerStatus = $Shelf.psu_overall_status
   			if ($NimbleShelfPowerStatus -like 'ok') 
				{	$NimbleShelfEnabled = "Enabled" 
				} else 
				{	$NimbleShelfEnabled = "Faulted" 
				}
   			$PowerSupplyObj=@()
   			$PSCount=1
   			foreach ($PS in ($Shelf).chassis_sensors )
	   			{	if ( $($PS.status) -like 'OK' ) 
						{ $LocalState="Enabled" 
						} else 
						{ $LocalState="Faulted" 
						}
		   			$PowerSupply= @{	'@Redfish.Copyright'= 	$RedfishCopyright;
							   			'@odata.id'			=	'/redfish/v1/Chassis/'+($Shelf.serial)+'/Power/PowerSupplies/'+$PSCount;
							   			MemberID			= 	$PSCount;
							   			Status				= 	@{	State	= $LocalState;
																	Health	= ($PS.Status)
														   		 };
										Manufacturer		= 	"HPE-Nimble"
									}
		   			$PowerSupplyObj+=$PowerSupply
		   			$PSCount+=1
	   			}	
   			$PowerObj=[ordered]@{	'@Redfish.Copyright'	= 	$RedfishCopyright;
						   			'@odata.type'			= 	'#Power.v1_1_0.Power';
						   			'@odata.id'				= 	'/redfish/v1/Chassis/'+($Shelf.serial)+'/Power';
						   			Id						= 	($Shelf.ID);
						   			Name					= 	"NimbleShelfPower";
						   			PowerControl			= 	@( 	@{	'@odata.id'	= 	'/redfish/v1/Chassis/'+($Shelf.serial)+'/Power#/PowerControl/0';
																		MemberID	= 	0;
															   			Status 		= 	@{	State	=	$NimbleShelfEnabled;
																						   	Health	=	$NimbleShelfPowerStatus
																				 		 }
														   			 }
																 );
						   			PowerSupplies			= 	$PowerSupplyObj
						  		}
   			if ($Shelf)
	   			{	return $PowerObj
	   			}
		   }
}
#>
		
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