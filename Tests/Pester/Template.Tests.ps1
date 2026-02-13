# Tests\Pester\Template.Tests.ps1
# COM5411 - Student Test Template
#
# INSTRUCTIONS FOR STUDENTS:
#   1. Copy this template to create your own test file (e.g., MyFeature.Tests.ps1)
#   2. Your test filename MUST end with .Tests.ps1 (Pester convention)
#   3. Run tests using: .\Tests\Pester\Invoke-Validation.ps1
#
# WHAT YOU GET AUTOMATICALLY:
#   - $RepoRoot: The absolute path to your repository root
#   - $EvidenceDir: Where to save any test evidence (Evidence\Pester folder)
#
# PESTER v5 BASICS:
#   - Describe: Groups related tests together (think of it as a test suite)
#   - Context: Optional sub-grouping within a Describe block
#   - It: A single test case (should test one specific thing)
#   - Should: Assertion commands (-Be, -BeTrue, -Match, etc.)
#
# WHEN DO YOU NEED BeforeDiscovery vs BeforeAll?
#   - BeforeDiscovery: Use when you need to generate tests dynamically (foreach loops)
#   - BeforeAll: Use for setup code that runs before tests execute
#   - Most student tests only need BeforeAll

# ==============================================================================
# PATTERN 1: Simple Tests (No Dynamic Generation)
# ==============================================================================
# Use this pattern if you just have a fixed list of tests to run.

Describe "My Feature Tests" {

    BeforeAll {
        # REQUIRED: Accept parameters from the test harness
        param($RepoRoot, $EvidenceDir)

        # Good practice: Set strict mode and error handling
        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'

        # IMPORTANT: Fallback logic for when parameters aren't injected
        # This allows running tests directly OR through the harness
        if (-not $RepoRoot) {
            $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
        }
        if (-not $EvidenceDir) {
            $EvidenceDir = (Resolve-Path (Join-Path $RepoRoot 'Evidence/Pester')).Path
        }

        # EXAMPLE: Load configuration from your repo
        # $config = Import-PowerShellDataFile (Join-Path $RepoRoot 'DSC\Data\AllNodes.psd1')
        # $node = $config.AllNodes | Where-Object NodeName -eq 'localhost'

        # EXAMPLE: Set up test data in script scope (available to all tests)
        # $script:ExpectedValue = $node.SomeSetting
    }

    It "Example test: PowerShell version is 7+" {
        $PSVersionTable.PSVersion.Major | Should -BeGreaterOrEqual 7
    }

    It "Example test: Repo root exists" {
        Test-Path $RepoRoot | Should -BeTrue
    }

    It "Example test: Can load AllNodes.psd1" {
        $configPath = Join-Path $RepoRoot 'DSC\Data\AllNodes.psd1'
        Test-Path $configPath | Should -BeTrue
        
        $config = Import-PowerShellDataFile $configPath
        $config | Should -Not -BeNullOrEmpty
        $config.AllNodes | Should -Not -BeNullOrEmpty
    }
}

# ==============================================================================
# PATTERN 2: Dynamic Test Generation
# ==============================================================================
# Use this pattern when you want to generate tests from data (e.g., test each file
# in a folder, or test each required module).

Describe "Dynamic Test Example" {

    BeforeDiscovery {
        # REQUIRED: Accept parameters from the test harness
        param($RepoRoot, $EvidenceDir)

        # IMPORTANT: Fallback logic for when parameters aren't injected
        if (-not $RepoRoot) {
            $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
        }

        # Generate list of items to test (runs during discovery phase)
        # This example creates tests for each required PowerShell module
        $script:RequiredModules = @(
            'Pester'
            'ActiveDirectoryDsc'
            'ComputerManagementDsc'
        )
    }

    BeforeAll {
        # REQUIRED: Accept parameters from the test harness
        param($RepoRoot, $EvidenceDir)

        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'

        # IMPORTANT: Fallback logic for when parameters aren't injected
        if (-not $RepoRoot) {
            $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
        }
        if (-not $EvidenceDir) {
            $EvidenceDir = (Resolve-Path (Join-Path $RepoRoot 'Evidence/Pester')).Path
        }

        # Any setup that runs before tests execute
    }

    # This creates one test for EACH module in $RequiredModules
    It "Module '<_>' should be installed" -ForEach $RequiredModules {
        # $_ represents the current module name in the loop
        Get-Module -ListAvailable -Name $_ | Should -Not -BeNullOrEmpty
    }
}

# ==============================================================================
# COMMON PATTERNS AND TIPS
# ==============================================================================

Describe "Common Testing Patterns" {

    BeforeAll {
        param($RepoRoot, $EvidenceDir)
        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'

        # IMPORTANT: Fallback logic
        if (-not $RepoRoot) {
            $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
        }
        if (-not $EvidenceDir) {
            $EvidenceDir = (Resolve-Path (Join-Path $RepoRoot 'Evidence/Pester')).Path
        }
    }

    Context "File and Directory Tests" {
        
        It "Tests a file exists" {
            $testFile = Join-Path $RepoRoot 'README.md'
            Test-Path $testFile | Should -BeTrue
        }

        It "Tests a directory exists" {
            $testDir = Join-Path $RepoRoot 'Tests\Pester'
            Test-Path $testDir -PathType Container | Should -BeTrue
        }
    }

    Context "Service and Process Tests" {
        
        It "Tests a Windows service status" {
            $service = Get-Service -Name 'W32Time' -ErrorAction SilentlyContinue
            $service | Should -Not -BeNullOrEmpty
            $service.Status | Should -Be 'Running'
        }
    }

    Context "Network Tests" {
        
        It "Tests network adapter exists" {
            $adapter = Get-NetAdapter -Name 'Ethernet*' -ErrorAction SilentlyContinue
            $adapter | Should -Not -BeNullOrEmpty
        }
    }

    Context "String and Value Tests" {
        
        It "Tests exact string match" {
            $actual = 'Hello'
            $actual | Should -Be 'Hello'
        }

        It "Tests string contains pattern" {
            $actual = 'Hello World'
            $actual | Should -Match 'World'
        }

        It "Tests numeric comparison" {
            $value = 42
            $value | Should -BeGreaterThan 40
            $value | Should -BeLessThan 50
        }
    }
}

# ==============================================================================
# COMMON SHOULD ASSERTIONS
# ==============================================================================
# -Be                  : Exact equality (like -eq)
# -BeTrue / -BeFalse   : Boolean tests
# -BeNullOrEmpty       : Tests for null or empty
# -Match               : Regex pattern matching
# -Contain             : Array/collection contains item
# -BeGreaterThan       : Numeric comparison
# -BeLessThan          : Numeric comparison
# -Exist               : File/path exists (alternative to Test-Path)
# -Throw               : Tests that code throws an exception
#
# You can also negate with -Not:
#   Should -Not -Be 'value'
#   Should -Not -BeNullOrEmpty
