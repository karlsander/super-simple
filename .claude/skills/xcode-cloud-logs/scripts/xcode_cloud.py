#!/usr/bin/env python3
"""
Xcode Cloud API client for fetching build logs and status.
Authenticates via JWT with App Store Connect API.
"""

import argparse
import base64
import os
import subprocess
import sys
from datetime import datetime, timedelta

try:
    import jwt
    import requests
except ImportError:
    print("Error: Required packages not installed. Run: pip install PyJWT requests", file=sys.stderr)
    sys.exit(1)


def get_project_config() -> dict:
    """Read project.yml from git repo root for Xcode Cloud IDs."""
    config = {}
    try:
        # Find git repo root
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, check=True
        )
        repo_root = result.stdout.strip()
        project_yml = os.path.join(repo_root, "project.yml")

        if os.path.exists(project_yml):
            with open(project_yml, "r") as f:
                for line in f:
                    line = line.strip()
                    if line.startswith("XCODE_CLOUD_PRODUCT_ID:"):
                        config["product_id"] = line.split(":", 1)[1].strip()
                    elif line.startswith("XCODE_CLOUD_BRANCH_BUILD_WORKFLOW_ID:"):
                        config["workflow_id"] = line.split(":", 1)[1].strip()
    except:
        pass
    return config

# App Store Connect API credentials from environment variables
KEY_ID = os.environ.get("ASC_KEY_ID")
ISSUER_ID = os.environ.get("ASC_ISSUER_ID")
PRIVATE_KEY_BASE64 = os.environ.get("ASC_PRIVATE_KEY_BASE64")


def get_private_key() -> str:
    """Get private key from base64-encoded environment variable."""
    if not PRIVATE_KEY_BASE64:
        print("Error: ASC_PRIVATE_KEY_BASE64 environment variable not set.", file=sys.stderr)
        print("Set it with: export ASC_PRIVATE_KEY_BASE64=$(base64 < /path/to/AuthKey.p8)", file=sys.stderr)
        sys.exit(1)
    return base64.b64decode(PRIVATE_KEY_BASE64).decode("utf-8")


def check_credentials():
    """Verify all required credentials are set."""
    missing = []
    if not KEY_ID:
        missing.append("ASC_KEY_ID")
    if not ISSUER_ID:
        missing.append("ASC_ISSUER_ID")
    if not PRIVATE_KEY_BASE64:
        missing.append("ASC_PRIVATE_KEY_BASE64")

    if missing:
        print(f"Error: Missing environment variables: {', '.join(missing)}", file=sys.stderr)
        print("\nRequired environment variables:", file=sys.stderr)
        print("  ASC_KEY_ID         - Your App Store Connect API Key ID", file=sys.stderr)
        print("  ASC_ISSUER_ID      - Your App Store Connect Issuer ID", file=sys.stderr)
        print("  ASC_PRIVATE_KEY_BASE64 - Base64-encoded private key", file=sys.stderr)
        print("\nTo encode your key: base64 < /path/to/AuthKey.p8", file=sys.stderr)
        sys.exit(1)


def generate_token() -> str:
    """Generate JWT token for App Store Connect API."""
    check_credentials()
    private_key = get_private_key()

    now = datetime.utcnow()
    payload = {
        "iss": ISSUER_ID,
        "iat": now,
        "exp": now + timedelta(minutes=20),
        "aud": "appstoreconnect-v1",
    }

    return jwt.encode(payload, private_key, algorithm="ES256", headers={"kid": KEY_ID})


class AppStoreConnectAPI:
    BASE_URL = "https://api.appstoreconnect.apple.com/v1"

    def __init__(self):
        self.token = generate_token()
        self.headers = {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json",
        }

    def request(self, method: str, endpoint: str, params: dict = None, json_body: dict = None, silent: bool = False) -> dict:
        """Make a request to any App Store Connect API endpoint."""
        url = endpoint if endpoint.startswith("http") else f"{self.BASE_URL}/{endpoint}"
        resp = requests.request(method, url, headers=self.headers, params=params, json=json_body)
        if not resp.ok:
            if not silent:
                try:
                    error_data = resp.json()
                    errors = error_data.get("errors", [])
                    if errors:
                        error_msgs = [f"{e.get('status', '')} {e.get('title', '')}: {e.get('detail', '')}" for e in errors]
                        print(f"API Error: {'; '.join(error_msgs)}", file=sys.stderr)
                except:
                    print(f"API Error: {resp.status_code} {resp.reason} for {url}", file=sys.stderr)
            resp.raise_for_status()
        return resp.json() if resp.content else {}

    def get(self, endpoint: str, params: dict = None) -> dict:
        return self.request("GET", endpoint, params=params)

    def post(self, endpoint: str, json_body: dict = None, params: dict = None) -> dict:
        return self.request("POST", endpoint, params=params, json_body=json_body)

    def patch(self, endpoint: str, json_body: dict = None, params: dict = None) -> dict:
        return self.request("PATCH", endpoint, params=params, json_body=json_body)

    def delete(self, endpoint: str, params: dict = None) -> dict:
        return self.request("DELETE", endpoint, params=params)

    def list_products(self) -> list:
        """List all CI products (apps with Xcode Cloud enabled)."""
        data = self.get("ciProducts", params={"limit": 200})
        return data.get("data", [])

    def list_workflows(self, product_id: str) -> list:
        """List workflows for a product."""
        data = self.get(f"ciProducts/{product_id}/workflows", params={"limit": 200})
        return data.get("data", [])

    def list_builds(self, workflow_id: str, limit: int = 1) -> list:
        """List recent build runs for a workflow, newest first."""
        params = {"limit": min(limit, 200), "sort": "-number"}
        data = self.get(f"ciWorkflows/{workflow_id}/buildRuns", params=params)
        return data.get("data", [])[:limit]

    def get_latest_build_for_branch(self, workflow_id: str, branch: str) -> dict:
        """Get the latest build for a specific branch."""
        params = {"limit": 50, "sort": "-number", "include": "sourceBranchOrTag"}
        data = self.get(f"ciWorkflows/{workflow_id}/buildRuns", params=params)
        builds = data.get("data", [])
        included = {item["id"]: item for item in data.get("included", [])}

        for build in builds:
            ref_data = build.get("relationships", {}).get("sourceBranchOrTag", {}).get("data")
            if ref_data:
                ref = included.get(ref_data["id"], {})
                ref_name = ref.get("attributes", {}).get("name", "")
                if ref_name == branch:
                    build["_branch"] = ref_name
                    return build
        return {}

    def get_build(self, build_id: str) -> dict:
        """Get details for a specific build run."""
        data = self.get(f"ciBuildRuns/{build_id}")
        return data.get("data", {})

    def get_build_actions(self, build_id: str) -> list:
        """Get actions (steps) for a build run."""
        data = self.get(f"ciBuildRuns/{build_id}/actions", params={"limit": 200})
        return data.get("data", [])

    def get_action_logs(self, action_id: str) -> str:
        """Get logs for a specific build action."""
        try:
            data = self.request("GET", f"ciBuildActions/{action_id}/buildLogs", silent=True)
            logs_url = data.get("data", {}).get("attributes", {}).get("url")
            if logs_url:
                resp = requests.get(logs_url)
                resp.raise_for_status()
                return resp.text
        except:
            pass
        return None

    def get_action_issues(self, action_id: str) -> list:
        """Get issues (errors/warnings) for a build action."""
        try:
            data = self.request("GET", f"ciBuildActions/{action_id}/issueSummaries", params={"limit": 200}, silent=True)
            return data.get("data", [])
        except:
            return []

    def get_artifacts(self, build_id: str) -> list:
        """Get artifacts for a build run via its actions."""
        actions = self.get_build_actions(build_id)
        all_artifacts = []
        for action in actions:
            try:
                data = self.get(f"ciBuildActions/{action['id']}/artifacts", params={"limit": 200})
                artifacts = data.get("data", [])
                for a in artifacts:
                    a["_action_name"] = action.get("attributes", {}).get("name", "Unknown")
                all_artifacts.extend(artifacts)
            except:
                pass
        return all_artifacts

    def download_artifact(self, artifact_id: str) -> bytes:
        """Download an artifact and return its contents."""
        data = self.get(f"ciArtifacts/{artifact_id}")
        download_url = data.get("data", {}).get("attributes", {}).get("downloadUrl")
        if download_url:
            resp = requests.get(download_url)
            resp.raise_for_status()
            return resp.content
        return None

    def get_test_results(self, build_id: str) -> list:
        """Get test results for a build run."""
        actions = self.get_build_actions(build_id)
        results = []
        for action in actions:
            action_id = action["id"]
            try:
                data = self.get(f"ciBuildActions/{action_id}/testResults", params={"limit": 200})
                results.extend(data.get("data", []))
            except:
                pass
        return results

    # Workflow management methods
    def get_workflow(self, workflow_id: str) -> dict:
        """Get full workflow details."""
        data = self.get(f"ciWorkflows/{workflow_id}")
        return data.get("data", {})

    def get_product(self, product_id: str) -> dict:
        """Get product details."""
        data = self.get(f"ciProducts/{product_id}")
        return data.get("data", {})

    def get_product_repository(self, product_id: str) -> dict:
        """Get primary repository for a product."""
        data = self.get(f"ciProducts/{product_id}/primaryRepositories", params={"limit": 1})
        repos = data.get("data", [])
        return repos[0] if repos else {}

    def get_latest_xcode_version(self) -> tuple:
        """Get latest macOS and Xcode version IDs."""
        data = self.get("ciMacOsVersions", params={"limit": 1})
        versions = data.get("data", [])
        if versions:
            # "Latest Release" is typically the first one
            return versions[0]["id"], versions[0]["id"]  # macOS and Xcode share ID for "Latest"
        return None, None

    def create_workflow(self, product_id: str, repository_id: str, name: str,
                       container_file: str, scheme: str, actions: list,
                       start_conditions: dict = None, description: str = "",
                       is_enabled: bool = True, clean: bool = False) -> dict:
        """Create a new workflow with full trigger configuration."""
        mac_version_id, xcode_version_id = self.get_latest_xcode_version()

        # Build attributes with all start conditions
        attributes = {
            "name": name,
            "description": description,
            "isEnabled": is_enabled,
            "clean": clean,
            "containerFilePath": container_file,
            "actions": actions
        }

        # Add all start conditions from source (or defaults)
        if start_conditions:
            for key in ["branchStartCondition", "tagStartCondition", "pullRequestStartCondition",
                        "scheduledStartCondition", "manualBranchStartCondition",
                        "manualTagStartCondition", "manualPullRequestStartCondition"]:
                if key in start_conditions:
                    attributes[key] = start_conditions[key]
        else:
            # Default: all branches trigger if no conditions provided
            attributes["branchStartCondition"] = {
                "source": {"isAllMatch": True, "patterns": []},
                "autoCancel": True
            }

        body = {
            "data": {
                "type": "ciWorkflows",
                "attributes": attributes,
                "relationships": {
                    "product": {"data": {"type": "ciProducts", "id": product_id}},
                    "repository": {"data": {"type": "scmRepositories", "id": repository_id}},
                    "xcodeVersion": {"data": {"type": "ciXcodeVersions", "id": xcode_version_id}},
                    "macOsVersion": {"data": {"type": "ciMacOsVersions", "id": mac_version_id}}
                }
            }
        }

        return self.post("ciWorkflows", json_body=body)

    def delete_workflow(self, workflow_id: str) -> bool:
        """Delete a workflow."""
        self.delete(f"ciWorkflows/{workflow_id}")
        return True


def format_build(build: dict) -> str:
    """Format build info for display."""
    attrs = build.get("attributes", {})
    status = attrs.get("executionProgress", "unknown")
    result = attrs.get("completionStatus", "")
    number = attrs.get("number", "?")
    created = attrs.get("createdDate", "")[:19].replace("T", " ")
    started = attrs.get("startedDate", "")
    finished = attrs.get("finishedDate", "")

    duration = ""
    if started and finished:
        try:
            start_dt = datetime.fromisoformat(started.replace("Z", "+00:00"))
            end_dt = datetime.fromisoformat(finished.replace("Z", "+00:00"))
            delta = end_dt - start_dt
            mins = int(delta.total_seconds() // 60)
            secs = int(delta.total_seconds() % 60)
            duration = f" ({mins}m {secs}s)"
        except:
            pass

    status_icon = {
        "COMPLETE": "✓" if result == "SUCCEEDED" else "✗",
        "RUNNING": "⟳",
        "PENDING": "○",
    }.get(status, "?")

    result_str = f" - {result}" if result else ""
    return f"{status_icon} Build #{number} [{status}{result_str}] {created}{duration}"


def format_action(action: dict) -> str:
    """Format build action for display."""
    attrs = action.get("attributes", {})
    name = attrs.get("name", "Unknown")
    status = attrs.get("executionProgress", "unknown")
    result = attrs.get("completionStatus") or ""

    icon = {"COMPLETE": "✓" if result == "SUCCEEDED" else "✗", "RUNNING": "⟳"}.get(status, "○")
    result_str = f" {result}" if result else ""
    return f"  {icon} {name}: {status}{result_str}"


def cmd_products(api: AppStoreConnectAPI, args):
    """List CI products."""
    products = api.list_products()
    if not products:
        print("No Xcode Cloud products found.")
        return

    print(f"Found {len(products)} product(s):\n")
    for p in products:
        attrs = p.get("attributes", {})
        print(f"  {attrs.get('name', 'Unknown')} (ID: {p['id']})")
        print(f"    Type: {attrs.get('productType', '?')}")


def cmd_workflows(api: AppStoreConnectAPI, args):
    """List workflows for a product."""
    workflows = api.list_workflows(args.product)
    if not workflows:
        print("No workflows found.")
        return

    print(f"Found {len(workflows)} workflow(s):\n")
    for w in workflows:
        attrs = w.get("attributes", {})
        print(f"  {attrs.get('name', 'Unknown')} (ID: {w['id']})")

        # Extract branch info from branchStartCondition
        branch_cond = attrs.get("branchStartCondition") or {}
        source = branch_cond.get("source") or {}
        if source.get("isAllMatch"):
            branch_info = "All branches"
        else:
            patterns = source.get("patterns", [])
            if patterns:
                branch_info = ", ".join(p.get("pattern", "?") for p in patterns)
            else:
                branch_info = "Not configured"
        print(f"    Trigger: {branch_info}")


def cmd_builds(api: AppStoreConnectAPI, args):
    """List recent builds for a workflow."""
    builds = api.list_builds(args.workflow, args.limit)
    if not builds:
        print("No builds found.")
        return

    print(f"Recent builds:\n")
    for b in builds:
        print(format_build(b))
        print(f"    ID: {b['id']}")


def cmd_status(api: AppStoreConnectAPI, args):
    """Get build status."""
    build = api.get_build(args.build_id)
    if not build:
        print(f"Build {args.build_id} not found.")
        return

    print(format_build(build))
    print()

    actions = api.get_build_actions(args.build_id)
    if actions:
        print("Actions:")
        for a in actions:
            print(format_action(a))


def cmd_logs(api: AppStoreConnectAPI, args):
    """Get build logs."""
    import zipfile
    import io

    actions = api.get_build_actions(args.build_id)
    if not actions:
        print("No build actions found.")
        return

    for action in actions:
        attrs = action.get("attributes", {})
        name = attrs.get("name", "Unknown")
        status = attrs.get("completionStatus", "")

        if args.action and args.action.lower() not in name.lower():
            continue

        print(f"\n{'='*60}")
        print(f"Action: {name} [{status}]")
        print(f"{'='*60}\n")

        has_output = False

        # Try to get logs first
        logs = api.get_action_logs(action["id"])
        if logs:
            print(logs)
            has_output = True

        # Get issues (errors/warnings)
        issues = api.get_action_issues(action["id"])
        if issues:
            print("\n--- Issues ---\n")
            for issue in issues:
                issue_attrs = issue.get("attributes", {})
                category = issue_attrs.get("category", "unknown")
                message = issue_attrs.get("message", "No message")
                file_source = issue_attrs.get("fileSource", {})
                file_path = file_source.get("path", "")
                line = file_source.get("lineNumber", "")

                icon = "❌" if category == "ERROR" else "⚠️"
                location = f"{file_path}:{line}" if file_path else ""
                print(f"{icon} [{category}] {message}")
                if location:
                    print(f"   {location}")
            has_output = True

        # Try to get log artifacts if no direct logs
        if not has_output:
            try:
                data = api.get(f"ciBuildActions/{action['id']}/artifacts", params={"limit": 200})
                artifacts = data.get("data", [])
                for artifact in artifacts:
                    artifact_name = artifact.get("attributes", {}).get("fileName", "")
                    if "log" in artifact_name.lower():
                        print(f"Downloading log artifact: {artifact_name}")
                        content = api.download_artifact(artifact["id"])
                        if content:
                            if artifact_name.endswith(".zip"):
                                with zipfile.ZipFile(io.BytesIO(content)) as zf:
                                    for file_name in zf.namelist():
                                        print(f"\n--- {file_name} ---\n")
                                        print(zf.read(file_name).decode("utf-8", errors="replace"))
                            else:
                                print(content.decode("utf-8", errors="replace"))
                            has_output = True
            except Exception as e:
                print(f"Error fetching log artifacts: {e}")

        if not has_output:
            print("No logs or issues available.")


def cmd_artifacts(api: AppStoreConnectAPI, args):
    """List build artifacts."""
    artifacts = api.get_artifacts(args.build_id)
    if not artifacts:
        print("No artifacts found.")
        return

    print(f"Found {len(artifacts)} artifact(s):\n")
    for a in artifacts:
        attrs = a.get("attributes", {})
        action_name = a.get("_action_name", "")
        print(f"  [{action_name}] {attrs.get('fileName', 'Unknown')}")
        print(f"    Size: {attrs.get('fileSize', '?')} bytes")


def cmd_api(api: AppStoreConnectAPI, args):
    """Make a raw API request to any endpoint."""
    import json

    params = {}
    if args.params:
        for p in args.params:
            key, value = p.split("=", 1)
            params[key] = value

    json_body = None
    if args.body:
        json_body = json.loads(args.body)

    result = api.request(args.method.upper(), args.endpoint, params=params or None, json_body=json_body)
    print(json.dumps(result, indent=2))


def cmd_workflow_get(api: AppStoreConnectAPI, args):
    """Get full workflow details as JSON."""
    import json
    workflow = api.get_workflow(args.workflow_id)
    if not workflow:
        print(f"Workflow {args.workflow_id} not found.")
        return
    print(json.dumps(workflow, indent=2))


def cmd_workflow_clone(api: AppStoreConnectAPI, args):
    """Clone a workflow to another product."""
    import json

    # Get source workflow
    source = api.get_workflow(args.source_workflow)
    if not source:
        print(f"Source workflow {args.source_workflow} not found.", file=sys.stderr)
        sys.exit(1)

    source_attrs = source.get("attributes", {})

    # Get target product info
    target_product = api.get_product(args.target_product)
    if not target_product:
        print(f"Target product {args.target_product} not found.", file=sys.stderr)
        sys.exit(1)

    target_repo = api.get_product_repository(args.target_product)
    if not target_repo:
        print(f"No repository found for product {args.target_product}.", file=sys.stderr)
        sys.exit(1)

    # Get target product's existing workflow to determine scheme/container
    target_workflows = api.list_workflows(args.target_product)
    if not target_workflows:
        print(f"Target product has no existing workflows. Cannot determine scheme.", file=sys.stderr)
        print("Create an initial workflow in Xcode first.", file=sys.stderr)
        sys.exit(1)

    # Use first workflow's scheme and container as reference
    ref_workflow = target_workflows[0]
    ref_attrs = ref_workflow.get("attributes", {})
    target_scheme = ref_attrs.get("actions", [{}])[0].get("scheme", "App")
    target_container = ref_attrs.get("containerFilePath", "App.xcodeproj")

    # Adapt actions for target product
    adapted_actions = []
    for action in source_attrs.get("actions", []):
        adapted = action.copy()
        adapted["scheme"] = args.scheme if args.scheme else target_scheme
        adapted_actions.append(adapted)

    # Create the workflow
    workflow_name = args.name if args.name else source_attrs.get("name", "Cloned Workflow")
    container = args.container if args.container else target_container

    # Collect all start conditions from source
    start_conditions = {}
    for key in ["branchStartCondition", "tagStartCondition", "pullRequestStartCondition",
                "scheduledStartCondition", "manualBranchStartCondition",
                "manualTagStartCondition", "manualPullRequestStartCondition"]:
        if source_attrs.get(key):
            start_conditions[key] = source_attrs[key]

    result = api.create_workflow(
        product_id=args.target_product,
        repository_id=target_repo["id"],
        name=workflow_name,
        container_file=container,
        scheme=args.scheme if args.scheme else target_scheme,
        actions=adapted_actions,
        start_conditions=start_conditions if start_conditions else None,
        description=f"Cloned from {source.get('id', 'unknown')}",
        is_enabled=source_attrs.get("isEnabled", True),
        clean=source_attrs.get("clean", False)
    )

    new_workflow = result.get("data", {})
    print(f"✓ Created workflow '{workflow_name}' (ID: {new_workflow.get('id', 'unknown')})")
    print(f"  Product: {target_product.get('attributes', {}).get('name', 'unknown')}")
    print(f"  Scheme: {args.scheme if args.scheme else target_scheme}")
    print(f"  Container: {container}")


def cmd_workflow_delete(api: AppStoreConnectAPI, args):
    """Delete a workflow."""
    # Get workflow info first for confirmation message
    workflow = api.get_workflow(args.workflow_id)
    if not workflow:
        print(f"Workflow {args.workflow_id} not found.", file=sys.stderr)
        sys.exit(1)

    name = workflow.get("attributes", {}).get("name", "Unknown")

    if not args.force:
        print(f"Are you sure you want to delete workflow '{name}'? [y/N] ", end="")
        confirm = input().strip().lower()
        if confirm != "y":
            print("Cancelled.")
            return

    api.delete_workflow(args.workflow_id)
    print(f"✓ Deleted workflow '{name}'")


def cmd_check(api: AppStoreConnectAPI, args):
    """Check build status for current branch."""
    import zipfile
    import io

    # Get workflow ID from args or project.yml
    workflow_id = args.workflow
    if not workflow_id:
        config = get_project_config()
        workflow_id = config.get("workflow_id")
        if not workflow_id:
            print("Error: No workflow ID provided and none found in project.yml", file=sys.stderr)
            print("Use: check <workflow_id> or add XCODE_CLOUD_BRANCH_BUILD_WORKFLOW_ID to project.yml", file=sys.stderr)
            sys.exit(1)

    # Get current git branch
    if args.branch:
        branch = args.branch
    else:
        try:
            result = subprocess.run(["git", "rev-parse", "--abbrev-ref", "HEAD"],
                                    capture_output=True, text=True, check=True)
            branch = result.stdout.strip()
        except subprocess.CalledProcessError:
            print("Error: Could not determine current git branch.", file=sys.stderr)
            print("Use --branch to specify manually.", file=sys.stderr)
            sys.exit(1)

    # Get latest build for this branch
    build = api.get_latest_build_for_branch(workflow_id, branch)

    if not build:
        print(f"No builds found for branch '{branch}'")
        sys.exit(0)

    attrs = build.get("attributes", {})
    status = attrs.get("executionProgress", "unknown")
    result = attrs.get("completionStatus", "")
    number = attrs.get("number", "?")
    commit = attrs.get("sourceCommit", {})
    commit_sha = commit.get("commitSha", "")[:7] if commit.get("commitSha") else ""
    commit_msg = commit.get("message", "").split("\n")[0][:50]

    # Determine overall status
    if status == "COMPLETE":
        if result == "SUCCEEDED":
            print(f"✓ Build #{number} SUCCEEDED ({branch} @ {commit_sha})")
            print(f"  {commit_msg}")
            sys.exit(0)
        elif result == "FAILED":
            print(f"✗ Build #{number} FAILED ({branch} @ {commit_sha})")
            print(f"  {commit_msg}")
            print()
            # Fetch and display logs for failed actions
            actions = api.get_build_actions(build["id"])
            for action in actions:
                action_attrs = action.get("attributes", {})
                action_status = action_attrs.get("completionStatus", "")
                if action_status == "FAILED":
                    name = action_attrs.get("name", "Unknown")
                    print(f"{'='*60}")
                    print(f"FAILED: {name}")
                    print(f"{'='*60}")

                    # Get issues first
                    issues = api.get_action_issues(action["id"])
                    if issues:
                        for issue in issues:
                            issue_attrs = issue.get("attributes", {})
                            category = issue_attrs.get("category", "unknown")
                            message = issue_attrs.get("message", "No message")
                            file_source = issue_attrs.get("fileSource", {})
                            file_path = file_source.get("path", "")
                            line = file_source.get("lineNumber", "")
                            icon = "❌" if category == "ERROR" else "⚠️"
                            location = f" ({file_path}:{line})" if file_path else ""
                            print(f"{icon} {message}{location}")
                        print()

                    # Try log artifacts
                    try:
                        data = api.get(f"ciBuildActions/{action['id']}/artifacts", params={"limit": 200})
                        artifacts = data.get("data", [])
                        for artifact in artifacts:
                            artifact_name = artifact.get("attributes", {}).get("fileName", "")
                            if "log" in artifact_name.lower():
                                content = api.download_artifact(artifact["id"])
                                if content and artifact_name.endswith(".zip"):
                                    with zipfile.ZipFile(io.BytesIO(content)) as zf:
                                        for file_name in zf.namelist():
                                            log_content = zf.read(file_name).decode("utf-8", errors="replace")
                                            lines = log_content.strip().split("\n")

                                            # Search for error lines in the full log
                                            error_lines = []
                                            for i, line in enumerate(lines):
                                                if "error:" in line.lower() or "fatal error" in line.lower():
                                                    # Include some context before and after
                                                    start = max(0, i - 2)
                                                    end = min(len(lines), i + 5)
                                                    for j in range(start, end):
                                                        error_lines.append(lines[j])
                                                    error_lines.append("---")

                                            if error_lines:
                                                print(f"--- {file_name} (errors found) ---")
                                                # Deduplicate and show error context
                                                seen = set()
                                                for line in error_lines:
                                                    if line not in seen:
                                                        print(line)
                                                        seen.add(line)
                                            else:
                                                # No errors found, show last 100 lines
                                                if len(lines) > 100:
                                                    print(f"--- {file_name} (last 100 lines) ---")
                                                    print("\n".join(lines[-100:]))
                                                else:
                                                    print(f"--- {file_name} ---")
                                                    print(log_content)
                                            print()
                    except:
                        pass
            sys.exit(1)
        else:
            print(f"? Build #{number} {result} ({branch} @ {commit_sha})")
            sys.exit(0)
    elif status in ("RUNNING", "PENDING"):
        print(f"⟳ Build #{number} {status} ({branch} @ {commit_sha})")
        print(f"  {commit_msg}")
        sys.exit(0)
    else:
        print(f"? Build #{number} {status} ({branch} @ {commit_sha})")
        sys.exit(0)


def main():
    parser = argparse.ArgumentParser(description="Xcode Cloud build logs and status")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # products
    subparsers.add_parser("products", help="List CI products")

    # workflows
    wf_parser = subparsers.add_parser("workflows", help="List workflows for a product")
    wf_parser.add_argument("product", help="Product ID (from 'products' command)")

    # builds
    builds_parser = subparsers.add_parser("builds", help="List recent builds for a workflow")
    builds_parser.add_argument("workflow", help="Workflow ID (from 'workflows' command)")
    builds_parser.add_argument("--limit", type=int, default=1, help="Number of builds (default: 1)")

    # status
    status_parser = subparsers.add_parser("status", help="Get build status")
    status_parser.add_argument("build_id", help="Build run ID")

    # logs
    logs_parser = subparsers.add_parser("logs", help="Get build logs")
    logs_parser.add_argument("build_id", help="Build run ID")
    logs_parser.add_argument("--action", help="Filter by action name")

    # artifacts
    art_parser = subparsers.add_parser("artifacts", help="List build artifacts")
    art_parser.add_argument("build_id", help="Build run ID")

    # api - raw API request
    api_parser = subparsers.add_parser("api", help="Make raw API request to any endpoint")
    api_parser.add_argument("endpoint", help="API endpoint (e.g., 'apps', 'builds/123')")
    api_parser.add_argument("--method", "-m", default="GET", help="HTTP method (GET, POST, PATCH, DELETE)")
    api_parser.add_argument("--params", "-p", nargs="*", help="Query params as key=value")
    api_parser.add_argument("--body", "-b", help="JSON body for POST/PATCH requests")

    # workflow-get - get full workflow details
    wf_get_parser = subparsers.add_parser("workflow-get", help="Get full workflow details as JSON")
    wf_get_parser.add_argument("workflow_id", help="Workflow ID")

    # workflow-clone - clone workflow to another product
    wf_clone_parser = subparsers.add_parser("workflow-clone", help="Clone a workflow to another product")
    wf_clone_parser.add_argument("source_workflow", help="Source workflow ID to clone")
    wf_clone_parser.add_argument("target_product", help="Target product ID")
    wf_clone_parser.add_argument("--name", help="Name for the new workflow (default: same as source)")
    wf_clone_parser.add_argument("--scheme", help="Override scheme name for target")
    wf_clone_parser.add_argument("--container", help="Override container file path")

    # workflow-delete - delete a workflow
    wf_delete_parser = subparsers.add_parser("workflow-delete", help="Delete a workflow")
    wf_delete_parser.add_argument("workflow_id", help="Workflow ID")
    wf_delete_parser.add_argument("--force", "-f", action="store_true", help="Skip confirmation")

    # check - check build status for current branch
    check_parser = subparsers.add_parser("check", help="Check build status for current git branch")
    check_parser.add_argument("workflow", nargs="?", help="Workflow ID (default: from project.yml)")
    check_parser.add_argument("--branch", "-b", help="Branch name (default: current git branch)")

    args = parser.parse_args()
    api = AppStoreConnectAPI()

    commands = {
        "products": cmd_products,
        "workflows": cmd_workflows,
        "builds": cmd_builds,
        "status": cmd_status,
        "logs": cmd_logs,
        "artifacts": cmd_artifacts,
        "api": cmd_api,
        "workflow-get": cmd_workflow_get,
        "workflow-clone": cmd_workflow_clone,
        "workflow-delete": cmd_workflow_delete,
        "check": cmd_check,
    }

    commands[args.command](api, args)


if __name__ == "__main__":
    try:
        main()
    except requests.exceptions.HTTPError:
        # Error message already printed by request method
        sys.exit(1)
    except KeyboardInterrupt:
        print("\nInterrupted.", file=sys.stderr)
        sys.exit(130)
