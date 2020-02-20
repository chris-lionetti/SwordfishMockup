function Get-SFSystemRoot {
	param()
	process{
		$SRoot=[ordered]@{
				'@odata.type'		=	'#ComputerSystemCollection.ComputerSystempCollection';
				'@odata.Copyright'	=	$RedfishCopyright;
				'@odata.context'	=	'/redfish/v1/$metadata#Systems';
				'@odata.id'			=	'/redfish/v1/StorageSystems';
                Name				=	'Computer System Collection';
                'Members@odata.count'=	1;                
				Members				=	@( @{	'@odata.id'	=	'/redfish/v1/StorageSystems/'+$NimbleSerial
										 	}
										 )	
			 		 	 }
		Return $SRoot
	}
}
