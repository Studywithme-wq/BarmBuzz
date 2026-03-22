<#
STUDENT TASK:
- Define Configuration StudentBaseline
- Use ConfigurationData (AllNodes.psd1)
- DO NOT hardcode passwords here.
#>

Configuration StudentBaseline {
    param(
        [PSCredential]$DomainAdminCredential,
        [PSCredential]$DsrmCredential,
        [PSCredential]$UserCredential
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDSC
    Import-DscResource -ModuleName ActiveDirectoryDsc
    Import-DscResource -ModuleName GroupPolicyDsc

    Node $AllNodes.NodeName {
        
        # Proof-of-life
        File TestFolder {
            DestinationPath = 'C:\TEST'
            Type            = 'Directory'
            Ensure          = 'Present'
        }

        File TestFile {
            DestinationPath = 'C:\TEST\test.txt'
            Type            = 'File'
            Ensure          = 'Present'
            Contents        = 'Proof-of-life: DSC created this file.'
            DependsOn       = '[File]TestFolder'
        }

        # 1. Root Domain
        ADDomain BoltonDomain {
            DomainName                = $Node.DomainName
            IsSingleInstance          = 'Yes'
            DomainAdministratorCredential = $DomainAdminCredential
            SafemodeAdministratorPassword = $DsrmCredential
        }

        # 2. OU Structure
        ADOrganizationalUnit OU_Users {
            Name      = 'Users'
            Path      = "DC=bolton,DC=barmbuzz,DC=test"
            DependsOn = '[ADDomain]BoltonDomain'
        }
        
        ADOrganizationalUnit OU_Computers {
            Name      = 'Computers'
            Path      = "DC=bolton,DC=barmbuzz,DC=test"
            DependsOn = '[ADDomain]BoltonDomain'
        }

        ADOrganizationalUnit OU_ITAdmins {
            Name      = 'IT-Admins'
            Path      = "DC=bolton,DC=barmbuzz,DC=test"
            DependsOn = '[ADDomain]BoltonDomain'
        }

        ADOrganizationalUnit OU_Derby {
            Name      = 'Derby'
            Path      = "DC=bolton,DC=barmbuzz,DC=test"
            DependsOn = '[ADDomain]BoltonDomain'
        }

        ADOrganizationalUnit OU_Nottingham {
            Name      = 'Nottingham'
            Path      = "OU=Derby,DC=bolton,DC=barmbuzz,DC=test"
            DependsOn = '[ADOrganizationalUnit]OU_Derby'
        }

        # 3. RBAC Groups
        ADGroup GG_Staff {
            GroupName  = 'GG-Staff'
            Path       = "OU=Users,DC=bolton,DC=barmbuzz,DC=test"
            Category   = 'Security'
            GroupScope = 'Global'
            DependsOn  = '[ADOrganizationalUnit]OU_Users'
        }

        ADGroup GG_ITAdmins {
            GroupName  = 'GG-IT-Admins'
            Path       = "OU=IT-Admins,DC=bolton,DC=barmbuzz,DC=test"
            Category   = 'Security'
            GroupScope = 'Global'
            DependsOn  = '[ADOrganizationalUnit]OU_ITAdmins'
        }

        # 4. Identity Baseline (Users)
        ADUser User_JohnDoe {
            UserName    = 'JohnDoe'
            Path        = "OU=Users,DC=bolton,DC=barmbuzz,DC=test"
            Password    = $UserCredential
            DependsOn   = '[ADOrganizationalUnit]OU_Users'
        }

        ADGroupMember Member_JohnDoe {
            GroupName = 'GG-Staff'
            Members   = 'JohnDoe'
            DependsOn = @('[ADGroup]GG_Staff', '[ADUser]User_JohnDoe')
        }

        ADUser User_AdminJane {
            UserName    = 'AdminJane'
            Path        = "OU=IT-Admins,DC=bolton,DC=barmbuzz,DC=test"
            Password    = $UserCredential
            DependsOn   = '[ADOrganizationalUnit]OU_ITAdmins'
        }

        ADGroupMember Member_AdminJane {
            GroupName = 'GG-IT-Admins'
            Members   = 'AdminJane'
            DependsOn = @('[ADGroup]GG_ITAdmins', '[ADUser]User_AdminJane')
        }

        # 5. Security Policies (A* FGPP Requirements)
        ADFineGrainedPasswordPolicy PwdPolicyAdmins {
            Name               = 'FGPP-ITAdmins'
            Precedence         = 10
            ComplexityEnabled  = $true
            MinPasswordLength  = 15
            MaxPasswordAge     = '30.00:00:00'
            MinPasswordAge     = '1.00:00:00'
            PasswordHistoryCount = 24
            LockoutDuration    = '00:30:00'
            LockoutObservationWindow = '00:15:00'
            LockoutThreshold   = 3
            DependsOn          = '[ADDomain]BoltonDomain'
        }

        ADFineGrainedPasswordPolicySubject PwdPolicyAdminsSubject {
            PolicyName = 'FGPP-ITAdmins'
            Subjects   = 'GG-IT-Admins'
            DependsOn  = @('[ADFineGrainedPasswordPolicy]PwdPolicyAdmins', '[ADGroup]GG_ITAdmins')
        }
    }
}
