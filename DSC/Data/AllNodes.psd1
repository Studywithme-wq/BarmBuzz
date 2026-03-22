@{
    AllNodes = @(
        @{
            NodeName   = 'localhost'
            Role       = 'DC'
            DomainName = 'bolton.barmbuzz.test'
            DomainNetBIOSName = 'BOLTON'
            ComputerName = 'Bolton-DC01'
            InterfaceAlias_Internal = 'Ethernet'
            IPv4Address_Internal = '192.168.0.10'
            ForestMode = 'WinThreshold'
            DomainMode = 'WinThreshold'
            TimeZone = 'GMT Standard Time'
        }
    )
}
