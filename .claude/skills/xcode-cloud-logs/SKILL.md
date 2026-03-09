---
name: xcode-cloud-logs
description: Fetch Xcode Cloud build logs, status, and results from App Store Connect API. Use when the user asks about build status, build logs, why a build failed, CI/CD results, Xcode Cloud workflows, or anything related to App Store Connect CI builds.
---

# Xcode Cloud Build Verification

## Autonomous Build-Fix Workflow

This skill enables an autonomous code-build-fix loop:

1. **Make changes** to the code
2. **Push** to trigger Xcode Cloud build
3. **Check build status** with `python3 scripts/xcode_cloud.py check`
4. **If failed**: logs are included automatically - analyze and fix
5. **Repeat** until build succeeds

### Quick Check Command

```bash
# Check build status for current git branch (auto-reads workflow ID from project.yml)
python3 scripts/xcode_cloud.py check

# Check specific branch
python3 scripts/xcode_cloud.py check --branch main
```

- Returns exit code 0 for success/running, 1 for failed
- Automatically includes build logs when failed
- Reads `XCODE_CLOUD_BRANCH_BUILD_WORKFLOW_ID` from `project.yml` in repo root

### Project Configuration

The script reads from `project.yml` in the repo root:

```yaml
XCODE_CLOUD_PRODUCT_ID: <product_id>
XCODE_CLOUD_BRANCH_BUILD_WORKFLOW_ID: <workflow_id>
```

When configured, just run `python3 scripts/xcode_cloud.py check` - no IDs needed.

---

# Full API Reference

## Setup

**Requirements:** `pip install PyJWT requests`

**Environment Variables:**

```bash
export ASC_KEY_ID="your-key-id"           # API Key ID from App Store Connect
export ASC_ISSUER_ID="your-issuer-id"     # Issuer ID from App Store Connect
export ASC_PRIVATE_KEY_BASE64="..."       # Base64-encoded private key
```

**To encode your private key:**

```bash
base64 < /path/to/AuthKey_XXXXXX.p8
```

## Commands

### Xcode Cloud Commands

| Command | Description |
|---------|-------------|
| `check [workflow_id] [-b BRANCH]` | Check build status for current/specified branch |
| `products` | List apps with Xcode Cloud enabled |
| `workflows <product_id>` | List workflows for a product |
| `builds <workflow_id> [--limit N]` | List recent builds (default: 1) |
| `status <build_id>` | Get build status and actions |
| `logs <build_id> [--action NAME]` | Get build logs |
| `artifacts <build_id>` | List build artifacts |

### Workflow Management

| Command | Description |
|---------|-------------|
| `workflow-get <workflow_id>` | Get full workflow details as JSON |
| `workflow-clone <source_wf> <target_product>` | Clone a workflow to another product (copies all triggers) |
| `workflow-delete <workflow_id> [-f]` | Delete a workflow |

**workflow-clone options:** `--name`, `--scheme`, `--container`

**Note:** For workflow updates, use the `api` command with PATCH requests for full control over all workflow attributes including triggers.

### Raw API Access

```bash
python3 scripts/xcode_cloud.py api <endpoint> [--method METHOD] [--params key=value ...] [--body JSON]
```

Examples:
```bash
python3 scripts/xcode_cloud.py api apps
python3 scripts/xcode_cloud.py api betaTesters --params limit=50
python3 scripts/xcode_cloud.py api apps/123 --method PATCH --body '{"data": {...}}'
```

## API Reference

Common endpoints:
- `apps` - List/manage apps
- `ciProducts` - Xcode Cloud products
- `ciWorkflows` - CI workflows
- `ciBuildRuns` - Build runs
- `betaTesters` - TestFlight testers

Full schema: https://developer.apple.com/documentation/appstoreconnectapi
