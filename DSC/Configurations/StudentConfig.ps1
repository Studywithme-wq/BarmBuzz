<#
StudentConfig.ps1 — BarmBuzz AD Build
Student-authored DSC configuration.
AI usage logged in Evidence\AI_LOG\AI-Usage.md
#>

Configuration StudentBaseline {
    param(
        [PSCredential]$DomainAdminCredential,
        [PSCredential]$DsrmCredential,
        [PSCredential]$UserCredential
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ActiveDirectoryDsc
    Import-DscResource -ModuleName ComputerManagementDsc

    $cfg  = $ConfigurationData.AllNodes | Where-Object { $_.NodeName -eq 'localhost' } | Select-Object -First 1
    $base = 'DC=bolton,DC=barmbuzz,DC=test'
    $dom  = 'bolton.barmbuzz.test'

    Node localhost {

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


        File EvidenceAD {
            DestinationPath = 'C:\BarmBuzz\Evidence\AD'
            Type            = 'Directory'
            Ensure          = 'Present'
        }
        File EvidenceHealth {
            DestinationPath = 'C:\BarmBuzz\Evidence\HealthChecks'
            Type            = 'Directory'
            Ensure          = 'Present'
        }
        File EvidenceGPO {
            DestinationPath = 'C:\BarmBuzz\Evidence\GPOBackups'
            Type            = 'Directory'
            Ensure          = 'Present'
        }

        WindowsFeature ADDS {
            Name   = 'AD-Domain-Services'
            Ensure = 'Present'
        }
        WindowsFeature DNS {
            Name      = 'DNS'
            Ensure    = 'Present'
            DependsOn = '[WindowsFeature]ADDS'
        }
        WindowsFeature GPMC {
            Name      = 'GPMC'
            Ensure    = 'Present'
            DependsOn = '[WindowsFeature]ADDS'
        }
        WindowsFeature RSAT_AD {
            Name      = 'RSAT-AD-Tools'
            Ensure    = 'Present'
            DependsOn = '[WindowsFeature]ADDS'
        }
        WindowsFeature RSAT_DNS {
            Name      = 'RSAT-DNS-Server'
            Ensure    = 'Present'
            DependsOn = '[WindowsFeature]DNS'
        }

        ADDomain BoltonDomain {
            DomainName                    = $cfg.DomainName
            DomainNetbiosName             = $cfg.DomainNetBIOSName
            Credential                    = $DomainAdminCredential
            SafemodeAdministratorPassword = $DsrmCredential
            ForestMode                    = $cfg.ForestMode
            DomainMode                    = $cfg.DomainMode
            DependsOn                     = '[WindowsFeature]ADDS'
        }
        WaitForADDomain WaitDomain {
            DomainName  = $cfg.DomainName
            Credential  = $DomainAdminCredential
            DependsOn   = '[ADDomain]BoltonDomain'
        }

        ADOrganizationalUnit OU_Bolton {
            Name = 'Bolton'; Path = $base; Description = 'HQ root OU'; Ensure = 'Present'
            DependsOn = '[WaitForADDomain]WaitDomain'
        }
        ADOrganizationalUnit OU_BoltonUsers {
            Name = 'BoltonUsers'; Path = "OU=Bolton,$base"; Description = 'Bolton standard users'; Ensure = 'Present'
            DependsOn = '[ADOrganizationalUnit]OU_Bolton'
        }
        ADOrganizationalUnit OU_BoltonComputers {
            Name = 'BoltonComputers'; Path = "OU=Bolton,$base"; Description = 'Bolton workstations'; Ensure = 'Present'
            DependsOn = '[ADOrganizationalUnit]OU_Bolton'
        }
        ADOrganizationalUnit OU_BoltonAdmins {
            Name = 'BoltonAdmins'; Path = "OU=Bolton,$base"; Description = 'Bolton Tier-1 privileged accounts'; Ensure = 'Present'
            DependsOn = '[ADOrganizationalUnit]OU_Bolton'
        }
        ADOrganizationalUnit OU_Derby {
            Name = 'Derby'; Path = $base; Description = 'Derby regional OU'; Ensure = 'Present'
            DependsOn = '[WaitForADDomain]WaitDomain'
        }
        ADOrganizationalUnit OU_DerbyUsers {
            Name = 'DerbyUsers'; Path = "OU=Derby,$base"; Description = 'Derby standard users'; Ensure = 'Present'
            DependsOn = '[ADOrganizationalUnit]OU_Derby'
        }
        ADOrganizationalUnit OU_DerbyComputers {
            Name = 'DerbyComputers'; Path = "OU=Derby,$base"; Description = 'Derby workstations'; Ensure = 'Present'
            DependsOn = '[ADOrganizationalUnit]OU_Derby'
        }
        ADOrganizationalUnit OU_DerbyAdmins {
            Name = 'DerbyAdmins'; Path = "OU=Derby,$base"; Description = 'Derby Tier-1 privileged accounts'; Ensure = 'Present'
            DependsOn = '[ADOrganizationalUnit]OU_Derby'
        }
        ADOrganizationalUnit OU_Nottingham {
            Name = 'Nottingham'; Path = "OU=Derby,$base"; Description = 'Nottingham operational unit'; Ensure = 'Present'
            DependsOn = '[ADOrganizationalUnit]OU_Derby'
        }
        ADOrganizationalUnit OU_NottinghamUsers {
            Name = 'NottinghamUsers'; Path = "OU=Nottingham,OU=Derby,$base"; Description = 'Nottingham users'; Ensure = 'Present'
            DependsOn = '[ADOrganizationalUnit]OU_Nottingham'
        }
        ADOrganizationalUnit OU_NottinghamComputers {
            Name = 'NottinghamComputers'; Path = "OU=Nottingham,OU=Derby,$base"; Description = 'Nottingham workstations'; Ensure = 'Present'
            DependsOn = '[ADOrganizationalUnit]OU_Nottingham'
        }

        ADGroup GG_IT_Staff {
            GroupName = 'GG-IT-Staff'; GroupScope = 'Global'; Category = 'Security'
            Path = "OU=BoltonUsers,OU=Bolton,$base"; Description = 'Bolton IT staff role group'; Ensure = 'Present'
            DependsOn = '[ADOrganizationalUnit]OU_BoltonUsers'
        }
        ADGroup GG_Finance {
            GroupName = 'GG-Finance'; GroupScope = 'Global'; Category = 'Security'
            Path = "OU=BoltonUsers,OU=Bolton,$base"; Description = 'Bolton Finance role group'; Ensure = 'Present'
            DependsOn = '[ADOrganizationalUnit]OU_BoltonUsers'
        }
        ADGroup GG_HR {
            GroupName = 'GG-HR'; GroupScope = 'Global'; Category = 'Security'
            Path = "OU=BoltonUsers,OU=Bolton,$base"; Description = 'Bolton HR role group'; Ensure = 'Present'
            DependsOn = '[ADOrganizationalUnit]OU_BoltonUsers'
        }
        ADGroup GG_IT_Admins {
            GroupName = 'GG-IT-Admins'; GroupScope = 'Global'; Category = 'Security'
            Path = "OU=BoltonAdmins,OU=Bolton,$base"; Description = 'Bolton Tier-1 admin accounts'; Ensure = 'Present'
            DependsOn = '[ADOrganizationalUnit]OU_BoltonAdmins'
        }
        ADGroup GG_Derby_IT {
            GroupName = 'GG-Derby-IT'; GroupScope = 'Global'; Category = 'Security'
            Path = "OU=DerbyUsers,OU=Derby,$base"; Description = 'Derby IT role group'; Ensure = 'Present'
            DependsOn = '[ADOrganizationalUnit]OU_DerbyUsers'
        }
        ADGroup GG_Derby_Sales {
            GroupName = 'GG-Derby-Sales'; GroupScope = 'Global'; Category = 'Security'
            Path = "OU=DerbyUsers,OU=Derby,$base"; Description = 'Derby Sales role group'; Ensure = 'Present'
            DependsOn = '[ADOrganizationalUnit]OU_DerbyUsers'
        }
        ADGroup GG_Derby_IT_Admins {
            GroupName = 'GG-Derby-IT-Admins'; GroupScope = 'Global'; Category = 'Security'
            Path = "OU=DerbyAdmins,OU=Derby,$base"; Description = 'Derby Tier-1 admin accounts'; Ensure = 'Present'
            DependsOn = '[ADOrganizationalUnit]OU_DerbyAdmins'
        }
        ADGroup GG_Nottingham_Ops {
            GroupName = 'GG-Nottingham-Ops'; GroupScope = 'Global'; Category = 'Security'
            Path = "OU=NottinghamUsers,OU=Nottingham,OU=Derby,$base"; Description = 'Nottingham Ops role group'; Ensure = 'Present'
            DependsOn = '[ADOrganizationalUnit]OU_NottinghamUsers'
        }
        ADGroup DL_FileShare_Bolton_R {
            GroupName = 'DL-FileShare-Bolton-R'; GroupScope = 'DomainLocal'; Category = 'Security'
            Path = "OU=BoltonUsers,OU=Bolton,$base"; Description = 'Read access to Bolton file share'; Ensure = 'Present'
            DependsOn = '[ADOrganizationalUnit]OU_BoltonUsers'
        }
        ADGroup DL_FileShare_Derby_R {
            GroupName = 'DL-FileShare-Derby-R'; GroupScope = 'DomainLocal'; Category = 'Security'
            Path = "OU=DerbyUsers,OU=Derby,$base"; Description = 'Read access to Derby file share'; Ensure = 'Present'
            DependsOn = '[ADOrganizationalUnit]OU_DerbyUsers'
        }

        ADUser User_jsmith {
            UserName = 'j.smith'; GivenName = 'John'; Surname = 'Smith'; DisplayName = 'John Smith'
            Department = 'IT'; JobTitle = 'Systems Engineer'
            Path = "OU=BoltonUsers,OU=Bolton,$base"; DomainName = $dom
            Enabled = $true; Password = $UserCredential; PasswordNeverExpires = $true; Ensure = 'Present'
            DependsOn = '[ADOrganizationalUnit]OU_BoltonUsers'
        }
        ADUser User_ajones {
            UserName = 'a.jones'; GivenName = 'Alice'; Surname = 'Jones'; DisplayName = 'Alice Jones'
            Department = 'Finance'; JobTitle = 'Finance Analyst'
            Path = "OU=BoltonUsers,OU=Bolton,$base"; DomainName = $dom
            Enabled = $true; Password = $UserCredential; PasswordNeverExpires = $true; Ensure = 'Present'
            DependsOn = '[ADOrganizationalUnit]OU_BoltonUsers'
        }
        ADUser User_btaylor {
            UserName = 'b.taylor'; GivenName = 'Bob'; Surname = 'Taylor'; DisplayName = 'Bob Taylor'
            Department = 'HR'; JobTitle = 'HR Manager'
            Path = "OU=BoltonUsers,OU=Bolton,$base"; DomainName = $dom
            Enabled = $true; Password = $UserCredential; PasswordNeverExpires = $true; Ensure = 'Present'
            DependsOn = '[ADOrganizationalUnit]OU_BoltonUsers'
        }
        ADUser User_dpatel {
            UserName = 'd.patel'; GivenName = 'Dev'; Surname = 'Patel'; DisplayName = 'Dev Patel'
            Department = 'IT'; JobTitle = 'Derby IT Technician'
            Path = "OU=DerbyUsers,OU=Derby,$base"; DomainName = $dom
            Enabled = $true; Password = $UserCredential; PasswordNeverExpires = $true; Ensure = 'Present'
            DependsOn = '[ADOrganizationalUnit]OU_DerbyUsers'
        }
        ADUser User_sgreen {
            UserName = 's.green'; GivenName = 'Sara'; Surname = 'Green'; DisplayName = 'Sara Green'
            Department = 'Sales'; JobTitle = 'Sales Executive'
            Path = "OU=DerbyUsers,OU=Derby,$base"; DomainName = $dom
            Enabled = $true; Password = $UserCredential; PasswordNeverExpires = $true; Ensure = 'Present'
            DependsOn = '[ADOrganizationalUnit]OU_DerbyUsers'
        }
        ADUser User_rkhan {
            UserName = 'r.khan'; GivenName = 'Raza'; Surname = 'Khan'; DisplayName = 'Raza Khan'
            Department = 'Ops'; JobTitle = 'Ops Coordinator'
            Path = "OU=NottinghamUsers,OU=Nottingham,OU=Derby,$base"; DomainName = $dom
            Enabled = $true; Password = $UserCredential; PasswordNeverExpires = $true; Ensure = 'Present'
            DependsOn = '[ADOrganizationalUnit]OU_NottinghamUsers'
        }
        ADUser User_admjsmith {
            UserName = 'adm.jsmith'; GivenName = 'ADM'; Surname = 'JSmith'; DisplayName = 'ADM JSmith'
            Department = 'IT'; JobTitle = 'IT Admin Account'
            Path = "OU=BoltonAdmins,OU=Bolton,$base"; DomainName = $dom
            Enabled = $true; Password = $UserCredential; PasswordNeverExpires = $true; Ensure = 'Present'
            DependsOn = '[ADOrganizationalUnit]OU_BoltonAdmins'
        }
        ADUser User_admdpatel {
            UserName = 'adm.dpatel'; GivenName = 'ADM'; Surname = 'DPatel'; DisplayName = 'ADM DPatel'
            Department = 'IT'; JobTitle = 'Derby IT Admin'
            Path = "OU=DerbyAdmins,OU=Derby,$base"; DomainName = $dom
            Enabled = $true; Password = $UserCredential; PasswordNeverExpires = $true; Ensure = 'Present'
            DependsOn = '[ADOrganizationalUnit]OU_DerbyAdmins'
        }

        Script GroupMemberships {
            GetScript  = { @{ Result = 'GroupMemberships' } }
            TestScript = {
                $m = Get-ADGroupMember -Identity 'GG-IT-Staff' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty SamAccountName
                return ($m -contains 'j.smith')
            }
            SetScript  = {
                Import-Module ActiveDirectory
                Add-ADGroupMember -Identity 'GG-IT-Staff'        -Members 'j.smith'    -ErrorAction SilentlyContinue
                Add-ADGroupMember -Identity 'GG-Finance'          -Members 'a.jones'    -ErrorAction SilentlyContinue
                Add-ADGroupMember -Identity 'GG-HR'               -Members 'b.taylor'   -ErrorAction SilentlyContinue
                Add-ADGroupMember -Identity 'GG-Derby-IT'         -Members 'd.patel'    -ErrorAction SilentlyContinue
                Add-ADGroupMember -Identity 'GG-Derby-Sales'      -Members 's.green'    -ErrorAction SilentlyContinue
                Add-ADGroupMember -Identity 'GG-Nottingham-Ops'   -Members 'r.khan'     -ErrorAction SilentlyContinue
                Add-ADGroupMember -Identity 'GG-IT-Admins'        -Members 'adm.jsmith' -ErrorAction SilentlyContinue
                Add-ADGroupMember -Identity 'GG-Derby-IT-Admins'  -Members 'adm.dpatel' -ErrorAction SilentlyContinue
                Add-ADGroupMember -Identity 'DL-FileShare-Bolton-R' -Members 'GG-IT-Staff'       -ErrorAction SilentlyContinue
                Add-ADGroupMember -Identity 'DL-FileShare-Bolton-R' -Members 'GG-Finance'         -ErrorAction SilentlyContinue
                Add-ADGroupMember -Identity 'DL-FileShare-Bolton-R' -Members 'GG-HR'              -ErrorAction SilentlyContinue
                Add-ADGroupMember -Identity 'DL-FileShare-Derby-R'  -Members 'GG-Derby-IT'        -ErrorAction SilentlyContinue
                Add-ADGroupMember -Identity 'DL-FileShare-Derby-R'  -Members 'GG-Derby-Sales'     -ErrorAction SilentlyContinue
                Add-ADGroupMember -Identity 'DL-FileShare-Derby-R'  -Members 'GG-Nottingham-Ops'  -ErrorAction SilentlyContinue
                Write-Host 'Group memberships configured.' -ForegroundColor Green
            }
            DependsOn = @(
                '[ADUser]User_jsmith','[ADUser]User_ajones','[ADUser]User_btaylor',
                '[ADUser]User_dpatel','[ADUser]User_sgreen','[ADUser]User_rkhan',
                '[ADUser]User_admjsmith','[ADUser]User_admdpatel',
                '[ADGroup]GG_IT_Staff','[ADGroup]GG_Finance','[ADGroup]GG_HR',
                '[ADGroup]GG_IT_Admins','[ADGroup]GG_Derby_IT','[ADGroup]GG_Derby_Sales',
                '[ADGroup]GG_Derby_IT_Admins','[ADGroup]GG_Nottingham_Ops',
                '[ADGroup]DL_FileShare_Bolton_R','[ADGroup]DL_FileShare_Derby_R'
            )
        }

        Script GPO_BaselineSecurity {
            GetScript  = { $g = Get-GPO -Name 'BB-Baseline-Security' -ErrorAction SilentlyContinue; @{ Result = if ($g) { 'Present' } else { 'Absent' } } }
            TestScript = { $g = Get-GPO -Name 'BB-Baseline-Security' -ErrorAction SilentlyContinue; return [bool]$g }
            SetScript  = {
                Import-Module GroupPolicy
                New-GPO -Name 'BB-Baseline-Security' -Comment 'Baseline security: LLMNR disable, screen lock' | Out-Null
                Set-GPRegistryValue -Name 'BB-Baseline-Security' -Key 'HKLM\Software\Policies\Microsoft\Windows NT\DNSClient' -ValueName 'EnableMulticast' -Type DWord -Value 0
                Set-GPRegistryValue -Name 'BB-Baseline-Security' -Key 'HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop' -ValueName 'ScreenSaveTimeOut' -Type String -Value '600'
                Set-GPRegistryValue -Name 'BB-Baseline-Security' -Key 'HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop' -ValueName 'ScreenSaverIsSecure' -Type String -Value '1'
                New-GPLink -Name 'BB-Baseline-Security' -Target 'OU=Bolton,DC=bolton,DC=barmbuzz,DC=test' -LinkEnabled Yes | Out-Null
            }
            DependsOn = '[WaitForADDomain]WaitDomain'
        }

        Script GPO_DerbyRegional {
            GetScript  = { $g = Get-GPO -Name 'BB-Derby-Regional' -ErrorAction SilentlyContinue; @{ Result = if ($g) { 'Present' } else { 'Absent' } } }
            TestScript = { $g = Get-GPO -Name 'BB-Derby-Regional' -ErrorAction SilentlyContinue; return [bool]$g }
            SetScript  = {
                Import-Module GroupPolicy
                New-GPO -Name 'BB-Derby-Regional' -Comment 'Derby regional policy: USB restriction' | Out-Null
                Set-GPRegistryValue -Name 'BB-Derby-Regional' -Key 'HKLM\System\CurrentControlSet\Services\USBSTOR' -ValueName 'Start' -Type DWord -Value 4
                Set-GPRegistryValue -Name 'BB-Derby-Regional' -Key 'HKCU\Software\Policies\BarmBuzz' -ValueName 'Region' -Type String -Value 'Derby'
                New-GPLink -Name 'BB-Derby-Regional' -Target 'OU=Derby,DC=bolton,DC=barmbuzz,DC=test' -LinkEnabled Yes | Out-Null
            }
            DependsOn = '[WaitForADDomain]WaitDomain'
        }

        Script GPO_AdminHygiene {
            GetScript  = { $g = Get-GPO -Name 'BB-Admin-Hygiene' -ErrorAction SilentlyContinue; @{ Result = if ($g) { 'Present' } else { 'Absent' } } }
            TestScript = { $g = Get-GPO -Name 'BB-Admin-Hygiene' -ErrorAction SilentlyContinue; return [bool]$g }
            SetScript  = {
                Import-Module GroupPolicy
                New-GPO -Name 'BB-Admin-Hygiene' -Comment 'Tier-1 admin isolation' | Out-Null
                Set-GPRegistryValue -Name 'BB-Admin-Hygiene' -Key 'HKLM\Software\Policies\BarmBuzz\AdminTier' -ValueName 'TierIsolation' -Type DWord -Value 1
                New-GPLink -Name 'BB-Admin-Hygiene' -Target 'OU=BoltonAdmins,OU=Bolton,DC=bolton,DC=barmbuzz,DC=test' -LinkEnabled Yes -Enforced Yes | Out-Null
            }
            DependsOn = '[ADOrganizationalUnit]OU_BoltonAdmins'
        }

        Script GPO_NottinghamOps {
            GetScript  = { $g = Get-GPO -Name 'BB-Nottingham-Ops' -ErrorAction SilentlyContinue; @{ Result = if ($g) { 'Present' } else { 'Absent' } } }
            TestScript = { $g = Get-GPO -Name 'BB-Nottingham-Ops' -ErrorAction SilentlyContinue; return [bool]$g }
            SetScript  = {
                Import-Module GroupPolicy
                New-GPO -Name 'BB-Nottingham-Ops' -Comment 'Nottingham ops baseline policy' | Out-Null
                Set-GPRegistryValue -Name 'BB-Nottingham-Ops' -Key 'HKCU\Software\Policies\BarmBuzz' -ValueName 'Region' -Type String -Value 'Nottingham'
                New-GPLink -Name 'BB-Nottingham-Ops' -Target 'OU=Nottingham,OU=Derby,DC=bolton,DC=barmbuzz,DC=test' -LinkEnabled Yes | Out-Null
            }
            DependsOn = '[ADOrganizationalUnit]OU_Nottingham'
        }

        Script FGPP_Admins {
            GetScript  = { $p = Get-ADFineGrainedPasswordPolicy -Filter { Name -eq 'PSO-Admins' } -ErrorAction SilentlyContinue; @{ Result = if ($p) { 'Present' } else { 'Absent' } } }
            TestScript = { $p = Get-ADFineGrainedPasswordPolicy -Filter { Name -eq 'PSO-Admins' } -ErrorAction SilentlyContinue; return [bool]$p }
            SetScript  = {
                Import-Module ActiveDirectory
                New-ADFineGrainedPasswordPolicy -Name 'PSO-Admins' -Precedence 10 -MinPasswordLength 16 `
                    -PasswordHistoryCount 24 -MaxPasswordAge '30.00:00:00' -MinPasswordAge '1.00:00:00' `
                    -LockoutThreshold 3 -LockoutDuration '00:30:00' -LockoutObservationWindow '00:30:00' `
                    -ComplexityEnabled $true -ReversibleEncryptionEnabled $false `
                    -Description 'Stricter policy for Tier-1 admin accounts'
                Add-ADFineGrainedPasswordPolicySubject -Identity 'PSO-Admins' -Subjects 'GG-IT-Admins'
                Add-ADFineGrainedPasswordPolicySubject -Identity 'PSO-Admins' -Subjects 'GG-Derby-IT-Admins'
            }
            DependsOn = @('[ADGroup]GG_IT_Admins','[ADGroup]GG_Derby_IT_Admins')
        }

        Script CollectEvidence {
            GetScript  = { @{ Result = 'Evidence' } }
            TestScript = { return $false }
            SetScript  = {
                $ts  = Get-Date -Format 'yyyyMMdd_HHmmss'
                $dir = 'C:\BarmBuzz\Evidence'
                dcdiag /test:services /test:advertising /test:fsmocheck 2>&1 | Out-File "$dir\HealthChecks\dcdiag_$ts.txt" -Encoding utf8
                Get-ADOrganizationalUnit -Filter * | Select-Object Name,DistinguishedName | Export-Csv "$dir\AD\OUs_$ts.csv" -NoTypeInformation
                Get-ADGroup -Filter * | Select-Object Name,GroupScope,GroupCategory | Export-Csv "$dir\AD\Groups_$ts.csv" -NoTypeInformation
                Get-ADUser -Filter * -Properties Department,Title | Select-Object SamAccountName,DisplayName,Department,Title,Enabled | Export-Csv "$dir\AD\Users_$ts.csv" -NoTypeInformation
                Get-ADFineGrainedPasswordPolicy -Filter * | Out-File "$dir\AD\FGPP_$ts.txt" -Encoding utf8
                Get-GPO -All | Select-Object DisplayName,GpoStatus | Out-File "$dir\GPOBackups\GPOList_$ts.txt" -Encoding utf8
                Write-Host "Evidence collected." -ForegroundColor Green
            }
            DependsOn = '[Script]FGPP_Admins'
        }
    }
}


