function Get-SFAccountServiceRoot {	
    param()
    process{
        $AccountRoot =[ordered]@{
                        '@Redfish.Copyright'	= 	$RedfishCopyright;
                        '@odata.context'		=	'/redfish/v1/$metadata#AccountService.AccountService';
                        '@odata.id'				=	'/redfish/v1/AccountService';
                        '@odata.type'			=	'#AccountService.AccountService';
                        Name					=   'Account Service';
                        Accounts				=	@{  '@odata.id' =   '/redfish/v1/AccountService/Accounts'   };
                        Roles				    =	@{  '@odata.id' =   '/redfish/v1/AccountService/Roles'      };
                                }
        return $AccountRoot
    }
}

function Get-SFAccountCol {	
    param()
    process{
        $Members=@()
        $users=( Get-NsUser )
        foreach ($user in $users)
            {	$LocalMembers = @{	'@odata.id'		=	'/redfish/v1/AccountService/Accounts/'+$user.name 
                                 }
                $Members+=$localMembers
            }
        
        $AccountCol =[ordered]@{
                        '@Redfish.Copyright'	= 	$RedfishCopyright;
                        '@odata.context'		=	'/redfish/v1/$metadata#ManagerAccountCollection.ManagerAccountCollection';
                        '@odata.id'				=	'/redfish/v1/AccountService/Accounts';
                        '@odata.type'			=	'#ManagerAccountCollection.ManagerAccountCollection';
                        Name					=   'Account Collection';
                        'Members@odata.count'   =   $Members.count
                        Members				    =	$Members;
                              }
        return $AccountCol
    }
}

function Get-SFAccount {	
    param(  $AccountName    )
    process{
        $user=( Get-NsUser -name $AccountName)
        if ($user.disabled) 
            {   $Status = @{    State = 'Disabled';
                                Health= 'OK'
                           }
            } else 
            {   $Status = @{    State = 'Enabled';
                                Health= 'OK'
                           }
            }
        $Account =  [ordered]@{
                        '@Redfish.Copyright'	= 	$RedfishCopyright;
                        '@odata.context'		=	'/redfish/v1/$metadata#ManagerAccount.ManagerAccount';
                        '@odata.id'				=	'/redfish/v1/AccountService/Accounts/'+$AccountName;
                        '@odata.type'			=	'#ManagerAccount.ManagerAccount';
                        Name					=   $user.full_name;
                        Username                =   $AccountName;
                        Id                      =   $user.id;
                        Description             =   $user.description;
                        RoleId                  =   $user.role;
                        Status                  =   $Status;
                        Links                    =  @{  Role = @{  '@odata.id' =   '/redfish/v1/AccountService/Roles/'+($user.role)
                                                                }
                                                     }
                             }
        if ($user)  
        {   return $Account
        } else 
        {   return
        }
    }
}

function Get-SFAccountRoleCol {	
    param()
    process{
        $RolesCol =  [ordered]@{
                        '@Redfish.Copyright'	= 	$RedfishCopyright;
                        '@odata.context'		=	'/redfish/v1/$metadata#RoleCollection.RoleCollection';
                        '@odata.id'				=	'/redfish/v1/AccountService/Roles';
                        '@odata.type'			=	'#RoleCollection.RoleCollection';
                        Name					=   'Roles Collection';
                        'Members@odata.count'   =   4;
                        Members				    =	@(  @{  '@odata.id'  =   '/redfish/v1/AccountService/Roles/administrator'   };
                                                        @{  '@odata.id'  =   '/redfish/v1/AccountService/Roles/poweruser'       };
                                                        @{  '@odata.id'  =   '/redfish/v1/AccountService/Roles/operator'        };
                                                        @{  '@odata.id'  =   '/redfish/v1/AccountService/Roles/guest'           }
                                                     )    
                              }
        return $RolesCol
    }
}

function Get-SFAccountRole {	
    param(  $RoleName    )
    process{ $asspriv=@('Login','ConfigureSelf')
             switch($RoleName)
                {   "administrator"     {   $asspriv    +=  "ConfigureUsers"
                                            $asspriv    +=  "ConfigureManager"
                                            $asspriv    +=  "ConfigureComponents"
                                            $Description =  'Administrator Role'
                                        }
                    "poweruser"         {   $asspriv    +=  "ConfigureManager"
                                            $asspriv    +=  "ConfigureComponents" 
                                            $Description =  'Power User Role'
                                        }
                    "operator"          {   $asspriv    +=  "ConfigureComponents"
                                            $Description =  'Operator Role'            
                                        }
                    "guest"             {   $Description =  'Guest Role'  
                                        }
                    default             {   return
                                        }
                }
        $RoleId=(get-nsuser | where { $_.role -like $RoleName } | select role_id -last 1 ).role_id
        $Role =  [ordered]@{
                        '@Redfish.Copyright'	= 	$RedfishCopyright;
                        '@odata.context'		=	'/redfish/v1/$metadata#Role.Role';
                        '@odata.id'				=	'/redfish/v1/AccountService/Roles/'+$RoleName;
                        '@odata.type'           =   '#Role.v1_1_0.Role';
                        Name					=   $RoleName;
                        IsPredefined            =   'True';
                        Id                      =   $RoleId;
                        Description             =   $Description;
                        RoleId                  =   $RoleId;
                        AssignedPrivileges      =   $asspriv
                      }
        return $Role
    }
}