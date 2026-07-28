# SRP Migration Quick Reference

## Current Situation
- **Current Version:** .NET 6.0  
- **Target Version:** .NET 10.0
- **Projects:** 2 (API + Tests)
- **Status:** Ready for migration using SRP skills

## Quick Start: Fast Track (5,500 tokens, 3 minutes)

### Step 1: Analyze Changes
```
Request: "Analyze migration to .NET 10.0 for this project"
↓
Uses: net-migration-analyzer
Output: {
  "globalJson": {...},
  "projects": [...],
  "breakingChanges": [],
  "riskLevel": "low"
}
Tokens: 2,500
```

### Step 2: Apply Updates
```
Request: "Apply the updates from the analysis"
↓
Uses: net-migration-updater
Output: ✅ Updated: global.json
         ✅ Updated: CustomerOrderApi.csproj
         ✅ Updated: CustomerOrderApi.Tests.csproj
Tokens: 3,000
```

### Done!
Push changes and create PR. Build validation happens in CI.

---

## Token Savings Summary

### Previous Monolithic Approach
```
20,500 tokens:
├── Pre-flight reads: 3,000
├── Verification reads: 2,500 ❌ REDUNDANT
├── Multi-replace: 4,000
├── Migration report: 6,000 ❌ UNNECESSARY
├── Report updates: 1,500
└── Todo management: 3,500
```

### New SRP Approach (Fast Track)
```
5,500 tokens:
├── Analyzer: 2,500 (focused, structured output)
└── Updater: 3,000 (batch operation, no fluff)

💰 SAVED: 15,000 tokens (73% reduction)
```

### New SRP Approach (Complete)
```
7,500 tokens:
├── Analyzer: 2,500
├── Updater: 3,000
└── Verifier: 2,000 (optional, reusable)

💰 SAVED: 13,000 tokens (63% reduction)
```

---

## Why SRP Skills Save Tokens

| Traditional | SRP Skills |
|-------------|-----------|
| One skill does everything | Each skill has ONE job |
| Redundant verification reads | No redundant reads |
| Large explanations | Minimal context switching |
| Full documentation | No unnecessary docs |
| Hard to reuse | Highly reusable |
| Mixed concerns | Separated concerns |

---

## Usage by Scenario

### Scenario 1: "Just show me what needs to change"
```
→ Use: net-migration-analyzer only
Tokens: 2,500
Output: Structured change spec (no modifications)
```

### Scenario 2: "Migrate the project"
```
→ Use: net-migration-analyzer + net-migration-updater
Tokens: 5,500
Output: Changes applied, ready for local testing
```

### Scenario 3: "Migrate AND validate"
```
→ Use: All three skills
Tokens: 7,500
Output: Changes applied + build verified
```

### Scenario 4: "Just validate the build"
```
→ Use: net-migration-verifier only (reusable)
Tokens: 2,000
Output: Build status + test results
```

---

## File Locations

```
.github/skills/
├── net-migration-analyzer/SKILL.md
├── net-migration-updater/SKILL.md
├── net-migration-verifier/SKILL.md
├── SRP_WORKFLOW.md (full documentation)
└── SRP_QUICK_REFERENCE.md (this file)
```

---

## Next Steps

1. **Review the update specification** from analyzer before applying
2. **Apply updates** using updater skill
3. **Local testing:** `dotnet build && dotnet test`
4. **Create PR** with changes
5. **CI validation** handles final verification

---

## Support

For detailed workflow information, see [SRP_WORKFLOW.md](./SRP_WORKFLOW.md)

For individual skill details:
- [Analyzer Skill](./net-migration-analyzer/SKILL.md)
- [Updater Skill](./net-migration-updater/SKILL.md)
- [Verifier Skill](./net-migration-verifier/SKILL.md)
