# SuperSimple

## Xcode Cloud Workflow

This project uses Xcode Cloud for CI/CD with an autonomous build-fix loop.

### Configuration

Project IDs are stored in `project.yml`:
- `XCODE_CLOUD_PRODUCT_ID` - App Store Connect product ID
- `XCODE_CLOUD_BRANCH_BUILD_WORKFLOW_ID` - Workflow ID for branch builds

### Build-Fix Loop

1. Make code changes
2. Commit and push to branch
3. Check build status: `python3 .claude/skills/xcode-cloud-logs/scripts/xcode_cloud.py check`
4. If failed, logs are included automatically - analyze and fix
5. Repeat until build succeeds

**When to use:** Run the full cloud build loop for meaningful commits, not every tiny change. For incremental work, a local Swift syntax sanity check is sufficient. Reserve cloud builds for when you're ready to validate a complete piece of work.

### Skill Commands

```bash
# Check build status for current branch
python3 .claude/skills/xcode-cloud-logs/scripts/xcode_cloud.py check

# Check specific branch
python3 .claude/skills/xcode-cloud-logs/scripts/xcode_cloud.py check --branch <branch-name>

# Get build logs
python3 .claude/skills/xcode-cloud-logs/scripts/xcode_cloud.py logs <build_id>

# List recent builds
python3 .claude/skills/xcode-cloud-logs/scripts/xcode_cloud.py builds <workflow_id>
```

### Required Environment Variables

```bash
ASC_KEY_ID=<your-key-id>
ASC_ISSUER_ID=<your-issuer-id>
ASC_PRIVATE_KEY_BASE64=<base64-encoded-private-key>
```
