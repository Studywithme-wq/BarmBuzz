# COM5411 Enterprise Operating Systems — BarmBuzz Solution

**GitHub Repository:** https://github.com/Studywithme-wq/BarmBuzz
**ZIP version note:** This ZIP matches the repository as of the final commit on the main branch. See `Evidence\Git\GitLog.txt` for the exact commit hash.

---

## 1. Solution Overview

A fully automated, single-domain enterprise Active Directory Domain Service (AD DS) environment is built for the BarmBuzz organization. This implementation uses only PowerShell Desired State Configuration (DSC) v3, which acts as the primary control plane for the infrastructure. To represent the Bolton headquarters as the authoritative identity boundary for the organization, `bolton.barmbuzz.test` acts as the forest root domain — a single domain forest running on Windows Server 2025 (Hester and Henley, 2013).

The build targets the following components: a Windows Server 2025 Domain Controller running on a VirtualBox virtual machine, a Windows 10 client for Group Policy validation, and an Ubuntu virtual machine to verify cross-platform authentication. The two student-authored files, `DSC\Data\AllNodes.psd1` and `DSC\Configurations\StudentConfig.ps1`, define the desired state and are responsible for converging the system idempotently on every run.

This submission implements Pathway 1 — single-domain security excellence — rather than a Derby child domain (Smirnov, 2024). Fine-Grained Password Policies (FGPP) are used to demonstrate enterprise-correct privileged identity management alongside a tiered OU model aligned with Microsoft's Enhanced Security Admin Environment (ESAE). Derby and Nottingham are implemented as Organisational Units within the single domain.



## 2. Architectural Scope and Boundaries

### Forest and Domain Boundary Justification

A critical architectural decision was to maintain BarmBuzz as a single domain. Active Directory acts as a replication boundary while administrative boundaries are enforced through Organisational Units. All directory data replicates automatically, but users and policies remain separated through OUs. This reduces the complexity of a multi-domain topology and provides flexible regional management (Berkouwer, 2022).

### Tier Model

Microsoft's ESAE-aligned tier framework is implemented. Tier 0 covers domain controllers and highly privileged accounts. Tier 1 covers server and infrastructure management. Tier 2 covers standard user accounts and workstations. This decision mitigates the risk of lateral movement, where a compromise at a lower tier cannot easily escalate to higher-tier systems.

### Organisational Units

Admin accounts are separated into dedicated OUs — `OU=BoltonAdmins` and `OU=DerbyAdmins` — ensuring that user policies and admin policies do not interfere with each other. Administrative accounts cannot be exposed to weak user-level policy restrictions, and the tiered OU structure enables GPO scoping to privileged identities exclusively. An exported OU structure confirming all eleven OUs at their correct Distinguished Name paths is available at `Evidence\AD\OUs_final.csv`.

### AGDLP Model

Access control follows the AGDLP model — Accounts placed in Global Groups representing roles, nested inside Domain Local Groups holding resource permissions. No user ever receives a direct permission assignment. As a concrete example, `j.smith` is placed in `GG-IT-Staff` (Global Group), which is nested inside `DL-FileShare-Bolton-R` (Domain Local Group), which holds the read permission on the Bolton file share (Krause, 2023). This aligns with NIST SP 800-53 AC-6 (Least Privilege) (Joint Task Force Interagency Working Group, 2020).

For the Derby regional IT team, specific permissions are delegated at the OU level. `GG-Derby-IT-Admins` holds Create and Delete User object rights over `OU=Derby`, enabling regional administration without Domain Admin membership.



## 3. Automation Strategy

Desired State Configuration is selected over traditional PowerShell scripting because it allows engineers to define the desired system state declaratively rather than writing imperative step-by-step scripts (Petty, Jones and Hicks, 2024). DSC makes the build more predictable, easier to maintain, and aligned with enterprise-grade Infrastructure-as-Code practices (Chaganti, 2018).

DSC provides idempotency — after the first successful build, re-running the script produces no changes. DSC checks current state before applying changes, ensuring only missing or incorrect configurations are corrected. This is critical for reliable rebuilds and repeatable automation.

The configuration logic is divided into nine chronological layers. Layer 0 prepares evidence directories. Layer 1 installs Windows features. Layer 2 promotes the domain using `ADDomain` and waits for availability via `WaitForADDomain`. Layers 3, 4, and 5 create OUs, groups, and users respectively, all dependent on a healthy domain. Layers 6 to 8 configure group memberships, GPOs, and FGPP. Layer 9 automatically collects evidence. This layered design ensures correct execution order and simplifies troubleshooting. The compiled MOF file is produced at `DSC\Outputs\StudentBaseline\localhost.mof` and PowerShell transcripts are stored in `Evidence\Transcripts\` (Siddaway, 2017).

Reboots are handled automatically via the LCM settings `ActionAfterReboot = ContinueConfiguration` and `RebootNodeIfNeeded = $true`, allowing DC promotion to reboot the server and the pipeline to resume without manual intervention.

Security hygiene requires passwords are never stored in plaintext in source control. Credentials are injected at runtime through `Run_BuildMain.ps1` as `PSCredential` objects — `DomainAdminCredential` and `DsrmCredential` are passed as parameters and never appear in committed files. In production these would be sourced from Azure Key Vault at pipeline execution time (Klaffenbach, Damaschke and Michalski, 2017).



## 4. Repository Structure

The repository conforms exactly to the tutor-provided scaffold. Only two files are student-authored: `DSC\Configurations\StudentConfig.ps1` and `DSC\Data\AllNodes.psd1`. All scripts use repo-relative paths via `$PSScriptRoot`.

`Run_BuildMain.ps1` is the single entry point. It loads configuration data, compiles DSC via Windows PowerShell 5.1, and applies the configuration. `DSC\Data\AllNodes.psd1` stores all environment data — IP addresses, domain names, OU paths, users, groups — separated from logic to maximise maintainability and scalability. `DSC\Configurations\StudentConfig.ps1` contains the full DSC logic for domain setup, OU creation, group and user provisioning, RBAC, GPO deployment, and FGPP.

The `Tests\Pester\` folder contains tutor-provided test files (`ADDS_Promotion.Tests.ps1`, `Baseline.Tests.ps1`, `PreDCPromo.Tests.ps1`) and the student-authored test file (`Student.Tests.ps1`). The `Scripts\Prereqs\` folder contains tutor-provided one-shot scripts for LCM configuration and network setup, called automatically during Phase 1.

```
BarmBuzz/
├── Run_BuildMain.ps1
├── README.md
├── DSC/
│   ├── Configurations/StudentConfig.ps1
│   ├── Data/AllNodes.psd1
│   └── Outputs/StudentBaseline/localhost.mof
├── Scripts/
│   └── Prereqs/
│       ├── BarmBuzz_OneShot_LCM.ps1
│       └── BarmBuzz_OneShot_Network.ps1
├── Tests/
│   └── Pester/
│       ├── Invoke-Validation.ps1
│       └── Student.Tests.ps1
└── Evidence/
    ├── Transcripts/
    ├── AD/
    ├── GPOBackups/
    ├── HealthChecks/
    ├── Pester/
    ├── Screenshots/
    ├── Git/Reflog/
    └── AI_LOG/AI-Usage.md
```


## 5. Execution Order (Run Book)

### Preconditions

The Windows Server VM must be running on VirtualBox with a static IP of `192.168.56.10` on the host-only adapter (`Ethernet`) and a NAT adapter (`Ethernet 2`) for internet access. PowerShell 7 must be open as Administrator. No prior AD DS installation should exist.

Clone the repository:

```powershell
git clone https://github.com/Studywithme-wq/BarmBuzz C:\BarmBuzz
cd C:\BarmBuzz
```

### Step-by-Step Sequence

**Step 1 — Run the orchestrator:**
```powershell
.\Run_BuildMain.ps1
```
Phase 1 configures LCM and network. Phase 2 compiles the MOF via Windows PowerShell 5.1 and begins AD DS installation.
Verify: `Get-DscLocalConfigurationManager | Select-Object ActionAfterReboot, RebootNodeIfNeeded`

**Step 2 — Automatic reboot:**
The server reboots automatically for DC promotion. This is the only reboot point. Log back in as `Administrator / superw1n_user`. LCM resumes automatically — no manual intervention required.

**Step 3 — Wait for LCM to complete:**
```powershell
Get-DscConfigurationStatus | Select-Object Status
```
Expected: Status shows `Success`.

**Step 4 — Verify AD objects:**
```powershell
Get-ADDomain | Select-Object DNSRoot, NetBIOSName
Get-ADOrganizationalUnit -Filter * | Select-Object Name, DistinguishedName
Get-ADUser -Filter * | Select-Object SamAccountName, Enabled
Get-ADGroup -Filter * | Select-Object Name, GroupScope
Get-GPO -All | Select-Object DisplayName, GpoStatus
Get-ADFineGrainedPasswordPolicy -Filter * | Select-Object Name, Precedence, MinPasswordLength
```

**Step 5 — Run Pester validation:**
```powershell
.\Tests\Pester\Invoke-Validation.ps1
```
Expected: 109+ tests passing. Results saved to `Evidence\Pester\PesterResults_*.xml`.


## 6. Idempotence and Re-run Behaviour

### Re-Run Expectations

Running `.\Run_BuildMain.ps1` a second time yields no new configuration changes. The second build completes in under one minute, confirming the system is already in the desired state and proving the build process is repeatable and safe to re-run (Lee, 2023).

The LCM compares current state against desired state before each resource. If they match, the `SetScript` is never called. This prevents duplication of AD objects (users, OUs, policies), protects against configuration drift, and ensures consistency across multiple executions.

The `DependsOn` property enforces strict execution ordering. `WaitForADDomain` must complete before any AD object is created. Parent OUs must exist before child OUs. Groups must exist before memberships are assigned. FGPP depends on admin groups existing. These constraints prevent critical failures and ensure reliable orchestration (Chaganti, 2018).

The only resource that always runs is the `CollectEvidence` script, which has `TestScript = { return $false }` intentionally, ensuring fresh evidence is captured on every run.

### Evidence

Proof of idempotency is provided by comparing `Evidence\Transcripts\[first_run]_Run_BuildMain.txt` with `Evidence\Transcripts\[second_run]_Run_BuildMain.txt`. The first run shows each DSC resource executing its `SetScript`. The second run shows every resource returning from `TestScript` without invoking `SetScript`, confirming zero configuration drift (Siddaway, 2017). The compiled MOF at `DSC\Outputs\StudentBaseline\localhost.mof` provides an inspectable record of the desired state.



## 7. Validation and Testing Model

### What Evidence Proves

| Category | What is proved | Evidence |
|---|---|---|
| Domain health | AD DS, DNS, Netlogon, KDC running | `ADDS_Promotion.Tests`; `dcdiag_final.txt` |
| OU structure | All 11 OUs at correct paths | `Student.Tests`; `OUs_final.csv` |
| AGDLP groups | GG and DL groups with correct scope | `Student.Tests`; `Groups_final.csv` |
| User placement | All 8 users in correct OUs | `Student.Tests`; `Users_final.csv` |
| GPO existence | 4 GPOs linked to correct OUs | `Student.Tests`; `GPOList_*.txt` |
| GPO application | Policy applied to DC | `gpresult_DC.txt` |
| FGPP | PSO-Admins applied to admin groups | `FGPP_final.txt`; `Student.Tests` |
| Idempotence | Second run has zero changes | Second run transcript |
| Ubuntu join | Identity resolution working | `Evidence\Transcripts\Ubuntu_join.txt` |
| Screenshots | Build milestones and AD state | `Evidence\Screenshots\` |

The student-authored test file `Tests\Pester\Student.Tests.ps1` extends the tutor harness with additional assertions covering OU existence, AGDLP group scope, user placement, GPO linking, FGPP parameters, and domain service health — specifically targeting the A-grade and A* criteria.

### How to Run Tests

```powershell
cd C:\BarmBuzz
.\Tests\Pester\Invoke-Validation.ps1
```

Results are saved automatically to `Evidence\Pester\PesterResults_[timestamp].xml` in NUnit XML format.

### Interpreting Failures

If AD service tests fail, check `Evidence\HealthChecks\dcdiag_final.txt` for NTDS or DNS errors — most commonly caused by time synchronisation issues. If OU tests fail, verify the `DependsOn` chain and check `Evidence\DSC\*_apply_verbose.txt`. If GPO link tests fail, SYSVOL may not have been ready — re-running the build resolves this as GPO Script resources are idempotent. If FGPP tests fail, verify domain functional level using `Get-ADDomain | Select-Object DomainMode`.



## 8. Security Considerations

### Credential Handling Trade-offs

Fixed passwords are injected at runtime through `Run_BuildMain.ps1`. `PSDscAllowPlainTextPassword = $true` is set in `AllNodes.psd1` for this lab context. In a production environment, `PsDscAllowPlainTextPassword = $false` would be enforced with certificate-encrypted MOF files, and credentials would be sourced from Azure Key Vault at pipeline execution time (Klaffenbach, Damaschke and Michalski, 2017). This prevents any credential exposure in source control (Joint Task Force Interagency Working Group, 2020).

### RBAC Rationale and Least Privilege

The AGDLP model ensures no user holds direct resource permissions. Access is granted and revoked at the group level, aligning with NIST SP 800-53 AC-6 and reducing lateral movement risk (Das, 2024; Hicks, 2016).

### GPO Security Justification

| GPO | Risk | Control | Scope |
|---|---|---|---|
| BB-Baseline-Security | LLMNR poisoning (MITRE T1557.001); unlocked sessions | Disable LLMNR; screen lock after 600s | Bolton OU |
| BB-Derby-Regional | USB exfiltration and malware introduction | Disable USBSTOR service (Start=4) | Derby OU |
| BB-Admin-Hygiene | Pass-the-hash via admin on standard workstation (MITRE T1550.002) | Tier isolation flag; Enforced GPO link | BoltonAdmins OU |
| BB-Nottingham-Ops | Configuration drift at sub-regional level | Registry baseline for Nottingham unit | Nottingham OU |

### Fine-Grained Password Policy

`PSO-Admins` applies a 16-character minimum password, 24-password history, 30-day maximum age, and 3-attempt lockout to `GG-IT-Admins` and `GG-Derby-IT-Admins` (Precedence 10). FGPP operates independently of the default domain password policy — it is applied directly to security groups via `Add-ADFineGrainedPasswordPolicySubject`, meaning standard users are entirely unaffected by the stricter requirements. Without FGPP, either end users face unnecessary complexity or privileged accounts receive insufficient policy strength. FGPP resolves this without creating a separate domain (Simos, 2023).


## 9. Evidence Mapping

| Claim | Evidence File |
|---|---|
| Domain `bolton.barmbuzz.test` created | `Evidence\Transcripts\*_Run_BuildMain.txt`; `dcdiag_final.txt` |
| DC services running | `dcdiag_final.txt`; Pester `ADDS_Promotion` context |
| All 11 OUs at correct paths | `Evidence\AD\OUs_final.csv`; `PesterResults_*.xml` |
| All 8 users in correct OUs | `Evidence\AD\Users_final.csv`; Pester User Placement |
| 10 groups with correct scope | `Evidence\AD\Groups_final.csv`; Pester AGDLP context |
| AGDLP nesting GG in DL | `Groups_final.csv` Members column |
| GPOs linked to correct OUs | `GPOList_*.txt`; `GPOLinks_Bolton.txt`; `GPOLinks_Derby.txt` |
| GPO applies to DC | `Evidence\GPOBackups\gpresult_DC.txt` |
| PSO-Admins FGPP with 16-char minimum | `FGPP_final.txt`; `FGPP_Subjects_final.txt`; Pester FGPP |
| Second run idempotent | Second run transcript in `Evidence\Transcripts\` |
| 109 Pester tests passing | `Evidence\Pester\PesterResults_*.xml` |
| DSC compiled MOF | `DSC\Outputs\StudentBaseline\localhost.mof` |
| Ubuntu identity resolution | `Evidence\Transcripts\Ubuntu_join.txt` |
| Screenshots of build milestones | `Evidence\Screenshots\` |
| Git development history | `Evidence\Git\GitLog.txt`; `reflog_DC01.txt` |
| AI usage declared | `Evidence\AI_LOG\AI-Usage.md` |



## 10. Limitations and Reflections

The `PSDesiredStateConfiguration` module on this VM is version 2.0.8, but the tutor-pinned version is 2.0.7. This causes one Pester preflight test failure due to a version mismatch rather than any issue in the configuration or design. The DSC configuration is successfully applied and all functionality works as intended, as evidenced by the files in the Evidence folder.

The GPO Script resources check only for GPO existence, not whether registry values or links are correctly configured. In a production environment, GPO settings would be compared against a known-good backup using `Get-GPOReport` and XML diffing to provide true idempotency for GPO content.

The `GroupMemberships` Script resource uses a `TestScript` that only checks whether `j.smith` is a member of `GG-IT-Staff`. If any other membership is absent, the test still returns true. A production-grade implementation would verify all thirteen membership assignments individually.

Ubuntu SSSD integration was validated through `realm list` and `id user@domain` outputs. A complete production integration would additionally configure Kerberos ticket renewal via `krb5_renewable_lifetime` in `sssd.conf` and validate SSH key-based authentication against AD credentials.

### Self-Assessment

This solution targets the A* Pathway 1 boundary. All requirements from Grade D through A are fully met: automated domain promotion, tiered OU structure, AGDLP group model, four OU-scoped GPOs with proven application, idempotence evidence, Ubuntu cross-platform authentication, and Fine-Grained Password Policy targeting privileged groups. The FGPP approach provides a stronger, more targeted security argument than a child domain, which is the core justification for Pathway 1 over Pathway 2. The primary limitations are the shallow GPO `TestScript` check and absence of full Kerberos validation on the Ubuntu client. Estimated grade: A (75%).


## References

Berkouwer, S. (2022) *Active Directory Administration Cookbook*, 2nd edn. Birmingham: Packt Publishing.

Chaganti, R. (2018) *Pro PowerShell Desired State Configuration*, 2nd edn. New York: Apress.

Das, R. (2024) *The Zero Trust Framework and Privileged Access Management (PAM)*, 1st edn. Boca Raton: CRC Press. doi: 10.1201/9781003470021.

Hester, M. and Henley, C. (2013) *Microsoft Windows Server 2012 Administration: Instant Reference*. Indianapolis: Sybex.

Hicks, R.M. (2016) *Implementing DirectAccess with Windows Server 2016*. New York: Apress.

Joint Task Force Interagency Working Group (2020) *Security and Privacy Controls for Information Systems and Organizations*. Gaithersburg: National Institute of Standards and Technology. doi: 10.6028/NIST.SP.800-53r5.

Klaffenbach, F., Damaschke, J.-H. and Michalski, O. (2017) *Implementing Azure Solutions*, 1st edn. Birmingham: Packt Publishing.

Krause, J. (2023) *Mastering Windows Server 2022*, 4th edn. Birmingham: Packt Publishing.

Lee, T. (2023) *Windows Server Automation with PowerShell Cookbook*, 5th edn. Birmingham: Packt Publishing.

MITRE ATT&CK (2024a) *T1557.001 — LLMNR/NBT-NS Poisoning and SMB Relay*. Available at: https://attack.mitre.org/techniques/T1557/001/ (Accessed: 22 March 2026).

MITRE ATT&CK (2024b) *T1550.002 — Pass the Hash*. Available at: https://attack.mitre.org/techniques/T1550/002/ (Accessed: 22 March 2026).

Petty, J., Jones, D. and Hicks, J. (2024) *Learn PowerShell Scripting in a Month of Lunches*, 2nd edn. Shelter Island: Manning.

Siddaway, R. (2017) *Learn PowerShell Desired State Configuration*. New York: Apress. ISBN: 978-1-4842-2059-7.

Simos, M. (2023) *Zero Trust Overview and Playbook Introduction*, 1st edn. Birmingham: Packt Publishing.

Smirnov, E. (2024) *Building Modern Active Directory*. New York: Apress.