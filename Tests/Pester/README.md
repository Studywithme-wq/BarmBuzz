# Tests (Pester Validation)

This folder contains the validation tests for COM5411 (BarmBuzz).  
You use these tests to confirm your build is correct and to create evidence for your submission.

You are NOT expected to write tests (unless explicitly told).  
You are expected to RUN them, interpret the output, and commit the results to Git.

## 1. What these tests do

There are two kinds of tests you will see in this module:

1) Pre-flight tests (environment + inputs)  
These check that your repo is structured correctly and your student files are valid BEFORE a build.

2) Post-build tests (verification)  
These check that the configuration actually achieved the intended state AFTER the build.

Example (Week 1 proof-of-life):
- Post-build test checks that `C:\TEST\test.txt` exists and has the correct contents.

## 2. Where the tests live

- Pester tests live in: `Tests\Pester\`
- Test files typically end with: `.Tests.ps1`

Example:
- `Tests\Pester\Test-ProofOfLife.Tests.ps1`

## 3. How to run tests (exact commands)

IMPORTANT: run these commands from the REPO ROOT (the folder that contains `Run-BarmBuzz.ps1`).

### 3.1 Open PowerShell the correct way
You must run PowerShell as Administrator for the build (DSC), but tests can usually be run without admin.

For consistency:
- Open PowerShell 7 as Administrator.
- `cd` into your repo folder.

### 3.2 Run the test BEFORE orchestration (expected outcome)
Run:
```powershell
Invoke-Pester -Path .\Tests\Pester\Test-ProofOfLife.Tests.ps1 -Output Detailed