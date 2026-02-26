# Git Ownership Transfer Guide

**Date**: February 26, 2026  
**Project**: OpenList  
**Transfer To**: Team Lead

---

## Option 1: Transfer via GitHub/GitLab (Recommended)

### If Repository is on GitHub:

#### Step 1: Push to GitHub (if not already)
```bash
# Add remote repository (replace with actual URL)
git remote add origin https://github.com/YOUR_USERNAME/openlist.git

# Push all branches
git push -u origin master
git push origin --all

# Push all tags
git push origin --tags
```

#### Step 2: Transfer Repository Ownership
1. Go to repository on GitHub
2. Click **Settings** tab
3. Scroll down to **Danger Zone**
4. Click **Transfer ownership**
5. Enter team lead's GitHub username
6. Confirm transfer

#### Step 3: Team Lead Accepts Transfer
- Team lead receives email notification
- They accept the transfer
- Repository moves to their account

---

### If Repository is on GitLab:

#### Step 1: Push to GitLab (if not already)
```bash
# Add remote repository
git remote add origin https://gitlab.com/YOUR_USERNAME/openlist.git

# Push all branches
git push -u origin master
git push origin --all
```

#### Step 2: Transfer Project
1. Go to project on GitLab
2. Click **Settings** → **General**
3. Expand **Advanced** section
4. Click **Transfer project**
5. Enter team lead's username
6. Confirm transfer

---

## Option 2: Create New Repository Under Team Lead's Account

### Step 1: Team Lead Creates Repository
Team lead creates new repository on GitHub/GitLab:
- Repository name: `openlist`
- Visibility: Private (recommended)
- Don't initialize with README

### Step 2: Change Remote URL
```bash
# Remove old remote (if exists)
git remote remove origin

# Add new remote (team lead's repository)
git remote add origin https://github.com/TEAMLEAD_USERNAME/openlist.git

# Push all branches
git push -u origin master
git push origin --all

# Push all tags
git push origin --tags
```

### Step 3: Verify Transfer
```bash
# Check remote URL
git remote -v

# Should show team lead's repository
```

---

## Option 3: Add Team Lead as Collaborator (Alternative)

If you want to keep the repository but give team lead full access:

### On GitHub:
1. Go to repository **Settings**
2. Click **Collaborators**
3. Click **Add people**
4. Enter team lead's GitHub username
5. Select **Admin** role
6. Send invitation

### On GitLab:
1. Go to project **Settings** → **Members**
2. Click **Invite members**
3. Enter team lead's username
4. Select **Maintainer** role
5. Click **Invite**

---

## Option 4: Local Transfer (No GitHub/GitLab)

If you want to transfer just the local repository:

### Step 1: Create Bundle
```bash
# Create a complete bundle of the repository
git bundle create openlist-complete.bundle --all

# This creates a file containing entire repository history
```

### Step 2: Transfer Bundle File
- Send `openlist-complete.bundle` to team lead via:
  - Email (if small)
  - Google Drive / Dropbox
  - USB drive
  - Network share

### Step 3: Team Lead Clones from Bundle
Team lead runs:
```bash
# Clone from bundle
git clone openlist-complete.bundle openlist

# Navigate to directory
cd openlist

# Add remote (if needed)
git remote add origin https://github.com/TEAMLEAD_USERNAME/openlist.git

# Push to remote
git push -u origin master
git push origin --all
```

---

## Pre-Transfer Checklist

Before transferring, make sure:

- [ ] All changes are committed
  ```bash
  git status
  # Should show "nothing to commit, working tree clean"
  ```

- [ ] All branches are pushed (if using remote)
  ```bash
  git branch -a
  # Verify all branches are listed
  ```

- [ ] Backup created
  ```bash
  # Create backup branch
  git checkout -b backup-before-transfer-$(date +%Y-%m-%d)
  git checkout master
  ```

- [ ] Working files moved out of project
  - ✅ Already done (moved to ../openlist-working-files)

- [ ] Documentation is complete
  - ✅ PROJECT_EXECUTION_REPORT.md created
  - ✅ README.md exists

- [ ] Sensitive data removed
  - Check for API keys in code
  - Check for passwords
  - Check .env files

---

## Post-Transfer Steps

### For You:
1. Update your local remote URL (if using Option 2)
   ```bash
   git remote set-url origin https://github.com/TEAMLEAD_USERNAME/openlist.git
   ```

2. Pull latest changes
   ```bash
   git pull origin master
   ```

3. Continue working as usual

### For Team Lead:
1. Clone repository (if new to them)
   ```bash
   git clone https://github.com/TEAMLEAD_USERNAME/openlist.git
   cd openlist
   ```

2. Verify all branches
   ```bash
   git branch -a
   ```

3. Check commit history
   ```bash
   git log --oneline --graph --all -10
   ```

4. Set up development environment
   - Install Flutter
   - Run `flutter pub get`
   - Configure Supabase credentials

---

## Recommended Approach

**For your situation, I recommend Option 2**:

1. Team lead creates new repository
2. You change remote URL to point to their repository
3. Push all branches
4. Both of you can continue working

This is cleanest and gives team lead full control while preserving all history.

---

## Quick Commands Summary

```bash
# Check current status
git status
git remote -v
git branch -a

# Create final backup
git checkout -b backup-before-transfer-2026-02-26
git checkout master

# Change remote to team lead's repository
git remote remove origin
git remote add origin https://github.com/TEAMLEAD_USERNAME/openlist.git

# Push everything
git push -u origin master
git push origin --all
git push origin --tags

# Verify
git remote -v
git log --oneline -5
```

---

## Troubleshooting

### Issue: "Permission denied"
**Solution**: Team lead needs to give you push access or create repository first

### Issue: "Repository not found"
**Solution**: Verify repository URL is correct

### Issue: "Failed to push some refs"
**Solution**: Pull first, then push
```bash
git pull origin master --rebase
git push origin master
```

### Issue: "Large files rejected"
**Solution**: Use Git LFS or remove large files
```bash
# Check file sizes
find . -type f -size +50M

# Remove from history if needed
git filter-branch --tree-filter 'rm -f path/to/large/file' HEAD
```

---

## Contact Information

If you need help during transfer:
- Team Lead: [email/phone]
- Git Documentation: https://git-scm.com/docs
- GitHub Support: https://support.github.com
- GitLab Support: https://about.gitlab.com/support

---

**Status**: Ready for transfer  
**Backup Status**: ✅ 3 backup branches created  
**Working Files**: ✅ Moved to ../openlist-working-files  
**Documentation**: ✅ Complete
