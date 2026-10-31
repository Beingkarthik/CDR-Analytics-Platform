# GitHub setup

Open the VS Code terminal at the repository root.

```powershell
git init
git branch -M main
git status
git add .
git status
git commit -m "Initial CDR analytics platform"
git remote add origin YOUR_GITHUB_REPOSITORY_URL
git remote -v
git push -u origin main
```

For later changes:

```powershell
git add .
git commit -m "Update CDR pipeline"
git push
```

Before the first commit, verify that `.env` and `.venv` are NOT listed by:

```powershell
git status
```
