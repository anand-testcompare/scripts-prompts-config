#!/usr/bin/env python3
"""Collect evidence-backed repository facts for README generation."""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

try:
    import tomllib  # Python 3.11+
except ModuleNotFoundError:  # pragma: no cover
    tomllib = None

IGNORED_DIRS = {
    ".git",
    ".hg",
    ".svn",
    ".venv",
    "venv",
    "node_modules",
    "dist",
    "build",
    "coverage",
    "__pycache__",
    ".pytest_cache",
    ".mypy_cache",
    ".tox",
}

DEPLOY_FILE_MAP = {
    "Docker": ["Dockerfile", "Dockerfile.*"],
    "Docker Compose": ["docker-compose.yml", "docker-compose.yaml", "compose.yaml"],
    "Kubernetes": ["k8s/*.yaml", "k8s/*.yml", "kubernetes/*.yaml", "kubernetes/*.yml"],
    "Helm": ["charts/*/Chart.yaml", "helm/*/Chart.yaml"],
    "Terraform": ["*.tf"],
    "Railway": ["railway.json", "railway.toml"],
    "Vercel": ["vercel.json"],
    "Netlify": ["netlify.toml"],
    "Render": ["render.yaml", "render.yml"],
    "Fly.io": ["fly.toml"],
    "Cloud Run": ["cloudrun.yaml", "cloudrun.yml"],
    "Serverless": ["serverless.yml", "serverless.yaml"],
}

SERVICE_PATTERNS = {
    "PostgreSQL": [r"\bpostgres(?:ql)?\b", r"\bPOSTGRES(?:QL)?_"],
    "MySQL": [r"\bmysql\b", r"\bMYSQL_"],
    "MongoDB": [r"\bmongodb\b", r"\bMONGO(?:DB)?_"],
    "Redis": [r"\bredis\b", r"\bREDIS_"],
    "RabbitMQ": [r"\brabbitmq\b", r"\bAMQP_"],
    "Kafka": [r"\bkafka\b", r"\bKAFKA_"],
    "S3": [r"\bs3\b", r"\bAWS_S3"],
    "Google Cloud Storage": [r"\bgcs\b", r"\bGOOGLE_CLOUD_STORAGE\b"],
    "Sentry": [r"\bsentry\b", r"\bSENTRY_"],
    "Datadog": [r"\bdatadog\b", r"\bDD_"],
    "OpenAI": [r"\bopenai\b", r"\bOPENAI_"],
    "Anthropic": [r"\banthropic\b", r"\bANTHROPIC_"],
    "Stripe": [r"\bstripe\b", r"\bSTRIPE_"],
    "Twilio": [r"\btwilio\b", r"\bTWILIO_"],
}

TOOL_CATALOG = {
    "fastapi": {"name": "FastAPI", "group": "framework"},
    "flask": {"name": "Flask", "group": "framework"},
    "django": {"name": "Django", "group": "framework"},
    "uvicorn": {"name": "Uvicorn", "group": "runtime"},
    "pydantic": {"name": "Pydantic", "group": "framework"},
    "sqlalchemy": {"name": "SQLAlchemy", "group": "data"},
    "pytest": {"name": "pytest", "group": "test", "layer": ["unit", "integration"]},
    "pytest-asyncio": {"name": "pytest-asyncio", "group": "test", "layer": ["unit", "integration"]},
    "pytest-cov": {"name": "pytest-cov", "group": "test", "layer": ["unit", "integration"]},
    "hurl": {"name": "Hurl", "group": "test", "layer": ["e2e_api"]},
    "newman": {"name": "Newman", "group": "test", "layer": ["e2e_api"]},
    "venom": {"name": "Venom", "group": "test", "layer": ["e2e_api"]},
    "k6": {"name": "k6", "group": "test", "layer": ["e2e_api"]},
    "playwright": {"name": "Playwright", "group": "test", "layer": ["e2e_web"]},
    "@playwright/test": {"name": "Playwright", "group": "test", "layer": ["e2e_web"]},
    "cypress": {"name": "Cypress", "group": "test", "layer": ["e2e_web"]},
    "stagehand": {"name": "Stagehand", "group": "test", "layer": ["e2e_web"]},
    "jest": {"name": "Jest", "group": "test", "layer": ["unit", "integration"]},
    "vitest": {"name": "Vitest", "group": "test", "layer": ["unit", "integration"]},
    "supertest": {"name": "Supertest", "group": "test", "layer": ["e2e_api", "integration"]},
    "coverage": {"name": "coverage.py", "group": "test", "layer": ["unit", "integration"]},
}

TEST_LAYER_ORDER = ["unit", "integration", "e2e_api", "e2e_web"]

LAYER_KEYWORDS = {
    "unit": ["pytest", "vitest", "jest", "cargo test", "go test", "npm test", "bun test", "tox"],
    "integration": ["integration", "pytest", "vitest", "jest", "go test", "cargo test"],
    "e2e_api": ["hurl", "newman", "venom", "k6", "api test"],
    "e2e_web": ["playwright", "cypress", "stagehand", "selenium"],
}

API_ROUTE_PATTERNS = [
    re.compile(r"@(app|router)\.(get|post|put|delete|patch|options|head)\("),
    re.compile(r"\b(app|router)\.(get|post|put|delete|patch|options|head)\("),
]

REQ_PATTERN = re.compile(r"^([A-Za-z0-9_.-]+)(?:\[[^\]]+\])?\s*(.*)$")
VER_NUM_PATTERN = re.compile(r"\d+(?:\.\d+){0,3}")


@dataclass
class PackageVersion:
    name: str
    version: str
    source: str
    precision: str

    def to_dict(self) -> dict[str, str]:
        return {
            "name": self.name,
            "version": self.version,
            "source": self.source,
            "precision": self.precision,
        }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Collect README facts from a repository")
    parser.add_argument("--repo", default=".", help="Path to repository")
    parser.add_argument("--format", choices=["json", "markdown"], default="json")
    parser.add_argument("--max-files", type=int, default=5000, help="Max files to inspect")
    return parser.parse_args()


def walk_files(repo: Path, max_files: int) -> list[Path]:
    files: list[Path] = []
    for root, dirnames, filenames in os.walk(repo):
        dirnames[:] = [d for d in dirnames if d not in IGNORED_DIRS and not d.startswith(".")]
        for name in filenames:
            path = Path(root) / name
            files.append(path)
            if len(files) >= max_files:
                return files
    return files


def relpath(path: Path, repo: Path) -> str:
    return path.relative_to(repo).as_posix()


def read_text(path: Path, limit: int = 512_000) -> str:
    try:
        raw = path.read_bytes()
    except OSError:
        return ""
    if len(raw) > limit:
        raw = raw[:limit]
    return raw.decode("utf-8", errors="ignore")


def parse_precision(version: str) -> str:
    trimmed = version.strip()
    if not trimmed:
        return "unknown"
    if re.fullmatch(r"v?\d+(?:\.\d+){0,3}", trimmed):
        return "exact"
    if trimmed.startswith(("^", "~", ">", "<", "=", "!")) or "," in trimmed:
        return "range"
    if "*" in trimmed or "x" in trimmed.lower():
        return "range"
    return "other"


def normalize_package_name(name: str) -> str:
    return name.strip().lower().replace("_", "-")


def parse_requirement_line(raw: str) -> tuple[str, str] | None:
    line = raw.strip()
    if not line or line.startswith("#"):
        return None
    line = line.split("#", 1)[0].strip()
    if not line:
        return None
    if line.startswith(("-r", "--", "git+", "http://", "https://")):
        return None
    match = REQ_PATTERN.match(line)
    if not match:
        return None
    name, spec = match.groups()
    return normalize_package_name(name), spec.strip() or "unknown"


def load_toml(path: Path) -> dict:
    if tomllib is None or not path.exists():
        return {}
    try:
        with path.open("rb") as handle:
            data = tomllib.load(handle)
    except Exception:
        return {}
    return data if isinstance(data, dict) else {}


def collect_versions(repo: Path) -> dict[str, PackageVersion]:
    versions: dict[str, PackageVersion] = {}

    uv_lock = load_toml(repo / "uv.lock")
    for item in uv_lock.get("package", []) if isinstance(uv_lock.get("package"), list) else []:
        if not isinstance(item, dict):
            continue
        name = normalize_package_name(str(item.get("name", "")))
        version = str(item.get("version", "")).strip()
        if name and version:
            versions[name] = PackageVersion(name=name, version=version, source="uv.lock", precision="exact")

    pyproject = load_toml(repo / "pyproject.toml")
    project = pyproject.get("project", {}) if isinstance(pyproject.get("project"), dict) else {}
    deps = project.get("dependencies", []) if isinstance(project.get("dependencies"), list) else []
    optional = (
        project.get("optional-dependencies", {})
        if isinstance(project.get("optional-dependencies"), dict)
        else {}
    )

    dep_specs = list(deps)
    for group_deps in optional.values():
        if isinstance(group_deps, list):
            dep_specs.extend(group_deps)

    for dep in dep_specs:
        if not isinstance(dep, str):
            continue
        parsed = parse_requirement_line(dep)
        if not parsed:
            continue
        name, version = parsed
        if name in versions:
            continue
        versions[name] = PackageVersion(
            name=name,
            version=version,
            source="pyproject.toml",
            precision=parse_precision(version),
        )

    req_files = ["requirements.txt", "requirements-dev.txt", "dev-requirements.txt"]
    for req in req_files:
        path = repo / req
        if not path.exists():
            continue
        for raw in read_text(path).splitlines():
            parsed = parse_requirement_line(raw)
            if not parsed:
                continue
            name, version = parsed
            if name in versions:
                continue
            versions[name] = PackageVersion(
                name=name,
                version=version,
                source=req,
                precision=parse_precision(version),
            )

    package_json = repo / "package.json"
    if package_json.exists():
        try:
            package_data = json.loads(package_json.read_text())
        except Exception:
            package_data = {}
        for section in ["dependencies", "devDependencies", "peerDependencies", "optionalDependencies"]:
            block = package_data.get(section, {})
            if not isinstance(block, dict):
                continue
            for raw_name, raw_version in block.items():
                name = normalize_package_name(str(raw_name))
                version = str(raw_version)
                if not name or name in versions:
                    continue
                versions[name] = PackageVersion(
                    name=name,
                    version=version,
                    source=f"package.json:{section}",
                    precision=parse_precision(version),
                )

    go_mod = repo / "go.mod"
    if go_mod.exists():
        for line in read_text(go_mod).splitlines():
            line = line.strip()
            if not line or line.startswith("//"):
                continue
            if " " not in line:
                continue
            if line.startswith(("require", "replace", "module", "go", ")", "(")):
                continue
            parts = line.split()
            if len(parts) < 2:
                continue
            mod_name = parts[0].split("/")[-1]
            version = parts[1]
            name = normalize_package_name(mod_name)
            if name and name not in versions:
                versions[name] = PackageVersion(
                    name=name,
                    version=version,
                    source="go.mod",
                    precision=parse_precision(version),
                )

    cargo_toml = load_toml(repo / "Cargo.toml")
    for section in ["dependencies", "dev-dependencies"]:
        block = cargo_toml.get(section, {}) if isinstance(cargo_toml.get(section), dict) else {}
        for raw_name, raw_value in block.items():
            name = normalize_package_name(str(raw_name))
            if not name or name in versions:
                continue
            if isinstance(raw_value, str):
                version = raw_value
            elif isinstance(raw_value, dict):
                version = str(raw_value.get("version", "unknown"))
            else:
                version = "unknown"
            versions[name] = PackageVersion(
                name=name,
                version=version,
                source=f"Cargo.toml:{section}",
                precision=parse_precision(version),
            )

    return versions


def detect_runtime(repo: Path, versions: dict[str, PackageVersion]) -> list[dict[str, str]]:
    runtime: list[dict[str, str]] = []
    pyproject = load_toml(repo / "pyproject.toml")
    project = pyproject.get("project", {}) if isinstance(pyproject.get("project"), dict) else {}
    requires_python = project.get("requires-python")
    if isinstance(requires_python, str) and requires_python.strip():
        runtime.append(
            {
                "name": "Python",
                "version": requires_python.strip(),
                "source": "pyproject.toml:project.requires-python",
                "precision": parse_precision(requires_python),
            }
        )

    package_json = repo / "package.json"
    if package_json.exists():
        try:
            package_data = json.loads(package_json.read_text())
        except Exception:
            package_data = {}
        engines = package_data.get("engines", {}) if isinstance(package_data.get("engines"), dict) else {}
        node_version = engines.get("node")
        if isinstance(node_version, str) and node_version.strip():
            runtime.append(
                {
                    "name": "Node.js",
                    "version": node_version.strip(),
                    "source": "package.json:engines.node",
                    "precision": parse_precision(node_version),
                }
            )

    go_mod = repo / "go.mod"
    if go_mod.exists():
        for line in read_text(go_mod).splitlines():
            line = line.strip()
            if line.startswith("go "):
                version = line.split(" ", 1)[1].strip()
                runtime.append(
                    {
                        "name": "Go",
                        "version": version,
                        "source": "go.mod",
                        "precision": parse_precision(version),
                    }
                )
                break

    cargo_toml = load_toml(repo / "Cargo.toml")
    package = cargo_toml.get("package", {}) if isinstance(cargo_toml.get("package"), dict) else {}
    rust_version = package.get("rust-version")
    if isinstance(rust_version, str) and rust_version.strip():
        runtime.append(
            {
                "name": "Rust",
                "version": rust_version,
                "source": "Cargo.toml:package.rust-version",
                "precision": parse_precision(rust_version),
            }
        )

    if not runtime and any((repo / marker).exists() for marker in ["pyproject.toml", "requirements.txt"]):
        runtime.append({"name": "Python", "version": "unknown", "source": "inferred", "precision": "unknown"})

    for pkg_name in ["bun", "deno"]:
        pkg = versions.get(pkg_name)
        if pkg:
            runtime.append(
                {
                    "name": pkg_name.capitalize(),
                    "version": pkg.version,
                    "source": pkg.source,
                    "precision": pkg.precision,
                }
            )

    return runtime


def select_tools(versions: dict[str, PackageVersion]) -> list[dict[str, str]]:
    tools: list[dict[str, str]] = []
    seen: set[str] = set()
    for pkg, meta in TOOL_CATALOG.items():
        package_version = versions.get(pkg)
        if not package_version:
            continue
        key = meta["name"]
        if key in seen:
            continue
        tools.append(
            {
                "name": meta["name"],
                "package": pkg,
                "version": package_version.version,
                "source": package_version.source,
                "precision": package_version.precision,
                "group": meta["group"],
            }
        )
        seen.add(key)
    return tools


def augment_tools_from_files(repo: Path, files: list[Path], tools: list[dict[str, str]]) -> list[dict[str, str]]:
    rel_files = [relpath(path, repo).lower() for path in files]
    seen_names = {tool["name"] for tool in tools}
    additions: list[dict[str, str]] = []

    def add_if_missing(name: str, package: str, source_hint: str) -> None:
        if name in seen_names:
            return
        additions.append(
            {
                "name": name,
                "package": package,
                "version": "unknown",
                "source": source_hint,
                "precision": "unknown",
                "group": "test",
            }
        )
        seen_names.add(name)

    if any(rel.endswith(".hurl") for rel in rel_files):
        add_if_missing("Hurl", "hurl", "tests/**/*.hurl")
    if any("playwright.config" in rel or "/playwright/" in rel for rel in rel_files):
        add_if_missing("Playwright", "playwright", "playwright config/files")
    if any("cypress.config" in rel or "/cypress/" in rel for rel in rel_files):
        add_if_missing("Cypress", "cypress", "cypress config/files")
    if any(rel.endswith("pytest.ini") or rel.endswith("conftest.py") for rel in rel_files):
        add_if_missing("pytest", "pytest", "pytest config/files")
    if any("vitest.config" in rel for rel in rel_files):
        add_if_missing("Vitest", "vitest", "vitest config")
    if any("jest.config" in rel for rel in rel_files):
        add_if_missing("Jest", "jest", "jest config")

    return tools + additions


def detect_ci(repo: Path) -> tuple[list[dict[str, str]], str]:
    ci_entries: list[dict[str, str]] = []
    snippets: list[str] = []

    workflow_dir = repo / ".github/workflows"
    if workflow_dir.exists():
        files = sorted(list(workflow_dir.glob("*.yml")) + list(workflow_dir.glob("*.yaml")))
        if files:
            ci_entries.append(
                {
                    "provider": "GitHub Actions",
                    "files": ", ".join(relpath(path, repo) for path in files),
                }
            )
            snippets.extend(read_text(path).lower() for path in files)

    if (repo / ".gitlab-ci.yml").exists():
        ci_entries.append({"provider": "GitLab CI", "files": ".gitlab-ci.yml"})
        snippets.append(read_text(repo / ".gitlab-ci.yml").lower())

    circleci = repo / ".circleci/config.yml"
    if circleci.exists():
        ci_entries.append({"provider": "CircleCI", "files": ".circleci/config.yml"})
        snippets.append(read_text(circleci).lower())

    azure = repo / "azure-pipelines.yml"
    if azure.exists():
        ci_entries.append({"provider": "Azure Pipelines", "files": "azure-pipelines.yml"})
        snippets.append(read_text(azure).lower())

    bitbucket = repo / "bitbucket-pipelines.yml"
    if bitbucket.exists():
        ci_entries.append({"provider": "Bitbucket Pipelines", "files": "bitbucket-pipelines.yml"})
        snippets.append(read_text(bitbucket).lower())

    return ci_entries, "\n".join(snippets)


def detect_deploy(repo: Path) -> list[dict[str, str]]:
    detected: list[dict[str, str]] = []
    seen: set[str] = set()
    for system, patterns in DEPLOY_FILE_MAP.items():
        matched: list[str] = []
        for pattern in patterns:
            matched.extend(relpath(path, repo) for path in repo.glob(pattern))
        if matched and system not in seen:
            detected.append({"name": system, "evidence": ", ".join(sorted(set(matched)))})
            seen.add(system)
    return detected


def detect_external_services(repo: Path, files: Iterable[Path]) -> list[dict[str, str]]:
    file_candidates: list[Path] = []
    for path in files:
        rel = relpath(path, repo)
        name = path.name.lower()
        if name.startswith(".env") or name.endswith((".yml", ".yaml", ".toml", ".json", ".ini", ".cfg")):
            file_candidates.append(path)
            continue
        if "/config" in rel or rel.startswith("config"):
            file_candidates.append(path)
            continue
        if rel.startswith("app/") or rel.startswith("src/"):
            if path.suffix.lower() in {".py", ".js", ".ts", ".tsx", ".go", ".rs"}:
                file_candidates.append(path)

    observed: dict[str, str] = {}
    for path in file_candidates[:400]:
        text = read_text(path).lower()
        if not text:
            continue
        rel = relpath(path, repo)
        for service, patterns in SERVICE_PATTERNS.items():
            if service in observed:
                continue
            for pattern in patterns:
                if re.search(pattern, text):
                    observed[service] = rel
                    break

    return [{"name": name, "evidence": evidence} for name, evidence in sorted(observed.items())]


def detect_tests(repo: Path, files: list[Path], tools: list[dict[str, str]], ci_text: str) -> dict[str, dict[str, object]]:
    rel_files = [relpath(path, repo).lower() for path in files]
    lower_ci = ci_text.lower()

    def any_path(patterns: Iterable[str]) -> bool:
        return any(any(token in rel for token in patterns) for rel in rel_files)

    def add_evidence(layer: str, evidence: str) -> None:
        if evidence not in layer_data[layer]["evidence"]:
            layer_data[layer]["evidence"].append(evidence)

    def add_tool(layer: str, tool_name: str) -> None:
        if tool_name not in layer_data[layer]["tools"]:
            layer_data[layer]["tools"].append(tool_name)

    has_any_tests = any(
        rel.startswith("tests/")
        or "/tests/" in rel
        or rel.endswith("_test.py")
        or rel.endswith(".spec.ts")
        or rel.endswith(".spec.js")
        or rel.endswith(".test.ts")
        or rel.endswith(".test.js")
        for rel in rel_files
    )

    layer_data: dict[str, dict[str, object]] = {
        "unit": {"present": False, "tools": [], "evidence": [], "ci": False},
        "integration": {"present": False, "tools": [], "evidence": [], "ci": False},
        "e2e_api": {"present": False, "tools": [], "evidence": [], "ci": False},
        "e2e_web": {"present": False, "tools": [], "evidence": [], "ci": False},
    }

    has_integration_paths = any_path(["tests/integration", "/integration/", "integration_test", "/itest"])
    has_e2e_api_paths = any_path(["tests/api", "api-test", "/hurl/", "/newman/", "/venom/", "/k6/"])
    has_e2e_web_paths = any_path(["tests/e2e", "/playwright/", "/cypress/", "/stagehand/", "/selenium/"])

    has_unit_paths = any(
        (
            rel.startswith("tests/unit")
            or "/tests/unit/" in rel
            or rel.endswith("_test.py")
            or rel.endswith(".spec.ts")
            or rel.endswith(".spec.js")
            or rel.endswith(".test.ts")
            or rel.endswith(".test.js")
        )
        and "integration" not in rel
        and "e2e" not in rel
        and "/api/" not in rel
        and "/hurl/" not in rel
        for rel in rel_files
    )

    if has_unit_paths or (has_any_tests and not (has_integration_paths or has_e2e_api_paths or has_e2e_web_paths)):
        layer_data["unit"]["present"] = True
        add_evidence("unit", "unit test paths")

    if has_integration_paths:
        layer_data["integration"]["present"] = True
        add_evidence("integration", "integration test paths")

    if has_e2e_api_paths:
        layer_data["e2e_api"]["present"] = True
        add_evidence("e2e_api", "api e2e test paths")

    if has_e2e_web_paths:
        layer_data["e2e_web"]["present"] = True
        add_evidence("e2e_web", "web e2e test paths")

    if any(rel.endswith(".hurl") for rel in rel_files):
        layer_data["e2e_api"]["present"] = True
        add_evidence("e2e_api", "hurl files")
        add_tool("e2e_api", "Hurl")

    if any("playwright.config" in rel for rel in rel_files):
        layer_data["e2e_web"]["present"] = True
        add_evidence("e2e_web", "playwright config")
        add_tool("e2e_web", "Playwright")

    if any("cypress.config" in rel for rel in rel_files):
        layer_data["e2e_web"]["present"] = True
        add_evidence("e2e_web", "cypress config")
        add_tool("e2e_web", "Cypress")

    if any(rel.endswith("pytest.ini") or rel.endswith("conftest.py") for rel in rel_files):
        if not layer_data["unit"]["present"]:
            layer_data["unit"]["present"] = True
            add_evidence("unit", "pytest config")
        add_tool("unit", "pytest")

    for tool in tools:
        if tool.get("group") != "test":
            continue
        layer_hints = TOOL_CATALOG.get(tool.get("package", ""), {}).get("layer", [])
        for layer in layer_hints:
            if layer not in layer_data:
                continue
            tool_key = tool["name"].lower()
            has_ci_signal = tool_key in lower_ci
            if layer_data[layer]["present"] or has_ci_signal:
                add_tool(layer, tool["name"])
            if has_ci_signal and not layer_data[layer]["present"]:
                layer_data[layer]["present"] = True
                add_evidence(layer, f"ci mentions {tool['name'].lower()}")

    for layer in TEST_LAYER_ORDER:
        keywords = LAYER_KEYWORDS[layer]
        layer_data[layer]["ci"] = bool(lower_ci and any(keyword in lower_ci for keyword in keywords))
        layer_data[layer]["tools"] = sorted(set(layer_data[layer]["tools"]))

    return layer_data


def detect_api_surface(repo: Path, files: list[Path]) -> dict[str, object]:
    endpoint_count = 0
    evidence: dict[str, int] = defaultdict(int)

    for path in files:
        if path.suffix.lower() not in {".py", ".js", ".ts", ".tsx", ".go", ".rs"}:
            continue
        text = read_text(path)
        if not text:
            continue
        local_count = 0
        for pattern in API_ROUTE_PATTERNS:
            local_count += len(pattern.findall(text))
        if local_count:
            endpoint_count += local_count
            evidence[relpath(path, repo)] += local_count

    top_evidence = sorted(evidence.items(), key=lambda item: item[1], reverse=True)[:5]
    return {
        "exposed": endpoint_count > 0,
        "estimated_endpoint_decorators": endpoint_count,
        "evidence": [f"{path} ({count})" for path, count in top_evidence],
    }


def gather_facts(repo: Path, files: list[Path]) -> dict[str, object]:
    versions = collect_versions(repo)
    runtime = detect_runtime(repo, versions)
    tools = select_tools(versions)
    tools = augment_tools_from_files(repo, files, tools)
    ci, ci_text = detect_ci(repo)
    deployment = detect_deploy(repo)
    services = detect_external_services(repo, files)
    tests = detect_tests(repo, files, tools, ci_text)
    api = detect_api_surface(repo, files)

    gaps: list[str] = []
    for layer in TEST_LAYER_ORDER:
        if not tests[layer]["present"]:
            gaps.append(f"missing_{layer}_tests")
        elif not tests[layer]["ci"]:
            gaps.append(f"{layer}_tests_not_seen_in_ci")

    if api["exposed"] and not tests["e2e_api"]["present"]:
        gaps.append("api_surface_detected_without_e2e_api_tests")

    if not ci:
        gaps.append("no_ci_config_detected")

    return {
        "repo": str(repo),
        "runtime": runtime,
        "tools": tools,
        "ci": ci,
        "deployment": deployment,
        "external_services": services,
        "testing": tests,
        "api_surface": api,
        "gaps": gaps,
        "counts": {
            "files_scanned": len(files),
            "tools_detected": len(tools),
            "deploy_targets_detected": len(deployment),
            "external_services_detected": len(services),
        },
    }


def _fmt_version(item: dict[str, str]) -> str:
    version = item.get("version", "unknown")
    source = item.get("source", "unknown")
    precision = item.get("precision", "unknown")
    return f"{version} ({precision}; {source})"


def to_markdown(data: dict[str, object]) -> str:
    lines: list[str] = []
    lines.append("# README Fact Snapshot")
    lines.append("")

    lines.append("## Runtime")
    runtime = data.get("runtime", [])
    if runtime:
        for entry in runtime:
            lines.append(f"- {entry['name']}: {_fmt_version(entry)}")
    else:
        lines.append("- none detected")
    lines.append("")

    lines.append("## Tools")
    tools = data.get("tools", [])
    if tools:
        for tool in tools:
            lines.append(f"- {tool['name']}: {_fmt_version(tool)}")
    else:
        lines.append("- none detected")
    lines.append("")

    lines.append("## Testing Matrix")
    lines.append("| Layer | Present | Tooling | In CI |")
    lines.append("|---|---|---|---|")
    testing = data.get("testing", {})
    for layer in TEST_LAYER_ORDER:
        details = testing.get(layer, {})
        present = "yes" if details.get("present") else "no"
        tooling = ", ".join(details.get("tools", [])) or "none"
        in_ci = "yes" if details.get("ci") else "no"
        lines.append(f"| {layer} | {present} | {tooling} | {in_ci} |")
    lines.append("")

    lines.append("## CI Providers")
    ci = data.get("ci", [])
    if ci:
        for entry in ci:
            lines.append(f"- {entry['provider']}: {entry['files']}")
    else:
        lines.append("- none detected")
    lines.append("")

    lines.append("## Deployment")
    deployment = data.get("deployment", [])
    if deployment:
        for item in deployment:
            lines.append(f"- {item['name']}: {item['evidence']}")
    else:
        lines.append("- none detected")
    lines.append("")

    lines.append("## External Services")
    external = data.get("external_services", [])
    if external:
        for item in external:
            lines.append(f"- {item['name']}: {item['evidence']}")
    else:
        lines.append("- none detected")
    lines.append("")

    lines.append("## API Surface")
    api = data.get("api_surface", {})
    exposed = "yes" if api.get("exposed") else "no"
    lines.append(f"- Exposed: {exposed}")
    lines.append(f"- Estimated route decorators: {api.get('estimated_endpoint_decorators', 0)}")
    evidence = api.get("evidence", [])
    if evidence:
        lines.append(f"- Evidence: {', '.join(evidence)}")
    lines.append("")

    lines.append("## Gaps")
    gaps = data.get("gaps", [])
    if gaps:
        for gap in gaps:
            lines.append(f"- {gap}")
    else:
        lines.append("- none")

    return "\n".join(lines) + "\n"


def main() -> int:
    args = parse_args()
    repo = Path(args.repo).expanduser().resolve()
    if not repo.exists() or not repo.is_dir():
        print(f"error: repo not found: {repo}", file=sys.stderr)
        return 1

    files = walk_files(repo, args.max_files)
    facts = gather_facts(repo, files)

    if args.format == "json":
        print(json.dumps(facts, indent=2, sort_keys=True))
    else:
        print(to_markdown(facts), end="")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
