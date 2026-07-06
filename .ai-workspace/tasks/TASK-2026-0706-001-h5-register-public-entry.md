# TASK-2026-0706-001 H5 注册公开固定入口

## 状态

implemented

## 目标

为运营二维码提供稳定注册入口 `https://hybird.aigcpop.com/register`，避免二维码直接绑定 `/h5-v/<version>/register` 后因 H5 版本容器下线或升级导致失效。

## 背景

注册页已经在 H5 项目中开发并完成基础联调。当前 H5 发布采用多版本容器，真实页面地址形如 `https://hybird.aigcpop.com/h5-v/v1.0.28/register`。运营二维码需要长期稳定，不应随 H5 版本号变化。

## 涉及项目

- Node register resolver：提供公开固定入口解析。
- `hybird-meumall`：继续承载 `/register` 页面和版本化发布。
- 运维/nginx：需要将公网 `/register` 转发到 Node register resolver。

## 范围

- 新增独立 Node resolver 的 `GET /register` public entry。
- public entry 基于 Java H5 版本管理 active manifest 拼接当前 H5 版本注册页。
- 保留二维码 URL 中的运营 query 参数；测试和正式环境通过域名与部署实例区分，不使用 `environment` query。
- Jenkins 发版时同步并启动 resolver 容器，Nginx 精确代理公网 `/register`。
- 更新根级契约、对接说明、H5 发版文档和项目文档。
- 同步到飞书知识库。

## 不包含

- 不拆分新的 `register-h5` 独立容器。
- 不改变 H5 注册页业务表单、AES 加密、短信验证码或认证流程。
- 不改变 App 内登录/注册策略；App 内仍不展示注册入口。
- 不新增数据库 schema。
- 不要求 Java 服务新增 `/register` 跳转接口。

## 责任边界

- Node register resolver：按环境配置的 `JAVA_H5_RELEASE_API_BASE_URL` 请求 Java `GET /platform/h5Release/active`，校验 active 版本声明 `/register` 路由，返回 302。
- `hybird-meumall`：确保发版 manifest routes 包含 `/register`，页面在版本 basePath 下可访问。
- 运维/nginx：公网域名 `/register` 转发到 Node resolver，`/h5-v/<version>/` 继续转发到对应 H5 版本容器。
- 运营：二维码固定使用 `https://hybird.aigcpop.com/register`，不直接使用版本化 URL。

## 契约影响

- 契约文档：`.ai-workspace/contracts/api/h5-register-public-entry-contract.md`
- 向后兼容：是。新增公开入口，不改变原 `/api/h5/manifest/active` 和 H5 版本路径。
- 是否需要迁移：否。
- 是否需要灰度：入口可先在测试域验证，active manifest 切回旧版本即可回滚。

## 对接说明

- 对接说明：`.ai-workspace/integration-briefs/BRIEF-2026-0706-001-h5-register-public-entry.md`
- 需要确认角色：运维、H5 发版负责人、运营、Java H5 版本管理接口负责人。
- 对方事项：nginx 代理、二维码投放口径、active manifest 包含 `/register`，Java active manifest endpoint 可访问。

## 对方责任

- 运维确认 `GET /register` 的公网代理目标为 Node resolver。
- H5 发版确认注册页所在版本容器持续运行且 manifest 已声明 `/register`。
- 运营确认二维码只使用固定入口。

## Mock 和联调方式

- Mock：无。
- 联调环境：测试域名 `https://hybird.aigcpop.com/register`。
- 联调步骤：
  1. 发布包含 `/register` route 的 H5 candidate。
  2. 将该 release promote 为 active。
  3. 访问 `/register?utm=qr`，确认 302 到 active 版本 `/h5-v/<version>/register?utm=qr`。
  4. 完成注册页真实接口联调。

## 验收标准

- [x] `GET /register` 在 active manifest 包含 `/register` 时返回 302。
- [x] 目标地址等于 `assets.serviceBaseUrl + assets.basePath + /register`。
- [x] `/register` 不接收 `environment` query，测试和正式环境通过域名与部署实例区分。
- [x] 运营 query 参数被保留。
- [x] active manifest 未声明 `/register` 时返回 404。
- [x] 不修改 H5 注册页业务逻辑。
- [x] 更新 H5、根级契约和发版文档。
- [x] 飞书知识库完成同步并回写链接。

## 验证命令

```bash
cd /Users/mac/person_code/meu-mall
bash -n scripts/deploy/h5-version-deploy.sh
bash -n scripts/deploy/h5-jenkins-release.sh
node --check scripts/register-resolver/server.js
node scripts/register-resolver/test.js
```

## 发布影响

- Jenkins 发版会同步并启动 `meu-mall-register-resolver` 容器，默认监听 `127.0.0.1:4110`。
- Nginx 模板新增公网 `/register` 精确代理，避免落到默认 H5 3109。
- H5 发版脚本自动发现路由时必须包含 `/register`，否则 public entry 会返回 404，阻止跳到不存在页面。
- 回滚 active manifest 后，固定入口会自动指向回滚版本的 `/register`。

## 风险和阻塞

- 如果当前 active H5 版本未包含注册页，二维码入口会 404；上线前必须先发布并激活包含 `/register` 的版本。
- 如果 nginx 未将 `/register` 转发到 Node resolver，公网入口不可用。
- 如果 Java active manifest endpoint 或 `JAVA_H5_RELEASE_API_BASE_URL` 配置错误，resolver 返回 502。

## 变更记录

- 2026-07-06：创建工作项；早期 `server-meumall` public entry 方案已被独立 Node resolver 方案取代。
- 2026-07-06：同步飞书知识库：
  - 规则页：https://v05ctaei9gn.feishu.cn/wiki/P8bGwOGHuiW2elkUWBUcfiFpnQh，创建 revision 3，回写后 revision 4。
  - 页面盘点：https://v05ctaei9gn.feishu.cn/wiki/WgaqwTRRUitnRNkCtNPcOcDnnre，更新至 revision 70。
  - H5 发版流程：https://v05ctaei9gn.feishu.cn/wiki/HyBpwTbNUigKsOkO2Qgc2rjBnie，更新至 revision 6。
- 2026-07-06：按最新确认移除 `/register` 的 `environment` query 口径，测试/正式环境改由域名与部署实例区分。
- 2026-07-06：同步飞书规则页最新口径，规则页 revision 更新至 6。
- 2026-07-06：按最新确认改为独立 Node resolver，不要求 Java 或 `server-meumall` 新增 `/register`；resolver 读取环境配置的 Java H5 版本管理前缀，并调用不带 `environment` query 的 `GET /platform/h5Release/active`。
- 2026-07-06：同步飞书知识库 Node resolver 口径：
  - 规则页：https://v05ctaei9gn.feishu.cn/wiki/P8bGwOGHuiW2elkUWBUcfiFpnQh，revision 11。
  - 页面盘点：https://v05ctaei9gn.feishu.cn/wiki/WgaqwTRRUitnRNkCtNPcOcDnnre，revision 73。
  - H5 发版流程：https://v05ctaei9gn.feishu.cn/wiki/HyBpwTbNUigKsOkO2Qgc2rjBnie，revision 7。
