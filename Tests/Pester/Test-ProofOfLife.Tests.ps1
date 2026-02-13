# Tests\Pester\Test-ProofOfLife.Tests.ps1
# Post-build proof-of-life: validates the baseline DSC created files
# Run after orchestration. Expected to fail before first successful build.

$ErrorActionPreference = 'Stop'

Describe "Proof-of-Life (DSC created files)" {

    BeforeAll {
        # REQUIRED: Accept injected parameters from the test harness
        param($RepoRoot, $EvidenceDir)

        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'

        # Fallback: If not injected by harness, calculate from test file location
        if (-not $RepoRoot) {
            $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
        }
        if (-not $EvidenceDir) {
            $EvidenceDir = (Resolve-Path (Join-Path $RepoRoot 'Evidence/Pester')).Path
        }

        # You can use $RepoRoot or $EvidenceDir here if needed
        # For now, this test just checks hardcoded paths
    }

    It "C:\\TEST directory exists" {
        Test-Path 'C:\\TEST' | Should -BeTrue
    }

    It "C:\\TEST\\test.txt exists" {
        Test-Path 'C:\\TEST\\test.txt' | Should -BeTrue
    }

    It "test.txt has expected contents" {
        if (-not (Test-Path 'C:\\TEST\\test.txt')) { Set-ItResult -Failed -Because "File missing"; return }
        $content = Get-Content 'C:\\TEST\\test.txt' -ErrorAction Stop -Raw
        $content | Should -Be 'Proof-of-life: DSC created this file.'
    }
}
