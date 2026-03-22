# Student.Tests.ps1 — BarmBuzz A* Validation Tests
# Tests match actual built objects: PSO-Admins, BB-* GPOs, BoltonAdmins OU

Describe "Student Custom A* Validation Tests" {
    BeforeAll {
        param($RepoRoot, $EvidenceDir)
        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'
        if (-not $RepoRoot) {
            $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
        }
        Import-Module ActiveDirectory -ErrorAction SilentlyContinue
        Import-Module GroupPolicy -ErrorAction SilentlyContinue
    }

    Context "Proof of Life" {
        It "C:\TEST directory exists" {
            Test-Path 'C:\TEST' | Should -BeTrue
        }
        It "C:\TEST\test.txt exists" {
            Test-Path 'C:\TEST\test.txt' | Should -BeTrue
        }
    }

    Context "OU Structure — Tiered Admin Model" {
        It "Bolton OU exists" {
            Get-ADOrganizationalUnit -Filter { Name -eq 'Bolton' } | Should -Not -BeNullOrEmpty
        }
        It "BoltonAdmins OU exists for Tier-1 isolation" {
            Get-ADOrganizationalUnit -Filter { Name -eq 'BoltonAdmins' } | Should -Not -BeNullOrEmpty
        }
        It "Derby OU exists" {
            Get-ADOrganizationalUnit -Filter { Name -eq 'Derby' } | Should -Not -BeNullOrEmpty
        }
        It "Nottingham OU exists nested under Derby" {
            $ou = Get-ADOrganizationalUnit -Filter { DistinguishedName -eq 'OU=Nottingham,OU=Derby,DC=bolton,DC=barmbuzz,DC=test' }
            $ou | Should -Not -BeNullOrEmpty
        }
        It "DerbyAdmins OU exists" {
            Get-ADOrganizationalUnit -Filter { Name -eq 'DerbyAdmins' } | Should -Not -BeNullOrEmpty
        }
    }

    Context "AGDLP Group Model" {
        It "GG-IT-Admins global security group exists" {
            $g = Get-ADGroup -Identity 'GG-IT-Admins'
            $g.GroupScope    | Should -Be 'Global'
            $g.GroupCategory | Should -Be 'Security'
        }
        It "GG-IT-Staff global security group exists" {
            $g = Get-ADGroup -Identity 'GG-IT-Staff'
            $g.GroupScope    | Should -Be 'Global'
        }
        It "DL-FileShare-Bolton-R domain local group exists" {
            $g = Get-ADGroup -Identity 'DL-FileShare-Bolton-R'
            $g.GroupScope    | Should -Be 'DomainLocal'
            $g.GroupCategory | Should -Be 'Security'
        }
        It "DL-FileShare-Derby-R domain local group exists" {
            $g = Get-ADGroup -Identity 'DL-FileShare-Derby-R'
            $g.GroupScope    | Should -Be 'DomainLocal'
        }
        It "GG-Derby-IT-Admins exists" {
            Get-ADGroup -Identity 'GG-Derby-IT-Admins' | Should -Not -BeNullOrEmpty
        }
        It "GG-Nottingham-Ops exists" {
            Get-ADGroup -Identity 'GG-Nottingham-Ops' | Should -Not -BeNullOrEmpty
        }
    }

    Context "User Placement" {
        It "j.smith exists in BoltonUsers OU" {
            $u = Get-ADUser -Identity 'j.smith' -Properties DistinguishedName
            $u.DistinguishedName | Should -Match 'BoltonUsers'
        }
        It "adm.jsmith exists in BoltonAdmins OU" {
            $u = Get-ADUser -Identity 'adm.jsmith' -Properties DistinguishedName
            $u.DistinguishedName | Should -Match 'BoltonAdmins'
        }
        It "r.khan exists in NottinghamUsers OU" {
            $u = Get-ADUser -Identity 'r.khan' -Properties DistinguishedName
            $u.DistinguishedName | Should -Match 'NottinghamUsers'
        }
        It "d.patel exists in DerbyUsers OU" {
            $u = Get-ADUser -Identity 'd.patel' -Properties DistinguishedName
            $u.DistinguishedName | Should -Match 'DerbyUsers'
        }
    }

    Context "GPO Existence and Linking" {
        It "BB-Baseline-Security GPO exists" {
            Get-GPO -Name 'BB-Baseline-Security' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It "BB-Derby-Regional GPO exists" {
            Get-GPO -Name 'BB-Derby-Regional' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It "BB-Admin-Hygiene GPO exists" {
            Get-GPO -Name 'BB-Admin-Hygiene' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It "BB-Nottingham-Ops GPO exists" {
            Get-GPO -Name 'BB-Nottingham-Ops' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It "BB-Baseline-Security is linked to Bolton OU" {
            $links = (Get-GPInheritance -Target 'OU=Bolton,DC=bolton,DC=barmbuzz,DC=test').GpoLinks
            $links.DisplayName | Should -Contain 'BB-Baseline-Security'
        }
        It "BB-Derby-Regional is linked to Derby OU" {
            $links = (Get-GPInheritance -Target 'OU=Derby,DC=bolton,DC=barmbuzz,DC=test').GpoLinks
            $links.DisplayName | Should -Contain 'BB-Derby-Regional'
        }
    }

    Context "Fine-Grained Password Policy (A-grade)" {
        It "PSO-Admins FGPP exists" {
            Get-ADFineGrainedPasswordPolicy -Identity 'PSO-Admins' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It "PSO-Admins has minimum 16 character length" {
            $pso = Get-ADFineGrainedPasswordPolicy -Identity 'PSO-Admins'
            $pso.MinPasswordLength | Should -BeGreaterOrEqual 16
        }
        It "PSO-Admins precedence is 10" {
            $pso = Get-ADFineGrainedPasswordPolicy -Identity 'PSO-Admins'
            $pso.Precedence | Should -Be 10
        }
        It "PSO-Admins is applied to GG-IT-Admins" {
            $subjects = Get-ADFineGrainedPasswordPolicySubject -Identity 'PSO-Admins' | Select-Object -ExpandProperty Name
            $subjects | Should -Contain 'GG-IT-Admins'
        }
    }

    Context "Domain Health" {
        It "AD DS service is running" {
            (Get-Service -Name 'NTDS').Status | Should -Be 'Running'
        }
        It "DNS service is running" {
            (Get-Service -Name 'DNS').Status | Should -Be 'Running'
        }
        It "Domain is bolton.barmbuzz.test" {
            (Get-ADDomain).DNSRoot | Should -Be 'bolton.barmbuzz.test'
        }
    }
}


