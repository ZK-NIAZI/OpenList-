# Daily Branch Workflow

**Purpose**: Create a separate branch for each day's work to maintain clean history and easy rollback.

---

## Daily Workflow

### Start of Day

1. **Create today's branch from main**
   ```bash
   git checkout main
   git pull origin main
   git checkout -b dev-$(date +%Y-%m-%d)
   ```

2. **Push branch to remote**
   ```bash
   git push -u origin dev-$(date +%Y-%m-%d)
   ```

3. **Start working**
   - Make changes
   - Commit frequently with descriptive messages

---

### During the Day

**Commit your work regularly**:
```bash
git add .
git commit -m "feat: description of what you did"
git push origin dev-$(date +%Y-%m-%d)
```

**Commit Message Prefixes**:
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `refactor:` - Code refactoring
- `test:` - Adding tests
- `chore:` - Maintenance tasks

---

### End of Day

1. **Final commit and push**
   ```bash
   git add .
   git commit -m "chore: end of day commit - [summary of work]"
   git push origin dev-$(date +%Y-%m-%d)
   ```

2. **Merge to main (if work is complete and tested)**
   ```bash
   git checkout main
   git merge dev-$(date +%Y-%m-%d)
   git push origin main
   ```

3. **Keep branch for history** (don't delete)
   - Daily branches serve as checkpoints
   - Easy to review what was done each day
   - Can rollback to any day if needed

---

## Branch Naming Convention

Format: `dev-YYYY-MM-DD`

Examples:
- `dev-2026-02-26` - February 26, 2026
- `dev-2026-02-27` - February 27, 2026
- `dev-2026-03-01` - March 1, 2026

---

## Quick Commands

### Windows PowerShell
```powershell
# Create today's branch
$date = Get-Date -Format "yyyy-MM-dd"
git checkout main
git pull origin main
git checkout -b "dev-$date"
git push -u origin "dev-$date"

# End of day merge
git checkout main
git merge "dev-$date"
git push origin main
```

### Linux/Mac Bash
```bash
# Create today's branch
git checkout main
git pull origin main
git checkout -b dev-$(date +%Y-%m-%d)
git push -u origin dev-$(date +%Y-%m-%d)

# End of day merge
git checkout main
git merge dev-$(date +%Y-%m-%d)
git push origin main
```

---

## Example Timeline

```
main
  │
  ├─ dev-2026-02-26 (AI extraction feature)
  │   └─ Merged to main
  │
  ├─ dev-2026-02-27 (Friends system start)
  │   └─ Merged to main
  │
  ├─ dev-2026-02-28 (Friends system complete)
  │   └─ Merged to main
  │
  └─ dev-2026-03-01 (Image upload feature)
      └─ In progress...
```

---

## Benefits

1. **Clear History**: See exactly what was done each day
2. **Easy Rollback**: Can revert to any day's state
3. **Safe Experimentation**: Try things without affecting main
4. **Team Visibility**: Team lead can see daily progress
5. **Clean Main Branch**: Main only has tested, complete work

---

## Current Branches

- `main` - Production-ready code
- `dev-2026-02-26` - Today's work (AI extraction, documentation, repo setup)
- `backup-2026-02-26-ai-extraction-complete` - Backup checkpoint
- `backup-2026-02-26-with-backup-tools` - Backup checkpoint
- `backup-2026-02-26-complete-with-docs` - Backup checkpoint

---

## Tips

1. **Commit often** - Small, focused commits are better
2. **Push regularly** - Don't lose work if computer crashes
3. **Descriptive messages** - Future you will thank you
4. **Test before merging** - Only merge working code to main
5. **Keep branches** - Don't delete daily branches (they're your history)

---

## Troubleshooting

### Forgot to create daily branch
```bash
# Create branch from current state
git checkout -b dev-2026-02-26
git push -u origin dev-2026-02-26
```

### Need to switch to different day's branch
```bash
git checkout dev-2026-02-25
```

### Want to see all daily branches
```bash
git branch -a | grep dev-
```

### Merge conflicts
```bash
# If conflict occurs during merge
git status  # See conflicted files
# Fix conflicts manually
git add .
git commit -m "merge: resolve conflicts from dev-2026-02-26"
git push origin main
```

---

**Status**: Workflow active  
**Current Branch**: dev-2026-02-26  
**Last Updated**: February 26, 2026
