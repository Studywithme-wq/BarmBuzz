BeforeDiscovery {
  param($RepoRoot, $EvidenceDir)

  Set-StrictMode -Version Latest
  $ErrorActionPreference = 'Stop'

  # Fallback: If not injected by harness, calculate from test file location
  if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
  }

  # Load intent for discovery phase (needed for -Skip: expressions)
  $cfg = Import-PowerShellDataFile (Join-Path $RepoRoot 'DSC\Data\AllNodes.psd1')
  $node = $cfg.AllNodes | Where-Object NodeName -eq 'localhost' | Select-Object -First 1

  $script:ExpectNatDhcp = [bool]$node.Expect_NAT_Dhcp
  $script:DisableNatReg = [bool]$node.DisableDnsRegistrationOnNat
  $script:NeedADDS = [bool]$node.InstallADDSRole
  $script:NeedRSAT = [bool]$node.InstallRSATADDS
}

Describe "Pre-DC Readiness (Dual NIC) - localhost" {

  BeforeAll {
    param($RepoRoot, $EvidenceDir)

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    # Fallback: If not injected by harness, calculate from test file location
    if (-not $RepoRoot) {
      $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
    }

    # Load intent
    $cfg = Import-PowerShellDataFile (Join-Path $RepoRoot 'DSC\Data\AllNodes.psd1')
    $node = $cfg.AllNodes | Where-Object NodeName -eq 'localhost' | Select-Object -First 1
    $node | Should -Not -BeNullOrEmpty

    # Scope
    $node.Role | Should -Be 'DC'

    foreach ($k in @(
      'InterfaceAlias_Internal','InterfaceAlias_NAT',
      'IPv4Address_Internal','PrefixLength_Internal',
      'DnsServers_Internal',
      'Expect_NAT_Dhcp',
      'DisableDnsRegistrationOnNat',
      'InstallADDSRole','InstallRSATADDS'
    )) {
      ($node.ContainsKey($k) -and -not [string]::IsNullOrWhiteSpace([string]$node[$k])) |
        Should -BeTrue -Because "AllNodes must provide $k for pre-DC dual-NIC readiness"
    }

    $script:IfInt   = [string]$node.InterfaceAlias_Internal
    $script:IfNat   = [string]$node.InterfaceAlias_NAT

    $script:IPv4Int = [string]$node.IPv4Address_Internal
    $script:PrefInt = [int]$node.PrefixLength_Internal
    $script:DnsInt  = @($node.DnsServers_Internal)

    $script:ExpectNatDhcp = [bool]$node.Expect_NAT_Dhcp
    $script:DisableNatReg = [bool]$node.DisableDnsRegistrationOnNat

    $script:NeedADDS = [bool]$node.InstallADDSRole
    $script:NeedRSAT = [bool]$node.InstallRSATADDS

    # Capture actual state
    $script:AdapterInt = Get-NetAdapter -Name $script:IfInt -ErrorAction SilentlyContinue
    $script:AdapterNat = Get-NetAdapter -Name $script:IfNat -ErrorAction SilentlyContinue

    $script:IPInt  = Get-NetIPConfiguration -InterfaceAlias $script:IfInt -ErrorAction SilentlyContinue
    $script:IPNat  = Get-NetIPConfiguration -InterfaceAlias $script:IfNat -ErrorAction SilentlyContinue

    $dnsInt = Get-DnsClientServerAddress -InterfaceAlias $script:IfInt -AddressFamily IPv4 -ErrorAction SilentlyContinue
    $dnsNat = Get-DnsClientServerAddress -InterfaceAlias $script:IfNat -AddressFamily IPv4 -ErrorAction SilentlyContinue
    $script:DnsIntActual = if ($dnsInt) { $dnsInt.ServerAddresses } else { @() }
    $script:DnsNatActual = if ($dnsNat) { $dnsNat.ServerAddresses } else { @() }

    $script:DnsClientInt = Get-DnsClient -InterfaceAlias $script:IfInt -ErrorAction SilentlyContinue
    $script:DnsClientNat = Get-DnsClient -InterfaceAlias $script:IfNat -ErrorAction SilentlyContinue

    # Feature state
    Import-Module ServerManager -ErrorAction Stop
    $script:FeatADDS = Get-WindowsFeature -Name AD-Domain-Services
    $script:FeatRSAT = Get-WindowsFeature -Name RSAT-ADDS
  }

  It "Internal and NAT adapters exist" {
    $script:AdapterInt | Should -Not -BeNullOrEmpty
    $script:AdapterNat | Should -Not -BeNullOrEmpty
  }

  It "Internal NIC has static IPv4 (Manual prefix origin)" {
    $script:IPInt.IPv4Address | Should -Not -BeNullOrEmpty
    ($script:IPInt.IPv4Address | Select-Object -First 1).PrefixOrigin | Should -Be 'Manual'
  }

  It "Internal NIC IPv4 address matches AllNodes" {
    ($script:IPInt.IPv4Address | Select-Object -First 1).IPv4Address | Should -Be $script:IPv4Int
  }

  It "Internal NIC prefix length matches AllNodes" {
    ($script:IPInt.IPv4Address | Select-Object -First 1).PrefixLength | Should -Be $script:PrefInt
  }

  It "Internal NIC has NO default gateway (single-gateway rule)" {
    $script:IPInt.IPv4DefaultGateway | Should -BeNullOrEmpty
  }

  It "NAT NIC has a default gateway" {
    $script:IPNat.IPv4DefaultGateway | Should -Not -BeNullOrEmpty
  }

  It "Internal NIC DNS servers match AllNodes (order-insensitive)" {
    @($script:DnsIntActual) | Should -BeEquivalentTo @($script:DnsInt)
  }

  It "NAT NIC does not register in DNS when DisableDnsRegistrationOnNat is true" -Skip:(-not $script:DisableNatReg) {
    $script:DnsClientNat.RegisterThisConnectionsAddress | Should -BeFalse
  }

  It "Internal NIC registers in DNS" {
    $script:DnsClientInt.RegisterThisConnectionsAddress | Should -BeTrue
  }

  It "NAT NIC is DHCP (when Expect_NAT_Dhcp is true)" -Skip:(-not $script:ExpectNatDhcp) {
    $script:IPNat.IPv4Address | Should -Not -BeNullOrEmpty
    ($script:IPNat.IPv4Address | Select-Object -First 1).PrefixOrigin | Should -Be 'Dhcp'
  }

  It "AD-Domain-Services is installed when requested" -Skip:(-not $script:NeedADDS) {
    $script:FeatADDS.Installed | Should -BeTrue
  }

  It "RSAT-ADDS is installed when requested" -Skip:(-not $script:NeedRSAT) {
    $script:FeatRSAT.Installed | Should -BeTrue
  }
}
