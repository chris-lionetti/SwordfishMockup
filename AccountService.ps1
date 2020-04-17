function Get-SFAccountServiceRoot {	
    param()
    process{
        $AccountRoot =[ordered]@{
                        '@Redfish.Copyright'	= 	$RedfishCopyright;
                        '@odata.id'				=	'/redfish/v1/AccountService';
                        '@odata.type'			=	'#AccountService.v1_7_0.AccountService';
                        Name					=   'Account Service';
                        Accounts				=	@{  '@odata.id' =   '/redfish/v1/AccountService/Accounts'   };
                        Roles				    =	@{  '@odata.id' =   '/redfish/v1/AccountService/Roles'      };
                        ServiceEnabled          =   $True;
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
            {	$LocalMembers = @{	'@odata.id'		=	'/redfish/v1/AccountService/Accounts/'+$user.id 
                                 }
                $Members+=$localMembers
            }
        
        $AccountCol =[ordered]@{
                        '@Redfish.Copyright'	= 	$RedfishCopyright;
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
    param(  $AccountId    )
    process{
        $user=( Get-NsUser -Id $AccountId)
        $Account =  [ordered]@{
                        '@Redfish.Copyright'	= 	$RedfishCopyright;
                        '@odata.id'				=	'/redfish/v1/AccountService/Accounts/'+$AccountId;
                        '@odata.type'			=	'#ManagerAccount.v1_5_0.ManagerAccount';
                        Id                      =   $user.id;
                        Name					=   $user.full_name;
                        UserName                =   $user.name;
                        Description             =   $user.description;
                        RoleId                  =   $user.role;
                        Locked                  =   (-not $User.Disabled)
                        Links                   =  @{  Role = @{  '@odata.id' =   '/redfish/v1/AccountService/Roles/'+($user.role)
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
                        '@odata.id'				=	'/redfish/v1/AccountService/Roles/'+$RoleName;
                        '@odata.type'           =   '#Role.v1_2_4.Role';
                        Name					=   $RoleName;
                        IsPredefined            =   $True;
                        Id                      =   $RoleName;
                        Description             =   $Description;
                        RoleId                  =   $RoleName;
                        AssignedPrivileges      =   $asspriv
                      }
        return $Role
    }
}