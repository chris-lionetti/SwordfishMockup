function Get-SFSystemCore {
	param()
	process{
		$SCore=[ordered]@{
				v1				=	'/redfish/v1';
                	 	 }
		Return $SCore
	}
}

function Get-SFRedfishRoot {
	param(
	     )
	process{
		$ServicesRoot=[ordered]@{
						'@odata.Copyright'	=	$RedfishCopyright;
						'@odata.type'		=	'#ServiceRoot.v1_3_0.ServiceRoot';
						'@odata.id'			=	'/redfish/v1';
						RedfishVersion		=	'1.0.2';
						Id					=	"RootService";
						Name				=	"Root Service";
						Chassis				=	@{	'@odata.id'	=	'/redfish/v1/Chassis'			};
						Systems				= 	@{  '@odata.id'	=	'/redfish/v1/Systems'			};		
						StorageSystems		=	@{	'@odata.id'	=	'/redfish/v1/Storage'			};
						AccountService		=	@{	'@odata.id'	=	'/redfish/v1/AccountService'	};
						EventService		=	@{	'@odata.id'	=	'/redfish/v1/EventService'		};
						LineOfService		=	@{	'@odata.id' =	'/redfish/v1/LineOfService'		};
						Fabrics				=	@{	'@odata.id' =	'/redfish/v1/Fabrics'			}
							   }
		Return $ServicesRoot
	}
}

function Get-SFSystemRoot {
	param()
	process{
		$SRoot=[ordered]@{
				'@odata.Copyright'	=	$RedfishCopyright;
				'@odata.type'		=	'#ComputerSystemCollection.ComputerSystemCollection';
				'@odata.id'			=	'/redfish/v1/Systems';
                Name				=	'Computer System Collection';
                'Members@odata.count'=	1;                
				Members				=	@( @{	'@odata.id'	=	'/redfish/v1/Storage/'+$NimbleSerial
										 	}
										 )	
			 		 	 }
		Return $SRoot
	}
}

function test-SFID {
	param(	$TestString
		 )
	$TestIDResult=$true
	
	if ($TestString.lenght -ne 42)
	{	$TestIDResult=$false
	}
	$count=0
	$ValidChars=@('0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f')
	while($Count -lt 42)
	{	foreach($Letter in $ValidChars)
		{	$ThisChar=$false
			foreach($hexidec in $ValidChars)
			{	if ( $TestString[$count] -eq $Hexidec )
					{$ThisChar=$true
					}
			}
			if ( $ThisChar -eq $False )
				{	$TestIDResult=$false
				}
		}
		$Count=$Count+1
	}
	return $ThisIDResult
}
