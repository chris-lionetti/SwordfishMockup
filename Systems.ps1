function Get-SFSystemRoot {
	param(	
		 )
	$SRoot=@{	'@odata.type'		=	'#ComputerSystemCollection.ComputerSystempCollection';
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
