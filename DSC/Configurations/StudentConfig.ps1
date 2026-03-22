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
        
        # 0. Base Windows Config
        Computer ServerName {
            Name = $Node.ComputerName
        }

        TimeZone SetTimeZone {
            IsSingleInstance = 'Yes'
            TimeZone = $Node.TimeZone
        }

        Service W32TimeService {
            Name = 'W32Time'
            State = 'Running'
            StartupType = 'Automatic'
        }

        # 1. Root Domain
        ADDomain BoltonDomain {
            DomainName                = $Node.DomainName
            DomainNetBIOSName         = $Node.DomainNetBIOSName
            Credential                = $DomainAdminCredential
            SafemodeAdministratorPassword = $DsrmCredential
        }

        ADWaitForDomain WaitForBolton {
            DomainName = $Node.DomainName
            DomainUserCredential = $DomainAdminCredential
            DependsOn = '[ADDomain]BoltonDomain'
            RetryIntervalSec = 20
            RetryCount = 30
        }

        # 2. OU Structure
        ADOrganizationalUnit OU_Users {
            Name      = 'Users'
            Path      = "DC=bolton,DC=barmbuzz,DC=test"
            DependsOn = '[ADWaitForDomain]WaitForBolton'
        }
        
        ADOrganizationalUnit OU_Computers {
            Name      = 'Computers'
            Path      = "DC=bolton,DC=barmbuzz,DC=test"
            DependsOn = '[ADWaitForDomain]WaitForBolton'
        }

        ADOrganizationalUnit OU_BoltonAdmins {
            Name      = 'BoltonAdmins'
            Path      = "DC=bolton,DC=barmbuzz,DC=test"
            DependsOn = '[ADWaitForDomain]WaitForBolton'
        }

        ADOrganizationalUnit OU_Derby {
            Name      = 'Derby'
            Path      = "DC=bolton,DC=barmbuzz,DC=test"
            DependsOn = '[ADWaitForDomain]WaitForBolton'
        }

        ADOrganizationalUnit OU_Nottingham {
            Name      = 'Nottingham'
            Path      = "OU=Derby,DC=bolton,DC=barmbuzz,DC=test"
            DependsOn = '[ADOrganizationalUnit]OU_Derby'
        }

        ADOrganizationalUnit OU_DerbyAdmins {
            Name      = 'DerbyAdmins'
            Path      = "OU=Derby,DC=bolton,DC=barmbuzz,DC=test"
            DependsOn = '[ADOrganizationalUnit]OU_Derby'
        }

        # 3. RBAC Groups (AGDLP Model Implementation)
        # Global Groups
        ADGroup GG_BoltonAdmins {
            GroupName  = 'GG-BoltonAdmins'
            Path       = "OU=BoltonAdmins,DC=bolton,DC=barmbuzz,DC=test"
            Category   = 'Security'
            GroupScope = 'Global'
            DependsOn  = '[ADOrganizationalUnit]OU_BoltonAdmins'
        }

        ADGroup GG_DerbyAdmins {
            GroupName  = 'GG-DerbyAdmins'
            Path       = "OU=DerbyAdmins,OU=Derby,DC=bolton,DC=barmbuzz,DC=test"
            Category   = 'Security'
            GroupScope = 'Global'
            DependsOn  = '[ADOrganizationalUnit]OU_DerbyAdmins'
        }

        ADGroup GG_DerbyStaff {
            GroupName  = 'GG-DerbyStaff'
            Path       = "OU=Derby,DC=bolton,DC=barmbuzz,DC=test"
            Category   = 'Security'
            GroupScope = 'Global'
            DependsOn  = '[ADOrganizationalUnit]OU_Derby'
        }

        ADGroup GG_NottinghamStaff {
            GroupName  = 'GG-NottinghamStaff'
            Path       = "OU=Nottingham,OU=Derby,DC=bolton,DC=barmbuzz,DC=test"
            Category   = 'Security'
            GroupScope = 'Global'
            DependsOn  = '[ADOrganizationalUnit]OU_Nottingham'
        }

        # Domain Local Groups
        ADGroup DLG_BoltonAdmins {
            GroupName  = 'DLG-BoltonAdmins'
            Path       = "OU=BoltonAdmins,DC=bolton,DC=barmbuzz,DC=test"
            Category   = 'Security'
            GroupScope = 'DomainLocal'
            DependsOn  = '[ADOrganizationalUnit]OU_BoltonAdmins'
        }

        ADGroup DLG_DerbyAdmins {
            GroupName  = 'DLG-DerbyAdmins'
            Path       = "OU=DerbyAdmins,OU=Derby,DC=bolton,DC=barmbuzz,DC=test"
            Category   = 'Security'
            GroupScope = 'DomainLocal'
            DependsOn  = '[ADOrganizationalUnit]OU_DerbyAdmins'
        }

        # AGDLP Bindings
        ADGroupMember Bind_BoltonAdmins {
            GroupName = 'DLG-BoltonAdmins'
            Members   = 'GG-BoltonAdmins'
            DependsOn = @('[ADGroup]DLG_BoltonAdmins', '[ADGroup]GG_BoltonAdmins')
        }

        ADGroupMember Bind_DerbyAdmins {
            GroupName = 'DLG-DerbyAdmins'
            Members   = 'GG-DerbyAdmins'
            DependsOn = @('[ADGroup]DLG_DerbyAdmins', '[ADGroup]GG_DerbyAdmins')
        }

        # 4. Identity Definitions
        ADUser User_AdminJane {
            UserName    = 'AdminJane'
            Path        = "OU=BoltonAdmins,DC=bolton,DC=barmbuzz,DC=test"
            Password    = $UserCredential
            DependsOn   = '[ADOrganizationalUnit]OU_BoltonAdmins'
        }
        ADGroupMember Member_AdminJane {
            GroupName = 'GG-BoltonAdmins'
            Members   = 'AdminJane'
            DependsOn = @('[ADGroup]GG_BoltonAdmins', '[ADUser]User_AdminJane')
        }

        ADUser User_JaneDoe {
            UserName    = 'JaneDoe'
            Path        = "OU=Derby,DC=bolton,DC=barmbuzz,DC=test"
            Password    = $UserCredential
            DependsOn   = '[ADOrganizationalUnit]OU_Derby'
        }
        ADGroupMember Member_JaneDoe {
            GroupName = 'GG-DerbyStaff'
            Members   = 'JaneDoe'
            DependsOn = @('[ADGroup]GG_DerbyStaff', '[ADUser]User_JaneDoe')
        }

        ADUser User_BobSmith {
            UserName    = 'BobSmith'
            Path        = "OU=Nottingham,OU=Derby,DC=bolton,DC=barmbuzz,DC=test"
            Password    = $UserCredential
            DependsOn   = '[ADOrganizationalUnit]OU_Nottingham'
        }
        ADGroupMember Member_BobSmith {
            GroupName = 'GG-NottinghamStaff'
            Members   = 'BobSmith'
            DependsOn = @('[ADGroup]GG_NottinghamStaff', '[ADUser]User_BobSmith')
        }

        # 5. GPO Deployments (Meaningful Objects & Links)
        Gpo GPO_Baseline {
            Name = 'BaselineSecurity'
            Ensure = 'Present'
            DependsOn = '[ADWaitForDomain]WaitForBolton'
        }
        GpoLink Link_Baseline {
            GpoName = 'BaselineSecurity'
            Target = 'DC=bolton,DC=barmbuzz,DC=test'
            Ensure = 'Present'
            DependsOn = '[Gpo]GPO_Baseline'
        }

        Gpo GPO_Derby {
            Name = 'DerbyRegionalPolicy'
            Ensure = 'Present'
            DependsOn = '[ADWaitForDomain]WaitForBolton'
        }
        GpoLink Link_Derby {
            GpoName = 'DerbyRegionalPolicy'
            Target = 'OU=Derby,DC=bolton,DC=barmbuzz,DC=test'
            Ensure = 'Present'
            DependsOn = @('[Gpo]GPO_Derby', '[ADOrganizationalUnit]OU_Derby')
        }
        
        Gpo GPO_Nottingham {
            Name = 'NottinghamOperations'
            Ensure = 'Present'
            DependsOn = '[ADWaitForDomain]WaitForBolton'
        }
        GpoLink Link_Nottingham {
            GpoName = 'NottinghamOperations'
            Target = 'OU=Nottingham,OU=Derby,DC=bolton,DC=barmbuzz,DC=test'
            Ensure = 'Present'
            DependsOn = @('[Gpo]GPO_Nottingham', '[ADOrganizationalUnit]OU_Nottingham')
        }

        # 6. A* FGPP Security Control Implementation
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
            DependsOn          = '[ADWaitForDomain]WaitForBolton'
        }

        ADFineGrainedPasswordPolicySubject PwdPolicyAdminsSubject {
            PolicyName = 'FGPP-ITAdmins'
            Subjects   = 'GG-BoltonAdmins'
            DependsOn  = @('[ADFineGrainedPasswordPolicy]PwdPolicyAdmins', '[ADGroup]GG_BoltonAdmins')
        }
    }
}
