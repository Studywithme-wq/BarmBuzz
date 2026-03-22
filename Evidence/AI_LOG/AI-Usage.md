# AI Usage Log

1. **What tasks AI was used for:** 
   I used Antigravity AI to draft the initial boilerplate for PowerShell DSC resources (`ActiveDirectoryDsc`) and cross-reference the A* assignment requirements to ensure the DSC implementation met single-domain excellence with Fine-Grained Password Policies (FGPP). I also used AI to help structure the `README.md` documentation according to the assignment brief.
   
2. **What was accepted vs rejected and why:**
   I accepted the generated `ADDomain`, `ADOrganizationalUnit`, `ADUser`, and `ADGroup` resource declarations because they syntactically match `ActiveDirectoryDsc` 6.6.0. I rejected the AI's suggestion to use absolute paths or multi-node configurations, keeping the node strictly bound to `localhost` to align with the `Run_BuildMain.ps1` orchestrator limitations as mandated by the brief.
   
3. **One concrete example where AI was wrong/incomplete:**
   The AI initially attempted to implement GPOs using the older `xGroupPolicy` module. The orchestrator explicitly imports `GroupPolicyDsc` v1.0.3, so I corrected the configuration to align with the correct naming conventions and modules provided by the tutor. Additionally, the AI initially tried to orchestrate the child domain inside the same configuration script which would require complex orchestration across two VMs. I corrected this by choosing Pathway 1 (FGPP + Privileged Identity Isolation) to keep the pipeline idempotent on a single VM.
   
4. **Statement of Own Work:**
   The final codebase and structure of this submission is my own carefully structured work. AI served solely as an intelligent typist and templating engine, but the architectural intent, delegation of control, and testing strategy reflect my own original design.
