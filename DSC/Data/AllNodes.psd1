<#
CYBERSECURITY WARNING: NO CREDENTIALS IN THIS FILE
See Documentation\README.md for lab passwords.
#>

@{
    AllNodes = @(
        @{
            NodeName                    = 'localhost'
            Role                        = 'DC'

            # --- Domain ---
            DomainName                  = 'bolton.barmbuzz.test'
            DomainNetBIOSName           = 'BOLTON'
            ForestMode                  = 'WinThreshold'
            DomainMode                  = 'WinThreshold'
            ComputerName                = 'DC01'

            # --- Network (must match your VM adapter names) ---
            InterfaceAlias_Internal     = 'Ethernet'
            IPv4Address_Internal        = '192.168.56.10/24'
            DefaultGateway_Internal     = '192.168.56.1'

            InterfaceAlias_NAT              = 'Ethernet 2'
            PrefixLength_Internal           = 24
            DnsServers_Internal             = @('127.0.0.1')
            Expect_NAT_Dhcp                 = $true
            DisableDnsRegistrationOnNat     = $true
            InstallADDSRole                 = $true
            InstallRSATADDS                 = $true
            TimeZone                        = 'GMT Standard Time'




            # --- DSC credential handling ---
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser        = $true

            # --- OU Structure ---
            OUs = @(
                @{ Name = 'Bolton';              Path = 'DC=bolton,DC=barmbuzz,DC=test';                                          Description = 'HQ root OU' }
                @{ Name = 'BoltonUsers';         Path = 'OU=Bolton,DC=bolton,DC=barmbuzz,DC=test';                                Description = 'Bolton standard users' }
                @{ Name = 'BoltonComputers';     Path = 'OU=Bolton,DC=bolton,DC=barmbuzz,DC=test';                                Description = 'Bolton workstations' }
                @{ Name = 'BoltonAdmins';        Path = 'OU=Bolton,DC=bolton,DC=barmbuzz,DC=test';                                Description = 'Bolton Tier-1 privileged accounts' }
                @{ Name = 'Derby';               Path = 'DC=bolton,DC=barmbuzz,DC=test';                                          Description = 'Derby regional OU' }
                @{ Name = 'DerbyUsers';          Path = 'OU=Derby,DC=bolton,DC=barmbuzz,DC=test';                                  Description = 'Derby standard users' }
                @{ Name = 'DerbyComputers';      Path = 'OU=Derby,DC=bolton,DC=barmbuzz,DC=test';                                  Description = 'Derby workstations' }
                @{ Name = 'DerbyAdmins';         Path = 'OU=Derby,DC=bolton,DC=barmbuzz,DC=test';                                  Description = 'Derby Tier-1 privileged accounts' }
                @{ Name = 'Nottingham';          Path = 'OU=Derby,DC=bolton,DC=barmbuzz,DC=test';                                  Description = 'Nottingham operational unit' }
                @{ Name = 'NottinghamUsers';     Path = 'OU=Nottingham,OU=Derby,DC=bolton,DC=barmbuzz,DC=test';                    Description = 'Nottingham users' }
                @{ Name = 'NottinghamComputers'; Path = 'OU=Nottingham,OU=Derby,DC=bolton,DC=barmbuzz,DC=test';                    Description = 'Nottingham workstations' }
            )

            # --- Groups (AGDLP model) ---
            Groups = @(
                # Global Groups (role-based)
                @{ Name = 'GG-IT-Staff';         GroupScope = 'Global';      GroupCategory = 'Security'; Path = 'OU=BoltonUsers,OU=Bolton,DC=bolton,DC=barmbuzz,DC=test';                             Description = 'Bolton IT staff' }
                @{ Name = 'GG-Finance';          GroupScope = 'Global';      GroupCategory = 'Security'; Path = 'OU=BoltonUsers,OU=Bolton,DC=bolton,DC=barmbuzz,DC=test';                             Description = 'Bolton Finance staff' }
                @{ Name = 'GG-HR';               GroupScope = 'Global';      GroupCategory = 'Security'; Path = 'OU=BoltonUsers,OU=Bolton,DC=bolton,DC=barmbuzz,DC=test';                             Description = 'Bolton HR staff' }
                @{ Name = 'GG-IT-Admins';        GroupScope = 'Global';      GroupCategory = 'Security'; Path = 'OU=BoltonAdmins,OU=Bolton,DC=bolton,DC=barmbuzz,DC=test';                            Description = 'Bolton Tier-1 admin accounts' }
                @{ Name = 'GG-Derby-IT';         GroupScope = 'Global';      GroupCategory = 'Security'; Path = 'OU=DerbyUsers,OU=Derby,DC=bolton,DC=barmbuzz,DC=test';                               Description = 'Derby IT staff' }
                @{ Name = 'GG-Derby-Sales';      GroupScope = 'Global';      GroupCategory = 'Security'; Path = 'OU=DerbyUsers,OU=Derby,DC=bolton,DC=barmbuzz,DC=test';                               Description = 'Derby Sales staff' }
                @{ Name = 'GG-Derby-IT-Admins';  GroupScope = 'Global';      GroupCategory = 'Security'; Path = 'OU=DerbyAdmins,OU=Derby,DC=bolton,DC=barmbuzz,DC=test';                              Description = 'Derby Tier-1 admin accounts' }
                @{ Name = 'GG-Nottingham-Ops';   GroupScope = 'Global';      GroupCategory = 'Security'; Path = 'OU=NottinghamUsers,OU=Nottingham,OU=Derby,DC=bolton,DC=barmbuzz,DC=test';             Description = 'Nottingham Ops staff' }
                # Domain Local Groups (resource access)
                @{ Name = 'DL-FileShare-Bolton-R'; GroupScope = 'DomainLocal'; GroupCategory = 'Security'; Path = 'OU=BoltonUsers,OU=Bolton,DC=bolton,DC=barmbuzz,DC=test';                           Description = 'Read access - Bolton file share' }
                @{ Name = 'DL-FileShare-Derby-R';  GroupScope = 'DomainLocal'; GroupCategory = 'Security'; Path = 'OU=DerbyUsers,OU=Derby,DC=bolton,DC=barmbuzz,DC=test';                             Description = 'Read access - Derby file share' }
            )

            # --- Users ---
            Users = @(
                @{ Sam = 'j.smith';    First = 'John';  Last = 'Smith';   OU = 'OU=BoltonUsers,OU=Bolton,DC=bolton,DC=barmbuzz,DC=test';                              Dept = 'IT';      Title = 'Systems Engineer';     Groups = @('GG-IT-Staff','DL-FileShare-Bolton-R') }
                @{ Sam = 'a.jones';    First = 'Alice'; Last = 'Jones';   OU = 'OU=BoltonUsers,OU=Bolton,DC=bolton,DC=barmbuzz,DC=test';                              Dept = 'Finance'; Title = 'Finance Analyst';       Groups = @('GG-Finance','DL-FileShare-Bolton-R') }
                @{ Sam = 'b.taylor';   First = 'Bob';   Last = 'Taylor';  OU = 'OU=BoltonUsers,OU=Bolton,DC=bolton,DC=barmbuzz,DC=test';                              Dept = 'HR';      Title = 'HR Manager';           Groups = @('GG-HR','DL-FileShare-Bolton-R') }
                @{ Sam = 'd.patel';    First = 'Dev';   Last = 'Patel';   OU = 'OU=DerbyUsers,OU=Derby,DC=bolton,DC=barmbuzz,DC=test';                                Dept = 'IT';      Title = 'Derby IT Technician';  Groups = @('GG-Derby-IT','DL-FileShare-Derby-R') }
                @{ Sam = 's.green';    First = 'Sara';  Last = 'Green';   OU = 'OU=DerbyUsers,OU=Derby,DC=bolton,DC=barmbuzz,DC=test';                                Dept = 'Sales';   Title = 'Sales Executive';      Groups = @('GG-Derby-Sales','DL-FileShare-Derby-R') }
                @{ Sam = 'r.khan';     First = 'Raza';  Last = 'Khan';    OU = 'OU=NottinghamUsers,OU=Nottingham,OU=Derby,DC=bolton,DC=barmbuzz,DC=test';              Dept = 'Ops';     Title = 'Ops Coordinator';      Groups = @('GG-Nottingham-Ops','DL-FileShare-Derby-R') }
                @{ Sam = 'adm.jsmith'; First = 'ADM';   Last = 'JSmith';  OU = 'OU=BoltonAdmins,OU=Bolton,DC=bolton,DC=barmbuzz,DC=test';                             Dept = 'IT';      Title = 'IT Admin Account';     Groups = @('GG-IT-Admins') }
                @{ Sam = 'adm.dpatel'; First = 'ADM';   Last = 'DPatel';  OU = 'OU=DerbyAdmins,OU=Derby,DC=bolton,DC=barmbuzz,DC=test';                               Dept = 'IT';      Title = 'Derby IT Admin';       Groups = @('GG-Derby-IT-Admins') }
            )
        }
    )
}
