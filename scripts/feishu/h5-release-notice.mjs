#!/usr/bin/env node
import { spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, "../..");
const h5Dir = process.env.H5_RELEASE_NOTICE_H5_DIR || path.join(rootDir, "hybird-meumall");
const generatedDir = path.join(rootDir, ".ai-workspace/release-notices/generated");
const exampleConfigPath = path.join(
  rootDir,
  ".ai-workspace/feishu/h5-release-notification.config.example.json",
);
const localConfigPath = path.join(
  rootDir,
  ".ai-workspace/feishu/h5-release-notification.local.json",
);

const cliTokens = process.argv.slice(2);
if (cliTokens[0] === "--") cliTokens.shift();
const command = cliTokens[0] || "help";
const args = parseArgs(cliTokens.slice(1));

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});

async function main() {
  if (command === "help" || args.help) {
    printHelp();
    return;
  }

  const config = loadConfig();
  const context = await collectContext(config);
  mkdirSync(generatedDir, { recursive: true });

  if (command === "overview-preview") {
    const reviewMessage = renderOverviewReviewMessage(context, config);
    const previewPath = writeGenerated(overviewStateKey(context), "review.md", reviewMessage);
    console.log(reviewMessage);
    console.log(`\n已生成总览预览：${previewPath}`);
    return;
  }

  if (command === "request-overview-review") {
    ensureReviewTarget(config);
    const reviewMessage = renderOverviewReviewMessage(context, config);
    const stateKey = overviewStateKey(context);
    const messageResult = sendFeishuMessage({
      config,
      markdown: reviewMessage,
      target: resolveReviewTarget(config),
      idempotencyKey: idempotencyKey("overview-review", stateKey, reviewMessage),
      dryRun: Boolean(args["dry-run"]),
    });
    const state = loadState(stateKey);
    const nextState = {
      ...state,
      version: context.version,
      stateKey,
      kind: "overview",
      status: args["dry-run"] ? "review_dry_run" : "review_requested",
      reviewRequestedAt: new Date().toISOString(),
      reviewTarget: resolveReviewTarget(config),
      reviewMessagePath: writeGenerated(stateKey, "review.md", reviewMessage),
      reviewSendResult: messageResult,
      approved: false,
      officialSent: false,
    };
    writeState(stateKey, nextState);
    console.log(args["dry-run"] ? "总览审核消息 dry-run 已完成。" : "总览审核消息已发送。");
    printStatePath(stateKey);
    return;
  }

  if (command === "check-overview-approval") {
    const stateKey = overviewStateKey(context);
    const state = loadState(stateKey);
    const approval = checkApprovalFromFeishu({
      config,
      context,
      approvalPhrases: buildOverviewApprovalPhrases(config),
    });
    if (!approval.approved) {
      console.log("未检测到项目总览的审核确认。");
      console.log("请在审核群回复：同意 总览");
      return;
    }
    const nextState = {
      ...state,
      version: context.version,
      stateKey,
      kind: "overview",
      status: "approved",
      approved: true,
      approvedAt: new Date().toISOString(),
      approvedBy: approval.approvedBy,
      approvalEvidence: approval.evidence,
    };
    writeState(stateKey, nextState);
    console.log(`已检测到总览审核确认：${approval.evidence}`);
    printStatePath(stateKey);
    return;
  }

  if (command === "mark-overview-approved") {
    const approvedBy = String(args["approved-by"] || "").trim();
    const approvalNote = String(args["approval-note"] || "").trim();
    if (!approvedBy || !approvalNote) {
      throw new Error(
        "mark-overview-approved 必须提供 --approved-by 和 --approval-note，例如：--approved-by 唐游超 --approval-note 飞书审核群已确认",
      );
    }
    const stateKey = overviewStateKey(context);
    const state = loadState(stateKey);
    const nextState = {
      ...state,
      version: context.version,
      stateKey,
      kind: "overview",
      status: "approved",
      approved: true,
      approvedAt: new Date().toISOString(),
      approvedBy,
      approvalEvidence: approvalNote,
      approvalMode: "manual",
    };
    writeState(stateKey, nextState);
    console.log("项目总览已标记为审核通过。");
    printStatePath(stateKey);
    return;
  }

  if (command === "send-overview-approved") {
    ensureTargetChat(config);
    const stateKey = overviewStateKey(context);
    const state = loadState(stateKey);
    if (!state.approved) {
      throw new Error(
        "项目总览尚未审核通过，不能发送正式群。请先执行 check-overview-approval 或 mark-overview-approved。",
      );
    }
    const officialMessage = renderOverviewOfficialMessage(context, config, state);
    const messageResult = sendFeishuMessage({
      config,
      markdown: officialMessage,
      target: { type: "chat", id: config.targetChatId },
      idempotencyKey: idempotencyKey("overview-official", stateKey, officialMessage),
      dryRun: Boolean(args["dry-run"]),
    });
    const nextState = {
      ...state,
      version: context.version,
      stateKey,
      kind: "overview",
      status: args["dry-run"] ? "official_dry_run" : "official_sent",
      officialSent: !args["dry-run"],
      officialSentAt: args["dry-run"] ? undefined : new Date().toISOString(),
      officialMessagePath: writeGenerated(stateKey, "official.md", officialMessage),
      officialSendResult: messageResult,
    };
    writeState(stateKey, nextState);
    console.log(args["dry-run"] ? "总览正式群消息 dry-run 已完成。" : "总览正式群消息已发送。");
    printStatePath(stateKey);
    return;
  }

  if (command === "preview") {
    const reviewMessage = renderReviewMessage(context, config);
    const previewPath = writeGenerated(context.version, "review.md", reviewMessage);
    console.log(reviewMessage);
    console.log(`\n已生成预览：${previewPath}`);
    return;
  }

  if (command === "request-review") {
    ensureReviewTarget(config);
    const reviewMessage = renderReviewMessage(context, config);
    const messageResult = sendFeishuMessage({
      config,
      markdown: reviewMessage,
      target: resolveReviewTarget(config),
      idempotencyKey: idempotencyKey("review", context.version, reviewMessage),
      dryRun: Boolean(args["dry-run"]),
    });
    const state = loadState(context.version);
    const nextState = {
      ...state,
      version: context.version,
      status: args["dry-run"] ? "review_dry_run" : "review_requested",
      reviewRequestedAt: new Date().toISOString(),
      reviewTarget: resolveReviewTarget(config),
      reviewMessagePath: writeGenerated(context.version, "review.md", reviewMessage),
      reviewSendResult: messageResult,
      approved: false,
      officialSent: false,
    };
    writeState(context.version, nextState);
    console.log(args["dry-run"] ? "审核消息 dry-run 已完成。" : "审核消息已发送。");
    printStatePath(context.version);
    return;
  }

  if (command === "check-approval") {
    const state = loadState(context.version);
    const approval = checkApprovalFromFeishu({ config, context, state });
    if (!approval.approved) {
      console.log(`未检测到 ${context.version} 的审核确认。`);
      console.log(`请在审核群回复：同意 ${context.version}`);
      return;
    }
    const nextState = {
      ...state,
      version: context.version,
      status: "approved",
      approved: true,
      approvedAt: new Date().toISOString(),
      approvedBy: approval.approvedBy,
      approvalEvidence: approval.evidence,
    };
    writeState(context.version, nextState);
    console.log(`已检测到审核确认：${approval.evidence}`);
    printStatePath(context.version);
    return;
  }

  if (command === "mark-approved") {
    const approvedBy = String(args["approved-by"] || "").trim();
    const approvalNote = String(args["approval-note"] || "").trim();
    if (!approvedBy || !approvalNote) {
      throw new Error(
        "mark-approved 必须提供 --approved-by 和 --approval-note，例如：--approved-by 张三 --approval-note 飞书审核群已确认",
      );
    }
    const state = loadState(context.version);
    const nextState = {
      ...state,
      version: context.version,
      status: "approved",
      approved: true,
      approvedAt: new Date().toISOString(),
      approvedBy,
      approvalEvidence: approvalNote,
      approvalMode: "manual",
    };
    writeState(context.version, nextState);
    console.log(`${context.version} 已标记为审核通过。`);
    printStatePath(context.version);
    return;
  }

  if (command === "send-approved") {
    ensureTargetChat(config);
    const state = loadState(context.version);
    if (!state.approved) {
      throw new Error(
        `${context.version} 尚未审核通过，不能发送正式群。请先执行 check-approval 或 mark-approved。`,
      );
    }
    const officialMessage = renderOfficialMessage(context, config, state);
    const messageResult = sendFeishuMessage({
      config,
      markdown: officialMessage,
      target: { type: "chat", id: config.targetChatId },
      idempotencyKey: idempotencyKey("official", context.version, officialMessage),
      dryRun: Boolean(args["dry-run"]),
    });
    const nextState = {
      ...state,
      version: context.version,
      status: args["dry-run"] ? "official_dry_run" : "official_sent",
      officialSent: !args["dry-run"],
      officialSentAt: args["dry-run"] ? undefined : new Date().toISOString(),
      officialMessagePath: writeGenerated(context.version, "official.md", officialMessage),
      officialSendResult: messageResult,
    };
    writeState(context.version, nextState);
    console.log(args["dry-run"] ? "正式群消息 dry-run 已完成。" : "正式群消息已发送。");
    printStatePath(context.version);
    return;
  }

  throw new Error(`未知命令：${command}。执行 pnpm run feishu:h5-release-notice -- help 查看用法。`);
}

function parseArgs(argv) {
  const parsed = {};
  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    if (!token.startsWith("--")) continue;
    const key = token.slice(2);
    const next = argv[index + 1];
    if (!next || next.startsWith("--")) {
      parsed[key] = true;
    } else {
      parsed[key] = next;
      index += 1;
    }
  }
  return parsed;
}

function printHelp() {
  console.log(`
MeuMall H5 飞书发版通报

用法：
  # 首次项目总览通报
  pnpm run feishu:h5-release-notice -- overview-preview
  pnpm run feishu:h5-release-notice -- request-overview-review [--dry-run]
  pnpm run feishu:h5-release-notice -- check-overview-approval
  pnpm run feishu:h5-release-notice -- mark-overview-approved --approved-by <name> --approval-note <text>
  pnpm run feishu:h5-release-notice -- send-overview-approved [--dry-run]

  # 后续单版本增量通报
  pnpm run feishu:h5-release-notice -- preview
  pnpm run feishu:h5-release-notice -- request-review [--dry-run]
  pnpm run feishu:h5-release-notice -- check-approval
  pnpm run feishu:h5-release-notice -- mark-approved --approved-by <name> --approval-note <text>
  pnpm run feishu:h5-release-notice -- send-approved [--dry-run]

本地配置：
  cp .ai-workspace/feishu/h5-release-notification.config.example.json \\
    .ai-workspace/feishu/h5-release-notification.local.json

必填配置：
  reviewChatId 或 reviewUserId：审核消息接收方
  targetChatId：正式对接群
`);
}

function loadConfig() {
  const example = readJson(exampleConfigPath, {});
  const local = existsSync(localConfigPath) ? readJson(localConfigPath, {}) : {};
  const releaseEnvironment =
    args.environment ||
    process.env.H5_RELEASE_ENV ||
    local.releaseEnvironment ||
    example.releaseEnvironment ||
    "test";
  return {
    ...example,
    ...local,
    releaseEnvironment,
    javaReleaseApiBaseUrl:
      process.env.JAVA_H5_RELEASE_API_BASE_URL ||
      local.javaReleaseApiBaseUrl ||
      example.javaReleaseApiBaseUrl ||
      "",
    javaReleaseRegisterApiBaseUrl:
      process.env.JAVA_H5_RELEASE_REGISTER_API_BASE_URL ||
      local.javaReleaseRegisterApiBaseUrl ||
      example.javaReleaseRegisterApiBaseUrl ||
      process.env.JAVA_H5_RELEASE_API_BASE_URL ||
      local.javaReleaseApiBaseUrl ||
      example.javaReleaseApiBaseUrl ||
      "",
    javaReleaseToken:
      process.env.JAVA_H5_RELEASE_TOKEN ||
      local.javaReleaseToken ||
      example.javaReleaseToken ||
      "",
    javaReleaseRegisterToken:
      process.env.JAVA_H5_RELEASE_REGISTER_TOKEN ||
      local.javaReleaseRegisterToken ||
      example.javaReleaseRegisterToken ||
      process.env.JAVA_H5_RELEASE_TOKEN ||
      local.javaReleaseToken ||
      example.javaReleaseToken ||
      "",
    approvalKeywords: local.approvalKeywords || example.approvalKeywords || ["同意", "确认", "approve"],
    approvalReadAs: local.approvalReadAs || example.approvalReadAs || local.sendAs || example.sendAs || "bot",
    sendAs: local.sendAs || example.sendAs || "bot",
    profile: local.profile || example.profile || "",
    senderDisplayName: local.senderDisplayName || example.senderDisplayName || "飞书机器人",
    reviewMode: local.reviewMode || example.reviewMode || "review_chat",
  };
}

async function collectContext(config) {
  const packageJson = readJson(path.join(h5Dir, "package.json"));
  const packageVersion = packageJson.version;
  if (!packageVersion) throw new Error("hybird-meumall/package.json 缺少 version。");

  const version = args.version || `v${packageVersion}`;
  const gitTag = args["git-tag"] || `h5/${version}`;
  const releaseDir = path.join(h5Dir, "archives/releases", version);
  const releaseRegistration = readJsonIfExists(path.join(releaseDir, "release-registration.json"));
  const releaseResponse = readJsonIfExists(path.join(releaseDir, "release-registration-response.json"));
  const promoteResponse = readJsonIfExists(path.join(releaseDir, "release-promote-response.json"));
  const releaseMeta = releaseRegistration?.buildMeta || {};
  const taggedCommit = tryGit(["rev-parse", `${gitTag}^{commit}`], h5Dir);
  const commit = releaseMeta.gitCommit || taggedCommit || git(["rev-parse", "HEAD"], h5Dir);
  const commitShort = commit.slice(0, 7);
  const commitSubject = releaseMeta.commitSubject || git(["log", "-1", "--pretty=%s", commit], h5Dir);
  const branch = releaseMeta.gitBranch || git(["rev-parse", "--abbrev-ref", "HEAD"], h5Dir);
  const previousTag = findPreviousTag(gitTag);
  const logEnd = taggedCommit ? gitTag : "HEAD";
  const commitLines = previousTag
    ? git(["log", "--oneline", `${previousTag}..${logEnd}`], h5Dir)
        .split("\n")
        .filter(Boolean)
    : git(["log", "--oneline", "-8", logEnd], h5Dir)
        .split("\n")
        .filter(Boolean);

  const javaReleaseContext = await fetchJavaReleaseContext(config, version);
  const activeManifest = javaReleaseContext?.activeManifest || await fetchJson(config.manifestUrl);
  const changeSummary = readTextIfExists(path.join(h5Dir, ".ai/CHANGE_SUMMARY.md"));
  const latestChange = extractLatestChange(changeSummary);
  const latestReleaseReport = findLatestReleaseReport(version);
  const javaTargetRelease = javaReleaseContext?.targetRelease || null;
  const javaTargetMeta = normalizeBuildMeta(javaTargetRelease);
  const javaTargetManifest = normalizeJsonObject(javaTargetRelease?.manifest);
  const javaCommit = javaTargetMeta.gitCommit || javaTargetMeta.git_commit || "";
  const javaGitTag = javaTargetMeta.gitTag || javaTargetMeta.git_tag || "";
  const javaCommitSubject = javaTargetMeta.commitSubject || javaTargetMeta.commit_subject || "";
  const resolvedCommit = javaCommit || commit;
  const resolvedGitTag = javaGitTag || gitTag;

  return {
    packageVersion,
    version,
    gitTag: resolvedGitTag,
    commit: resolvedCommit,
    commitShort: resolvedCommit.slice(0, 7),
    commitSubject: javaCommitSubject || commitSubject,
    branch: javaTargetMeta.gitBranch || javaTargetMeta.git_branch || branch,
    previousTag,
    commitLines,
    releaseRegistration,
    releaseResponse: javaTargetRelease || releaseResponse,
    promoteResponse,
    activeManifest,
    targetReleaseManifest: javaTargetManifest,
    javaReleaseContext,
    latestChange,
    latestReleaseReport,
    serviceBaseUrl: config.serviceBaseUrl || "https://hybird.aigcpop.com",
    basePath:
      releaseRegistration?.basePath ||
      javaTargetManifest?.assets?.basePath ||
      activeManifest?.assets?.basePath ||
      `/h5-v/${version}`,
  };
}

function readJson(filePath, fallback) {
  if (!existsSync(filePath)) {
    if (fallback !== undefined) return fallback;
    throw new Error(`文件不存在：${filePath}`);
  }
  return JSON.parse(readFileSync(filePath, "utf8"));
}

function readJsonIfExists(filePath) {
  return existsSync(filePath) ? readJson(filePath) : null;
}

function readTextIfExists(filePath) {
  return existsSync(filePath) ? readFileSync(filePath, "utf8") : "";
}

function git(params, cwd) {
  const result = spawnSync("git", params, { cwd, encoding: "utf8" });
  if (result.status !== 0) {
    throw new Error(`git ${params.join(" ")} 执行失败：${result.stderr || result.stdout}`);
  }
  return result.stdout.trim();
}

function tryGit(params, cwd) {
  const result = spawnSync("git", params, { cwd, encoding: "utf8" });
  if (result.status !== 0) return "";
  return result.stdout.trim();
}

function findPreviousTag(currentTag) {
  const tagList = tryGit(["tag", "--sort=-creatordate", "--merged", "HEAD"], h5Dir)
    .split("\n")
    .filter((tag) => tag.startsWith("h5/v"));
  const currentIndex = tagList.indexOf(currentTag);
  if (currentIndex >= 0) return tagList[currentIndex + 1] || "";
  return tagList.find((tag) => tag !== currentTag) || "";
}

async function fetchJson(url) {
  if (!url) return null;
  try {
    const response = await fetch(url, { headers: { Accept: "application/json" } });
    if (!response.ok) return null;
    return response.json();
  } catch {
    return null;
  }
}

async function fetchJavaReleaseContext(config, version) {
  const activeBaseUrl = String(config.javaReleaseApiBaseUrl || "").trim();
  const listBaseUrl = String(config.javaReleaseRegisterApiBaseUrl || activeBaseUrl).trim();
  if (!activeBaseUrl) return null;

  assertJavaReleaseBaseUrl("javaReleaseApiBaseUrl", activeBaseUrl);
  assertJavaReleaseBaseUrl("javaReleaseRegisterApiBaseUrl", listBaseUrl);

  const environment = config.releaseEnvironment || "test";
  const activeUrl = withEnvironment(`${activeBaseUrl.replace(/\/+$/, "")}/platform/h5Release/active`, environment);
  const listUrl = withEnvironment(`${listBaseUrl.replace(/\/+$/, "")}/platform/h5Release/list`, environment);
  const activePayload = await fetchJsonWithAuth(activeUrl, config.javaReleaseToken);
  const activeManifest = unwrapJavaData(activePayload);
  if (!activeManifest || typeof activeManifest !== "object" || !activeManifest.stableVersion) {
    throw new Error(`无法从 Java H5 版本管理读取 active manifest：${activeUrl}`);
  }

  const listPayload = await fetchJsonWithAuth(listUrl, config.javaReleaseRegisterToken);
  const releaseItems = unwrapJavaData(listPayload);
  if (releaseItems !== null && !Array.isArray(releaseItems)) {
    throw new Error(`Java H5 版本列表返回格式异常：${listUrl}`);
  }

  const activeVersion = activeManifest.stableVersion;
  const targetRelease = Array.isArray(releaseItems)
    ? releaseItems.find((item) => item?.version === version) || null
    : null;
  const activeRelease = Array.isArray(releaseItems)
    ? releaseItems.find((item) => item?.version === activeVersion && item?.status === "active") ||
      releaseItems.find((item) => item?.version === activeVersion) ||
      null
    : null;

  return {
    environment,
    activeUrl,
    listUrl,
    activeManifest,
    activeRelease,
    targetRelease,
    releaseItems: Array.isArray(releaseItems) ? releaseItems : [],
  };
}

function assertJavaReleaseBaseUrl(name, value) {
  if (!value) return;
  if (/\/api\/h5\/manifest|\/api\/releases|\/mini_h5(?:\/|$)/.test(value)) {
    throw new Error(
      `${name} 指向旧 Python manifest/release 或 Java 业务接口，不能用于 H5 版本管理：${value}`,
    );
  }
}

function withEnvironment(url, environment) {
  const separator = url.includes("?") ? "&" : "?";
  return `${url}${separator}environment=${encodeURIComponent(environment)}`;
}

async function fetchJsonWithAuth(url, token) {
  const headers = { Accept: "application/json" };
  if (token) headers.Authorization = token;
  const response = await fetch(url, { headers });
  if (!response.ok) {
    throw new Error(`请求失败 ${response.status}：${url}`);
  }
  return response.json();
}

function unwrapJavaData(payload) {
  if (payload === null || payload === undefined) return null;
  if (typeof payload === "object" && payload.success === false) {
    throw new Error(`Java H5 版本管理返回失败：${payload.msg || JSON.stringify(payload)}`);
  }
  let data = typeof payload === "object" && Object.prototype.hasOwnProperty.call(payload, "data")
    ? payload.data
    : payload;
  if (typeof data === "string") {
    try {
      data = JSON.parse(data);
    } catch {
      return null;
    }
  }
  return data;
}

function normalizeBuildMeta(releaseItem) {
  if (!releaseItem || typeof releaseItem !== "object") return {};
  let buildMeta = releaseItem.buildMeta || releaseItem.build_meta || {};
  if (typeof buildMeta === "string") {
    try {
      buildMeta = JSON.parse(buildMeta);
    } catch {
      buildMeta = {};
    }
  }
  return buildMeta && typeof buildMeta === "object" ? buildMeta : {};
}

function normalizeJsonObject(value) {
  if (!value) return null;
  if (typeof value === "string") {
    try {
      value = JSON.parse(value);
    } catch {
      return null;
    }
  }
  return value && typeof value === "object" && !Array.isArray(value) ? value : null;
}

function extractLatestChange(markdown) {
  if (!markdown) return { title: "未读取到 CHANGE_SUMMARY", changes: [], verification: [] };
  const titleMatch = markdown.match(/^##\s+(.+)$/m);
  const title = titleMatch?.[1]?.trim() || "最近变更";
  const firstSectionStart = titleMatch ? titleMatch.index || 0 : 0;
  const nextSectionIndex = markdown.slice(firstSectionStart + 1).search(/\n##\s+/);
  const section =
    nextSectionIndex >= 0
      ? markdown.slice(firstSectionStart, firstSectionStart + 1 + nextSectionIndex)
      : markdown.slice(firstSectionStart);
  return {
    title,
    changes: extractBullets(section, "变更"),
    verification: extractBullets(section, "验证"),
  };
}

function extractBullets(section, heading) {
  const pattern = new RegExp(`###\\s+${heading}\\s*\\n([\\s\\S]*?)(\\n###\\s+|$)`);
  const match = section.match(pattern);
  if (!match) return [];
  return match[1]
    .split("\n")
    .map((line) => line.trim())
    .filter((line) => line.startsWith("- "))
    .map((line) => line.slice(2).trim())
    .slice(0, 8);
}

function findLatestReleaseReport(version) {
  const reportDir = path.join(h5Dir, ".ai/test-reports");
  if (!existsSync(reportDir)) return null;
  const result = spawnSync("find", [reportDir, "-maxdepth", "1", "-type", "f", "-name", `*${version}*release*.md`], {
    cwd: rootDir,
    encoding: "utf8",
  });
  const filePath = result.stdout
    .split("\n")
    .filter(Boolean)
    .sort()
    .at(-1);
  if (!filePath) return null;
  return {
    path: path.relative(rootDir, filePath),
    content: readTextIfExists(filePath),
  };
}

function renderReviewMessage(context, config) {
  return renderMessage({
    context,
    config,
    title: context.version === "v1.0.13" ? "【更正版待审核】MeuMall H5 发版通报" : "【待审核】MeuMall H5 发版通报",
    includeApprovalGuide: true,
  });
}

function renderOfficialMessage(context, config, state) {
  return renderMessage({
    context,
    config,
    title: "【MeuMall H5 发版通报】",
    includeApprovalGuide: false,
    approvedBy: state.approvedBy,
  });
}

function renderOverviewReviewMessage(context, config) {
  return renderOverviewMessage({
    context,
    config,
    title: "【待审核】MeuMall H5 项目迭代总览",
    includeApprovalGuide: true,
  });
}

function renderOverviewOfficialMessage(context, config, state) {
  return renderOverviewMessage({
    context,
    config,
    title: "【MeuMall H5 项目迭代总览】",
    includeApprovalGuide: false,
    approvedBy: state.approvedBy,
  });
}

function renderOverviewMessage({ context, config, title, includeApprovalGuide, approvedBy }) {
  const versionUrl = `${context.serviceBaseUrl}${context.basePath}/`;
  const activeVersion = context.activeManifest?.stableVersion || "未读取到";
  const rollbackVersion =
    context.releaseRegistration?.rollbackVersion ||
    context.targetReleaseManifest?.rollbackVersion ||
    context.activeManifest?.rollbackVersion ||
    "未读取到";
  const overview = buildProjectOverview(context, config);

  const lines = [
    `# ${title}`,
    "",
    "这条先不讲某一个小版本，而是把 MeuMall H5 从立项到今天的项目进展统一同步给大家。后续每次发版，我会只发当前版本相对上个版本的增量变化。",
    "",
    `- 当前线上 active 版本：${activeVersion}`,
    `- 当前 H5 版本入口：${versionUrl}`,
    `- 当前回滚版本：${rollbackVersion}`,
    `- 当前阶段：${overview.stage}`,
    `- 构建提交：${context.gitTag} / ${context.commitShort}`,
    "",
    "## 到今天为止，我们已经完成了什么",
    "",
    "**1. 项目协作和交付机制**",
    ...toBullets(overview.deliverySystem),
    "",
    "**2. H5 工程架构和运行机制**",
    ...toBullets(overview.h5Architecture),
    "",
    "**3. 页面和业务能力**",
    ...toBullets(overview.pageProgress),
    "",
    "**4. 跨端和发布能力**",
    ...toBullets(overview.crossTeamProgress),
    "",
    "## 这些变化对大家意味着什么",
    "",
    "**外部运行环境**",
    ...toBullets(overview.nativeImpact),
    "",
    "**Java/API / 配置平台**",
    ...toBullets(overview.backendImpact),
    "",
    "**测试**",
    ...toBullets(overview.testImpact),
    "",
    "## 现在还缺什么，需要大家配合什么",
    "",
    "**外部运行环境需要配合**",
    ...toBullets(overview.nativeNeeded),
    "",
    "**Java/API / 配置平台需要配合**",
    ...toBullets(overview.backendNeeded),
    "",
    "**测试需要配合**",
    ...toBullets(overview.testNeeded),
    "",
    "## 后续通知规则",
    ...toBullets(overview.futureNoticeRule),
  ];

  if (approvedBy) {
    lines.push("", `审核人：${approvedBy}`);
  }

  if (includeApprovalGuide) {
    lines.push(
      "",
      "## 审核方式",
      `请审核人确认这份总览口径可以发到正式群后，在「${config.senderDisplayName || "飞书机器人"}」所在审核会话回复：同意 总览`,
      "也可以回复：approve overview",
      "",
      "审核通过后，执行：",
      "",
      "```bash",
      "pnpm run feishu:h5-release-notice -- check-overview-approval",
      "pnpm run feishu:h5-release-notice -- send-overview-approved",
      "```",
    );
  }

  if (config.scheduleBaseUrl || config.knowledgeBaseUrl) {
    lines.push("", "## 协作入口");
    if (config.scheduleBaseUrl) lines.push(`- 排期多维表格：${config.scheduleBaseUrl}`);
    if (config.knowledgeBaseUrl) lines.push(`- 项目知识库：${config.knowledgeBaseUrl}`);
  }

  return lines.join("\n");
}

function renderMessage({ context, config, title, includeApprovalGuide, approvedBy }) {
  const versionUrl = `${context.serviceBaseUrl}${context.basePath}/`;
  const activeVersion = context.activeManifest?.stableVersion || "未读取到";
  const releaseStatus =
    context.promoteResponse?.status ||
    context.releaseResponse?.status ||
    (activeVersion === context.version ? "active" : "candidate/待确认");
  const rollbackVersion =
    context.releaseRegistration?.rollbackVersion ||
    context.targetReleaseManifest?.rollbackVersion ||
    context.activeManifest?.rollbackVersion ||
    "未读取到";
  const notice = buildReleaseNotice(context, config);

  const lines = [
    `# ${title}`,
    "",
    `这次 H5 已发布到 ${releaseStatus}，当前 active manifest 指向 ${activeVersion}。`,
    "",
    `- 版本：${context.version}`,
    `- 地址：${versionUrl}`,
    `- 回滚版本：${rollbackVersion}`,
    `- 构建提交：${context.gitTag} / ${context.commitShort}`,
    "",
    "## 这次改了什么",
    ...toBullets(notice.changes),
    "",
    "## 和上个版本相比，影响哪里",
    ...toBullets(notice.impact),
    "",
    "## 验证情况",
    ...toBullets(notice.verification),
    "",
    "## 需要大家配合什么",
    "",
    "**外部运行环境**",
    "",
    "已对接：",
    ...toBullets(notice.nativeDone),
    "",
    "还需要你们确认/提供：",
    ...toBullets(notice.nativeNeeded),
    "",
    "**Java/API / 配置平台**",
    "",
    "已对接：",
    ...toBullets(notice.backendDone),
    "",
    "还需要你们确认/提供：",
    ...toBullets(notice.backendNeeded),
    "",
    "**测试重点**",
    ...toBullets(notice.testFocus),
  ];

  if (approvedBy) {
    lines.push("", `审核人：${approvedBy}`);
  }

  if (includeApprovalGuide) {
    lines.push(
      "",
      "## 审核方式",
      `请审核人确认后在「${config.senderDisplayName || "飞书机器人"}」所在审核会话回复：同意 ${context.version}`,
      `也可以回复：approve ${context.version}`,
      "",
      "审核通过后，执行：",
      "",
      "```bash",
      "pnpm run feishu:h5-release-notice -- check-approval",
      "pnpm run feishu:h5-release-notice -- send-approved",
      "```",
    );
  }

  if (config.scheduleBaseUrl || config.knowledgeBaseUrl) {
    lines.push("", "## 协作入口");
    if (config.scheduleBaseUrl) lines.push(`- 排期多维表格：${config.scheduleBaseUrl}`);
    if (config.knowledgeBaseUrl) lines.push(`- 项目知识库：${config.knowledgeBaseUrl}`);
  }

  return lines.join("\n");
}

function buildProjectOverview(context, config) {
  const override = config.projectOverview || {};
  return {
    stage:
      override.stage ||
      "H5 基础架构、版本发布体系、跨端跳转协议和推广相关页面已进入线上联调准备阶段",
    deliverySystem: override.deliverySystem?.length ? override.deliverySystem : [
      "根目录已经建立统一 AI 工作机制：工作项结构、状态流转、验收标准、上下文记忆、契约治理和发布治理都有仓库内事实源。",
      "H5 需求开发已经形成固定流程：先确定页面范围、渲染模式、BFF mock、接口契约、外部运行环境依赖和测试口径，再进入页面实现。",
      "飞书知识库和飞书多维表格已经纳入协作流：对接文档、路由说明、排期、接口需求、外部依赖和测试事项可以集中维护。",
      "发版通告已经接入飞书审核流：先发审核群，经负责人确认后再发正式对接群，避免未确认内容直接打扰大家。",
    ],
    h5Architecture: override.h5Architecture?.length ? override.h5Architecture : [
      "H5 使用 Next.js 承载，线上按 `/h5-v/<version>` 多版本路径发布，静态资源会跟随版本 basePath，避免新旧版本资源串用。",
      "版本控制已经从手写 URL 收敛到 active manifest：固定入口和外部容器读取 manifest 后再拼 H5 URL，后续切 active 或回滚不需要改二维码或重新发 H5 代码。",
      "H5 已建立 Bridge 路由抽象，统一处理 H5 内跳转、打开新 WebView、关闭 WebView、切回外部 Tab 和打开外部页面。",
      "H5 已接入运行时 cookie 调试能力，能读取 `pythonToken`、`mallToken`、`statusHeight`，后续请求会按 Java/Python 服务分别带 Authorization。",
      "页面侧已经开始收敛设计体系：颜色、间距、顶部导航、静态图片资产、版本 basePath 引用都有统一规则。",
    ],
    pageProgress: override.pageProgress?.length ? override.pageProgress : [
      "一级 Tab 页面已完成首轮闭环，H5 页面不再保留外部容器 Tab，Tab 由外部运行环境承载。",
      "推广首页已完成高保真版本，并接入达人等级、带货汇总、页面入口和本地静态资源体系。",
      "权益中心已完成高保真和等级切换交互，支持左右切换、等级主题、特权列表和权益图片资源。",
      "榜单中心、销量榜、销售额榜已按设计方向推进，排行榜静态资源和顶部视觉正在收敛到可复用资产。",
      "活动中心、佣金收益、商品详情、搜索等页面已纳入页面盘点和路由协作范围，后续按单页面需求继续拆分开发和联调。",
    ],
    crossTeamProgress: override.crossTeamProgress?.length ? override.crossTeamProgress : [
      "Java H5 版本管理已支持版本注册、active manifest、候选版本、切 active 和回滚信息。",
      "Jenkins / 本地发布脚本已经能构建 H5 多版本容器，并把候选版本发布到测试服务器。",
      "Nginx 已按版本路径转发 H5 容器，`hybird.aigcpop.com` 作为 App 侧统一入口。",
      "外部运行环境对接文档已经补充 WebView 容器策略、路由跳转原则、Bridge 调用清单和 H5 侧职责边界。",
    ],
    nativeImpact: override.nativeImpact?.length ? override.nativeImpact : [
      "外部入口不需要写死 H5 版本地址，只需要读取 active manifest，然后按 `serviceBaseUrl + basePath + route` 拼接最终 URL。",
      "首页、搜索、商品详情、消息、分类等场景会区分当前 WebView 内 push 和新开 H5 WebView，目的是保留首页缓存和滚动位置。",
      "二级/三级 H5 页面返回首页或其他 Tab 根页面时，H5 会通过 Bridge 通知原生关闭当前 WebView 或切 Tab。",
    ],
    backendImpact: override.backendImpact?.length ? override.backendImpact : [
      "当前推广、权益、榜单等页面仍以 H5 BFF mock 和静态配置为主，没有把 mock 当成正式业务接口。",
      "后续每个页面会按需求主体拆出 Java/API 子需求，明确服务、鉴权 token、字段、分页、错误码和兜底规则。",
      "首页运营配置、活动配置、榜单数据、权益数据、佣金收益等都需要 Java/API 或配置平台逐步提供正式接口或配置能力。",
    ],
    testImpact: override.testImpact?.length ? override.testImpact : [
      "测试重点从单页面 UI 扩展到版本切换、静态资源、外部 WebView 容器、Bridge 返回、cookie/token 和接口兜底。",
      "每次 H5 发版会给出当前版本的验证结果和需要重点回归的链路。",
    ],
    nativeNeeded: override.nativeNeeded?.length ? override.nativeNeeded : [
      "确认外部入口 active manifest 读取、URL 拼接、缓存策略和 WebView 新开/关闭规则。",
      "确认 Bridge 能力实现清单：`open`、`back`、`close_webview`、`tab`、`native_page`、`route_changed` 等能力由外部运行环境接收并处理。",
      "实机验证 cookie 写入：`pythonToken`、`mallToken`、`statusHeight` 必须在 H5 WebView 内可读取。",
    ],
    backendNeeded: override.backendNeeded?.length ? override.backendNeeded : [
      "按页面补齐正式业务接口：推广首页、权益中心、榜单中心、排行榜、活动中心、佣金收益等。",
      "明确接口环境、鉴权方式、错误码、分页规则、空态规则和 mock 到正式接口的切换时间。",
      "Java 配置平台需要补齐首页配置、活动配置、素材配置、版本配置和上下线规则，避免 H5 长期写死运营内容。",
    ],
    testNeeded: override.testNeeded?.length ? override.testNeeded : [
      "补充外部容器内 H5 打开、H5 内跳转、新 WebView、关闭返回、Tab 切换、token 过期重新认证等联调用例。",
      "提供测试账号、测试 token、设备覆盖范围和验收标准，方便 H5 发版后快速做 smoke 和回归。",
    ],
    futureNoticeRule: override.futureNoticeRule?.length ? override.futureNoticeRule : [
      "今天这条是项目总览，只用于建立共同背景。",
      "后续每个 H5 版本只同步当前版本改了什么、相对上个版本影响哪里、验证结果如何、还需要外部运行环境、Java/API 或测试配合什么。",
      "如果某个版本只改 H5 页面，不涉及外部运行环境或 Java/API，也会明确写出来，避免大家误以为需要额外联调。",
    ],
  };
}

function buildReleaseNotice(context, config) {
  const override = config.releaseNotice || {};
  const knownReleaseNotice = buildKnownReleaseNotice(context);
  const rawChanges = context.latestChange.changes.length
    ? context.latestChange.changes
    : context.commitLines.map((line) => line.replace(/^[a-f0-9]+\s+/, "")).slice(0, 8);
  const routes = context.releaseRegistration?.routes || context.activeManifest?.routes || [];
  const hasRoute = (route) => {
    if (Array.isArray(routes)) return routes.includes(route);
    if (routes && typeof routes === "object") return Object.prototype.hasOwnProperty.call(routes, route);
    return false;
  };
  const activeVersion = context.activeManifest?.stableVersion || context.version;
  const basePath = context.basePath;
  const targetStatus = context.releaseResponse?.status || (activeVersion === context.version ? "active" : "candidate");
  const versionImpact =
    activeVersion === context.version
      ? `H5 线上 active 已切到 ${activeVersion}，App 重新读取 Java active manifest 后会拿到 ${basePath} 这一版资源。`
      : `${context.version} 已注册为 ${targetStatus}，当前 Java active 仍指向 ${activeVersion}；管理系统 promote 后，App 重新读取 Java active manifest 才会拿到 ${basePath} 这一版资源。`;

  const changes = override.changes?.length
    ? override.changes
    : knownReleaseNotice.changes?.length
      ? knownReleaseNotice.changes
    : humanizeChanges(rawChanges, context);

  const impact = override.impact?.length
    ? override.impact
    : knownReleaseNotice.impact?.length
      ? knownReleaseNotice.impact
    : [
        versionImpact,
        hasRoute("/member")
          ? "旧 `/member` 路由仍在 manifest 中，暂未清理。"
          : "旧 `/member` 路由已从 H5 和 manifest 中移除，后续不要再从 App 或配置里跳这个地址。",
        "推广页入口规则做了收敛：佣金收益从推广首页进入，权益中心从我的页进入；推广首页头像、昵称、徽章不再跳权益中心。",
        "H5 返回、切 Tab、关闭二级 WebView、打开原生设置页这些动作已统一走 Bridge route，不再由页面各自拼逻辑。",
      ];

  const verification = override.verification?.length
    ? override.verification
    : knownReleaseNotice.verification?.length
      ? knownReleaseNotice.verification
    : [
        "H5 自动化检查已过：test、typecheck、lint、生产构建都通过。",
        `线上 smoke 已过：${basePath}/api/health、首页、推广页、我的页、搜索页都能访问。`,
        `active manifest 已确认指向 ${activeVersion}，目标版本回滚版本是 ${context.releaseRegistration?.rollbackVersion || context.targetReleaseManifest?.rollbackVersion || context.activeManifest?.rollbackVersion || "未读取到"}。`,
      ];

  return {
    changes,
    impact,
    verification,
    nativeDone: override.nativeDone?.length
      ? override.nativeDone
      : knownReleaseNotice.nativeDone?.length
        ? knownReleaseNotice.nativeDone
      : [
          "H5 已按 active manifest 版本体系发布，当前版本入口是 `/h5-v/<version>`。",
          "H5 已发出 Bridge route：`webview`、`tab`、`back`、`close_webview`、`native_page=settings`。",
          "H5 已上报 `event/route_changed`，方便外部运行环境同步 WebView 内部路由状态。",
        ],
    nativeNeeded: override.nativeNeeded?.length
      ? override.nativeNeeded
      : knownReleaseNotice.nativeNeeded?.length
        ? knownReleaseNotice.nativeNeeded
      : [
          "请确认外部入口打开 H5 时以 Java H5 版本管理 active manifest 为准，不要读旧 Python manifest，也不要写死某个版本 URL。",
          "请确认外部运行环境已处理 `tab`、`close_webview`、`native_page=settings` 和 `route_changed`，尤其是二级 WebView 返回首页/Tab 根页面时要关闭当前 WebView。",
          "请实机验证：首页打开搜索/消息/分类/商品详情的新 WebView 策略，以及从二级页返回后首页滚动位置是否保留。",
        ],
    backendDone: override.backendDone?.length
      ? override.backendDone
      : knownReleaseNotice.backendDone?.length
        ? knownReleaseNotice.backendDone
      : [
          "本次 H5 发布已接入 Java H5 版本管理：`GET /platform/h5Release/active`、`GET /platform/h5Release/list`、`POST /platform/h5Release`，promote/rollback 也以 Java 管理系统为准。",
          "本次没有新增正式业务 API 依赖；推广、权益、榜单相关页面仍以 H5 BFF mock 和静态配置为主。",
        ],
    backendNeeded: override.backendNeeded?.length
      ? override.backendNeeded
      : knownReleaseNotice.backendNeeded?.length
        ? knownReleaseNotice.backendNeeded
      : [
          "后续正式联调前，需要补齐推广首页、权益中心、榜单中心、佣金收益等业务接口，并明确 Java token 使用规则。",
          "如果首页、推广页或活动入口要从 Java 配置平台配置，请 Java/API 提前给出字段结构、上下线规则和兜底数据。",
          "当前没有支付、订单创建、真实佣金结算接口接入；涉及资金或交易的数据请以后端真实接口为准，H5 不会伪造。",
        ],
    testFocus: override.testFocus?.length
      ? override.testFocus
      : knownReleaseNotice.testFocus?.length
        ? knownReleaseNotice.testFocus
      : [
          "请重点回归外部容器打开 H5、H5 内跳 H5、H5 返回/关闭 WebView、切回 Tab 根页面这几条链路。",
          "请检查 `/member` 已不可访问，旧入口不要再出现。",
          "请检查版本角标、图片资源、权益中心/推广相关页面是否有白屏或 404。",
        ],
  };
}

function buildKnownReleaseNotice(context) {
  if (context.version === "v1.0.13") {
    return {
      changes: [
        "首页真实接口链路已联调完成：新增 `/api/bff/home`、`/api/bff/home/for-you-products`、`/api/bff/home/recommend-products`，首页和推荐商品页已从静态 mock 迁到 H5 BFF 聚合真实数据。",
        "商品详情真实链路已联调完成：新增 `/api/bff/product-detail` 和 `/api/bff/order-confirm`，商品详情页已接入真实商品详情、规格、店铺、评价和富文本详情内容。",
        "当前主要卡点是下单链路：商品详情和订单确认页已经能走到前端页面，但后端创建订单/下单能力还不可用，导致目前无法完成真实下单闭环。",
        "个人中心后续二级页已完成高保真静态页面：钱包、优惠券、我的收藏、我的足迹、订单列表都已按 Figma 方向落地；钱包/订单 tab 切换改为页面内状态，不再修改路由。",
        "我的收藏和我的足迹补齐编辑删除确认；个人中心达人等级改为图片徽章，收藏/足迹/订单商品图统一使用缺省图片组件。",
        "Bridge 和设置页链路已更新：H5 跳原生设置页、关闭二级 WebView、切 Tab、返回和 `route_changed` 上报都收敛到统一 Bridge route，并同步更新 Native Bridge 文档和页面盘点。",
        "根工作区同步了首页真实接口、商品详情真实链路、H5 BFF 鉴权、Native Bridge、个人中心二级页等任务、契约和集成说明。",
        "缺省图标只是本次末尾的小优化：`ProductImagePlaceholder` 现在默认居中展示 `Vector.png` 图标，背景色仍由 CSS 控制。",
      ],
      impact: [
        "线上 active 已切到 `v1.0.13`，manifest 的 basePath 是 `/h5-v/v1.0.13`，App 重新读取 active manifest 后会进入这一版。",
        "这版重点影响首页、推荐商品页、商品详情页、订单确认页、个人中心二级页，以及 H5 到原生设置页/二级 WebView 的 Bridge 跳转。",
        "首页和商品详情不再是纯静态样式验证，已经进入真实接口联调口径；个人中心二级页目前仍是高保真静态页面，先用于视觉、交互和路由验收。",
        "交易链路目前不能按“已可下单”验收：商品可以看详情、选规格、进入订单确认，但创建订单卡在后端下单接口能力。",
        "钱包和订单页 tab 切换不会再 push 路由，避免影响 WebView 返回事件；切换时保留页面内动画和 tab 横线移动。",
      ],
      verification: [
        "H5 本地自动化已过：`pnpm test` 44 个文件 / 226 个用例通过，`pnpm typecheck` 通过，`pnpm lint` 通过，生产 `pnpm run build` 通过。",
        "线上发布脚本 smoke 已过：`/h5-v/v1.0.13/api/health` 和版本首页可访问。",
        "外网路由已验证：`/mine`、`/wallet`、`/orders`、`/favorites/products`、`/footprints`、`/coupons` 均返回 200。",
        "active manifest 已确认指向 `v1.0.13`，回滚版本是 `v1.0.12`。",
      ],
      nativeDone: [
        "H5 已按 active manifest 版本体系发布，当前版本入口是 `/h5-v/v1.0.13`。",
        "H5 已统一发出 Bridge route：`webview`、`tab`、`back`、`close_webview`、`native_page=settings`。",
        "设置入口已改为走 `native_page=settings`，不再当作普通 H5 页面跳转。",
        "H5 已上报 `event/route_changed`，用于原生侧同步 WebView 内部路由状态。",
      ],
      nativeNeeded: [
        "请确认 App 启动和打开 H5 时以 Java H5 版本管理 active manifest 为准，不要读旧 Python manifest，也不要写死某个版本 URL。",
        "请确认原生侧已处理 `native_page=settings`，个人中心设置入口需要拉起原生设置页。",
        "请重点实机验证二级 WebView 返回：钱包、订单、收藏、足迹、优惠券、商品详情、订单确认页返回时不要被页面内 tab 状态污染。",
        "请确认 `tab`、`back`、`close_webview`、`webview` 和 `route_changed` 的事件处理仍符合最新 Bridge 文档。",
      ],
      backendDone: [
        "首页真实接口已通过 H5 BFF 接入并完成联调，首页推荐和推荐商品列表不再只依赖静态 mock。",
        "商品详情真实接口已通过 H5 BFF 接入并完成联调，商品详情、规格、店铺、评价、富文本详情已经进入真实数据口径。",
        "发版和 manifest 已走版本管理服务：`v1.0.13` 已注册并 promoted active；后续新发版以 Java H5 版本管理为准。",
      ],
      backendNeeded: [
        "当前最需要后端支持的是下单：请优先补齐或修复订单预览/创建订单接口，让商品详情到订单确认后的真实下单链路能闭环。",
        "请明确下单接口所需 token、地址、SKU、库存、价格、优惠券、运费、错误码和不可购买状态的字段口径。",
        "个人中心钱包、优惠券、收藏、足迹、订单列表目前是高保真静态页，后续需要后端提供真实数据接口和分页/删除/筛选规则。",
        "如果首页和商品详情后续字段仍会调整，请同步接口契约，避免 H5 BFF 再次临时适配。",
      ],
      testFocus: [
        "重点回归首页真实数据展示、推荐商品页、商品详情真实数据、规格选择、富文本详情和订单确认页。",
        "请把“无法真实下单”作为已知卡点记录：目前不要把创建订单失败判断成 H5 页面回归失败，除非后端确认接口已可用。",
        "重点验收个人中心二级页的高保真静态效果：钱包、优惠券、收藏、足迹、订单列表，以及编辑删除确认弹窗。",
        "重点验证钱包/订单 tab 切换不会改变 URL，页面返回事件不被影响。",
        "重点验证设置页 Bridge：点击个人中心设置入口应进入原生设置页。",
      ],
    };
  }
  if (context.version !== "v1.0.12") return {};
  return {
    changes: [
      "搜索页完成静态高保真：搜索历史、清除历史弹窗、tab 切换、筛选展开/选择/蒙层关闭都已经补齐。",
      "新增搜索热榜页 `/search/ranking`，从搜索页“查看更多”进入。",
      "推广商品页完成筛选、商品卡、收藏/推广按钮；筛选选中后会展示当前选项。",
      "推广商品“推广”按钮已接入 `share` Bridge，当前 payload 固定 `productId=1001`，方便原生 App 联调。",
      "限时秒杀页完成顶部背景图和商品区静态展示。",
      "商品详情补了购买弹窗，点击“选择”不再写入 hash，而是直接打开购买弹窗。",
      "新增提交订单静态页 `/order-confirm`，购买弹窗确认后进入。",
      "商品卡片图片统一使用 `ProductImagePlaceholder` 缺省组件；分类页 tab 改为组件内状态切换，不再写 `#level-*`。",
    ],
    impact: [
      "线上 active 已从 `v1.0.11` 切到 `v1.0.12`，manifest 的 basePath 是 `/h5-v/v1.0.12`。",
      "这版主要影响 `/search`、`/search/ranking`、`/promotion/products`、`/seckill`、`/product/[id]`、`/order-confirm`、`/category`。",
      "当前仍是“静态页面 + H5 Mock”阶段，真实后端接口还没全面接入；这次先验证页面、交互、路由和 Bridge 调用是否符合预期。",
    ],
    verification: [
      "本地 `pnpm test` 154 个用例通过，typecheck 通过，生产 build 通过。",
      "线上 version smoke 通过，active manifest 已确认是 `v1.0.12`。",
      "`/promotion/products`、`/search`、秒杀背景图资源返回 200。",
    ],
    nativeDone: [
      "H5 已在推广商品页发起 `share` Bridge，payload 中 `productId=1001`。",
      "H5 页面内普通跳转会尽量保持当前 WebView 内 push；首页打开商品详情仍按之前讨论新开 H5 WebView。",
    ],
    nativeNeeded: [
      "iOS/Android 请接一下推广商品分享 Bridge，先按 `productId=1001` 验证能否拉起原生分享面板。",
      "搜索页、推广商品页、秒杀页、商品详情、订单确认这些二级页返回时，请继续按 WebView history / close WebView 规则验证。",
      "商品详情地址入口后续要跳地址列表，目前 H5 还没做地址列表页，先不要按最终交易链路验收。",
    ],
    backendDone: [
      "发版和 manifest 已走真实服务：`v1.0.12` 已注册并 promoted active。",
      "页面当前使用 H5 Mock 数据，不阻塞大家先看页面和交互。",
    ],
    backendNeeded: [
      "需要补搜索建议、搜索结果、搜索热榜接口。",
      "需要补推广商品列表/筛选接口。",
      "需要补秒杀活动、秒杀商品、库存、服务端时间接口。",
      "需要补商品详情实时价格、库存、规格、可购买状态接口。",
      "需要补订单预览、创建订单接口。",
    ],
    testFocus: [
      "重点测 `/search`、`/search/ranking`、`/promotion/products`、`/seckill`、`/product/[id]`、`/order-confirm`、`/category`。",
      "重点检查筛选条件、tab 切换、返回行为、购买弹窗、订单确认静态页和静态图片资源。",
      "推广商品分享需要在 App 内验证 Bridge payload 是否被原生收到。",
    ],
  };
}

function humanizeChanges(items, context) {
  if (!items.length) {
    return [`这次主要发布 ${context.version}，用于同步 H5 最新页面和跨端跳转能力。`];
  }
  return items.slice(0, 6).map((item) => {
    const text = item.replace(/。$/, "");
    if (text.includes("package.json") || text.includes("版本")) {
      return `版本已升级到 ${context.version}，后续可以通过 manifest 精确识别这一版 H5。`;
    }
    if (text.includes("release") || text.includes("promote") || text.includes("active manifest")) {
      return `这版已经注册到 release 服务，并切到 prod active；App 重新拉 manifest 后会进入新版本。`;
    }
    if (text.includes("/member")) {
      return "旧的 `/member` 入口已经清掉，后面统一以推广首页和我的页里的正式入口为准。";
    }
    return text;
  });
}

function toBullets(items) {
  if (!items.length) return ["- 暂无"];
  return items.map((item) => `- ${item}`);
}

function ensureReviewTarget(config) {
  if (!config.reviewChatId && !config.reviewUserId) {
    throw new Error(
      `缺少审核接收方。请复制 ${path.relative(rootDir, exampleConfigPath)} 为 ${path.relative(
        rootDir,
        localConfigPath,
      )}，填写 reviewChatId 或 reviewUserId。`,
    );
  }
}

function ensureTargetChat(config) {
  if (!config.targetChatId) {
    throw new Error(
      `缺少正式对接群 targetChatId。请在 ${path.relative(rootDir, localConfigPath)} 中配置。`,
    );
  }
}

function resolveReviewTarget(config) {
  if (config.reviewChatId) return { type: "chat", id: config.reviewChatId };
  return { type: "user", id: config.reviewUserId };
}

function sendFeishuMessage({ config, markdown, target, idempotencyKey, dryRun }) {
  const params = ["im", "+messages-send", "--as", config.sendAs || "bot", "--markdown", markdown, "--idempotency-key", idempotencyKey, "--format", "json"];
  if (config.profile) params.push("--profile", config.profile);
  if (target.type === "chat") {
    params.push("--chat-id", target.id);
  } else {
    params.push("--user-id", target.id);
  }
  if (dryRun) params.push("--dry-run");

  const result = spawnSync("lark-cli", params, { cwd: rootDir, encoding: "utf8" });
  if (result.status !== 0) {
    throw new Error(`lark-cli 发送失败：${result.stderr || result.stdout}`);
  }
  return parseJsonOrText(result.stdout);
}

function checkApprovalFromFeishu({ config, context, approvalPhrases }) {
  if (!config.reviewChatId) {
    return {
      approved: false,
      evidence: "当前配置使用 reviewUserId，脚本无法读取私聊审核消息；请使用 mark-approved。",
    };
  }

  const params = [
    "im",
    "+chat-messages-list",
    "--as",
    config.approvalReadAs || config.sendAs || "bot",
    "--chat-id",
    config.reviewChatId,
    "--page-size",
    "50",
    "--sort",
    "desc",
    "--no-reactions",
    "--format",
    "json",
  ];
  if (config.profile) params.push("--profile", config.profile);
  const result = spawnSync("lark-cli", params, { cwd: rootDir, encoding: "utf8" });
  if (result.status !== 0) {
    throw new Error(`lark-cli 读取审核消息失败：${result.stderr || result.stdout}`);
  }
  const payloadText = result.stdout;
  const normalized = payloadText.toLowerCase();
  const matchedPhrase = (approvalPhrases || buildReleaseApprovalPhrases(config, context.version)).find((phrase) =>
    normalized.includes(String(phrase).toLowerCase()),
  );

  if (!matchedPhrase) return { approved: false };
  return {
    approved: true,
    approvedBy: "飞书审核消息",
    evidence: matchedPhrase,
  };
}

function buildReleaseApprovalPhrases(config, version) {
  const lowerVersion = String(version).toLowerCase();
  return (config.approvalKeywords || ["同意", "确认", "approve"]).flatMap((keyword) => {
    const lowerKeyword = String(keyword).toLowerCase();
    return [`${lowerKeyword} ${lowerVersion}`, `${lowerKeyword}${lowerVersion}`];
  });
}

function buildOverviewApprovalPhrases(config) {
  const keywords = config.approvalKeywords || ["同意", "确认", "approve"];
  const targets = ["总览", "项目总览", "overview", "project overview"];
  return keywords.flatMap((keyword) =>
    targets.flatMap((target) => {
      const lowerKeyword = String(keyword).toLowerCase();
      const lowerTarget = String(target).toLowerCase();
      return [`${lowerKeyword} ${lowerTarget}`, `${lowerKeyword}${lowerTarget}`];
    }),
  );
}

function parseJsonOrText(value) {
  const text = String(value || "").trim();
  if (!text) return {};
  try {
    return JSON.parse(text);
  } catch {
    return { raw: text };
  }
}

function writeGenerated(version, suffix, content) {
  const filePath = path.join(generatedDir, `${version}-${suffix}`);
  writeFileSync(filePath, content, "utf8");
  return path.relative(rootDir, filePath);
}

function overviewStateKey(context) {
  return `overview-${context.version}`;
}

function statePath(version) {
  return path.join(generatedDir, `${version}-state.json`);
}

function loadState(version) {
  const filePath = statePath(version);
  return existsSync(filePath) ? readJson(filePath, {}) : {};
}

function writeState(version, state) {
  writeFileSync(statePath(version), `${JSON.stringify(state, null, 2)}\n`, "utf8");
}

function printStatePath(version) {
  console.log(`状态文件：${path.relative(rootDir, statePath(version))}`);
}

function idempotencyKey(type, version, content) {
  return createHash("sha256").update(`meumall:${type}:${version}:${content}`).digest("hex").slice(0, 32);
}
