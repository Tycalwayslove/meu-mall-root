# TASK-2026-0611-004-H5 环境配置收敛

## 状态

verified

## 目标

为 `hybird-meumall` 建立本地 H5 开发、测试、正式三套环境配置，并在当前正式环境服务器和域名未完成前，统一指向现有测试 H5 配置和测试后端域名。

## 背景

首页真实接口已开始接入，后续会持续新增 Java / Python 接口。为了避免每次联调都临时手写域名，需要先把 H5 服务地址、manifest 地址、Java 后端地址和 Python 后端地址收敛到稳定环境配置中。

## 涉及项目

- `hybird-meumall`
- 根目录启动脚本

## 范围

包含：

- 新增三套 H5 环境配置文件。
- 本地 H5 启动命令读取环境配置。
- 根目录 `dev-all.sh` 读取 H5 环境配置并注入 Java / Python 后端域名。
- 更新 `.env.example`、API 规范、发布规范、变更记录和项目状态。

不包含：

- 不修改 Java / Python 后端。
- 不发布正式 H5 版本。
- 不切换远端 active manifest。
- 不改变首页接口 mapper 和页面展示逻辑。

## 责任边界

H5：

- 负责通过环境变量选择 H5、manifest、Java 和 Python base URL。
- 负责浏览器端继续只请求自身 BFF。
- 负责服务端 BFF 使用 `JAVA_API_BASE_URL` / `PYTHON_API_BASE_URL` 请求后端。

后端：

- Java 测试环境由 `https://test.aigcpop.com/mini_h5` 提供。
- Python 测试环境由 `https://test.aigcpop.com/api` 提供。

## 契约影响

- 是否影响跨项目契约：是，明确 H5 BFF 的后端环境变量取值。
- 契约文档路径：`.ai-workspace/contracts/api/h5-bff-http-auth-contract.md`
- 是否向后兼容：是。
- 是否需要迁移：否。
- 是否需要灰度：否，本次为本地配置和文档收敛。

## 对接说明

- 对接说明路径：无新增，对首页接口已有对接说明补充真实测试域名。
- 需要确认角色：Java 后端、Python 后端、测试。
- 当前确认状态：用户已确认当前 Java / Python 后端测试域名。

## 对方责任

- 后端继续保证测试域名可访问。
- 测试在联调时按同一套域名验证首页和后续接口。

## Mock 和联调方式

- 本地 H5 通过 `config/env/h5.local.env` 启动。
- 测试配置通过 `config/env/h5.test.env` 表达。
- 正式配置暂时通过 `config/env/h5.prod.env` 表达，但域名仍指向现有测试环境，待正式域名完成后再替换。

## 验收标准

- [x] 三套环境配置文件存在，并包含 H5、manifest、Java、Python 关键地址。
- [x] 根目录 `dev:h5` 和 H5 项目本地启动命令能读取本地环境配置。
- [x] `dev-all.sh` 能加载 H5 环境文件并向 H5 dev server 注入 Java / Python 后端地址。
- [x] 文档不再引用旧 Java 测试地址作为当前联调入口。
- [x] 环境配置校验、脚本语法检查和相关测试通过。

## 验证命令

```bash
bash -n scripts/root/dev-all.sh
pnpm run test:dev-script
cd hybird-meumall
pnpm test src/server/http/backend-registry.test.ts src/server/http/backend-client.test.ts src/server/http/bff-context.test.ts src/features/home/home-real-api.test.ts
pnpm typecheck
```

## 发布影响

- 是否需要发布：否，本次仅配置、脚本和文档收敛。
- 发布项目：无。
- 是否影响 manifest：否。
- 是否需要灰度：否。
- 回滚目标：回退本次配置文件和启动脚本变更。
- smoke check：用 `pnpm dev:h5` 或 `H5_ENV=local pnpm dev` 启动后访问 `/hybird`，确认 BFF 不再缺失 `JAVA_API_BASE_URL`。

## 风险和阻塞

- `h5.prod.env` 当前按要求暂时指向测试 H5 域名和测试后端，不能作为正式生产域名已经完成的信号。
- 已运行中的 Next dev server 不会自动刷新环境变量，切换配置后必须重启 H5 dev server。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-11 | in_progress | 创建环境配置收敛任务，按用户确认域名开始实现。 |
| 2026-06-11 | verified | 已完成三套环境 profile、启动脚本、文档同步和验证记录。 |

## 验证记录

```bash
node -e "JSON.parse(require('fs').readFileSync('package.json','utf8')); JSON.parse(require('fs').readFileSync('hybird-meumall/package.json','utf8')); console.log('package json ok')"
bash -n scripts/root/dev-all.sh
pnpm run test:dev-script
cd hybird-meumall
pnpm test src/server/http/backend-registry.test.ts src/server/http/backend-client.test.ts src/server/http/bff-context.test.ts src/features/home/home-real-api.test.ts
pnpm typecheck
pnpm lint
cd ..
pnpm run check
```

结果：

- package JSON 解析：通过。
- `bash -n scripts/root/dev-all.sh`：通过。
- `pnpm run test:dev-script`：通过。
- H5 目标测试：通过，4 files / 12 tests。
- `pnpm typecheck`：通过。
- `pnpm lint`：通过，存在 4 条历史 `<img>` warning，无 error。
- 根目录 `pnpm run check`：通过。
