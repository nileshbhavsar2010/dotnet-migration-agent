# SRP-Based .NET Migration Workflow

## Overview
Token-optimized migration using three single-responsibility skills.

## Skills Available
1. **net-migration-analyzer** - Analyze & generate update spec (2,500 tokens)
2. **net-migration-updater** - Apply updates (3,000 tokens)  
3. **net-migration-verifier** - Build & test (2,000 tokens)

## Usage Workflows

### Fast Track (5,500 tokens) 
For code review + confident team:
```bash
# 1. Analyze
→ net-migration-analyzer (target: "10.0")
  Output: Update specification JSON

# 2. Update  
→ net-migration-updater (apply spec)
  Output: Change confirmation

# SKIP VERIFICATION (saves 2,000 tokens)
# Schedule `dotnet build` locally or in CI
```

**Savings: 60% vs monolithic approach**

---

### Complete Flow (7,500 tokens)
For rigorous validation:
```bash
# 1. Analyze
→ net-migration-analyzer (target: "10.0")
  Output: Update specification + breaking changes report

# 2. Update
→ net-migration-updater (apply spec)
  Output: Change confirmation

# 3. Verify
→ net-migration-verifier (build + test)
  Output: Build status + test results
```

**Savings: 63% vs monolithic approach**

---

## Token Comparison

| Approach | Tokens | Time | Reusability |
|----------|--------|------|-------------|
| **Previous Monolithic** | 20,500 | ~5 min | Low (migration-only) |
| **SRP Fast Track** | 5,500 | ~3 min | High (reusable skills) |
| **SRP Complete** | 7,500 | ~4 min | High (reusable skills) |

**Savings: 60-73% tokens**

---

## Key Advantages

### 1. **Modularity**
- Each skill has one job
- Skills are independently testable
- Easy to update individual skills

### 2. **Reusability**
- `net-migration-analyzer`: Other version migrations, language upgrades
- `net-migration-updater`: Any batch file update task
- `net-migration-verifier`: Any build validation scenario

### 3. **Flexibility**
- Use all skills or only what you need
- Skip verification for faster execution
- Rerun individual skills if needed

### 4. **Token Efficiency**
- No redundant operations
- No verification reads
- No unnecessary documentation
- Structured data passing between skills

---

## Implementation Steps

### Step 1: Run Analyzer
```bash
# Input
targetVersion: "10.0"
projectPath: "g:\CodeGit\CustomerOrderApi"

# Output: updateSpec.json with all changes needed
```

### Step 2: Run Updater
```bash
# Input: updateSpec from analyzer
# Output: Confirmation of changes applied
```

### Step 3 (Optional): Run Verifier
```bash
# Input: projectPath
# Output: Build + test results
```

---

## File Structure
```
.github/skills/
├── net-migration-analyzer/
│   └── SKILL.md
├── net-migration-updater/
│   └── SKILL.md
└── net-migration-verifier/
    └── SKILL.md
```

## Future Enhancements

1. **Caching** - Store analyzer results for repeated runs
2. **Parallelization** - Run verification in parallel with other tasks
3. **Rollback Skill** - Undo migration if needed
4. **Report Generation** - Optional lightweight summary (not by default)

---

## When to Use Which Approach

| Scenario | Recommended | Tokens |
|----------|-------------|--------|
| Quick migration test | Fast Track | 5,500 |
| Production migration | Complete Flow | 7,500 |
| Just analyzing options | Analyzer only | 2,500 |
| Build validation only | Verifier only | 2,000 |
| Local development | Analyzer only | 2,500 |
