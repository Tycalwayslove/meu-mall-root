# TASK-2026-0612-009 H5 商品详情富文本内容渲染

## 状态

verified

## 目标

完善 `hybird-meumall` 商品详情页的详情内容展示：后端 `/prod/prodInfo` 返回的 `content` 是富文本 HTML 字符串，H5 需要通过社区组件方案解析为 React 节点，并对图片相对路径、危险标签和危险属性做安全处理。

## 背景

商品详情真实接口首批接入后，`content` 当前只被去标签后当纯文本展示，导致商品详情图片、段落、列表等富文本内容无法展示。旧 uni-app 迁移向导明确商品详情富文本来自 `data.content`，并需要处理富文本图片展示。

用户已确认：商品详情里的数据从 `content` 中获取，找社区可解析插件处理，最好封装为组件。

## 涉及项目

- `hybird-meumall`

## 范围

包含：

- 引入社区 HTML 富文本解析/清洗依赖。
- 新增商品详情富文本组件。
- 将 `/prod/prodInfo.content` 映射为可渲染富文本片段。
- 对富文本中的相对图片地址按 `JAVA_OSS_ASSET_BASE_URL` 拼接。
- 清除 `script`、事件属性、危险协议等不安全内容。
- 保留当前普通商品 + 快递 + SKU + 立即购买范围。
- 补充测试、文档和验证记录。

不包含：

- 秒杀、拼团、自提、同城。
- 商品参数弹层、证书弹层、优惠券弹层、评论接口。
- 正式下单和支付。
- 后端接口改造。

## 责任边界

`hybird-meumall`：

- 负责富文本解析、清洗、图片地址归一和页面展示。
- 负责不让浏览器端直接请求 Java 后端或读取 token。

后端：

- 继续返回现有 `content` 字段。
- 不需要为本任务新增接口。

原生 App：

- 无新增依赖。

管理后台：

- 无新增依赖。

## 契约影响

- 是否影响跨项目契约：是，补充 `content` 渲染处理规则。
- 契约文档路径：`.ai-workspace/contracts/api/h5-product-detail-real-flow-contract.md`
- 是否向后兼容：是。
- 是否需要迁移：否。
- 是否需要灰度：随 H5 常规灰度。

## 对接说明

- 是否需要对接说明：复用 `.ai-workspace/integration-briefs/BRIEF-2026-0611-008-h5-product-detail-real-flow.md`。
- 需要确认的角色：后端 / QA。
- 当前确认状态：H5 侧先按现有 `content` 字段兼容实现；如后端富文本标签范围变化，更新契约。

## 对方责任

后端：

- 保持 `content` 为商品详情富文本 HTML 字符串。
- 避免在富文本中依赖 H5 不允许的脚本、iframe 或事件属性。

原生 App：

- 无。

管理后台：

- 无。

## Mock 和联调方式

- Mock 数据位置：`hybird-meumall/src/features/product/product-real-flow.test.tsx` 内的商品 fixture。
- 测试接口环境：`JAVA_API_BASE_URL=https://test.aigcpop.com/mini_h5`。
- 联调步骤：
  1. 打开 `/hybird/product/1000054`。
  2. 检查详情区能展示 `content` 中的段落和图片。
  3. 检查相对图片地址已拼接 OSS base URL。
  4. 检查危险标签和事件属性不会进入渲染结果。

## 验收标准

- [x] `content` 富文本中的段落、列表、图片能在商品详情页展示。
- [x] `content` 图片相对路径按 `JAVA_OSS_ASSET_BASE_URL` 拼接。
- [x] `script`、`onclick`、`javascript:` 等危险内容被移除。
- [x] `content` 缺失时仍展示当前详情兜底，不白屏。
- [x] 新增组件有测试覆盖。
- [x] `pnpm test`、`pnpm typecheck`、`pnpm lint`、`pnpm run build` 通过或限制已记录。

## 验证命令

```bash
cd /Users/mac/person_code/meu-mall/hybird-meumall
pnpm exec vitest run src/features/product/product-rich-content.test.tsx src/features/product/product-real-flow.test.tsx
pnpm test
pnpm typecheck
pnpm lint
pnpm run build
```

## 发布影响

- 是否需要发布：需要随 H5 常规发版。
- 发布项目：`hybird-meumall`。
- 是否需要灰度：建议按 H5 常规灰度。
- 回滚目标：回滚到本任务前商品详情纯文本详情区。
- smoke check：打开 `/hybird/product/1000054`，确认商品详情区展示富文本内容。

## 风险和阻塞

- 后端富文本如果依赖脚本、iframe 或复杂内联样式，H5 会按安全白名单清理，可能与旧小程序展示不完全一致。
- 真实接口成功态仍依赖有效 `mallToken`。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-12 | ready | 用户确认商品详情数据从 `content` 富文本中解析展示，H5 使用社区插件封装组件。 |
| 2026-06-12 | verified | 已完成 `ProductRichContent` 组件、富文本清洗/解析、详情区接入、文档和验证记录。 |

## 验证结果

验证记录：`hybird-meumall/.ai/test-reports/2026-06-12-product-rich-content.md`

```bash
cd /Users/mac/person_code/meu-mall/hybird-meumall
pnpm exec vitest run src/features/product/product-rich-content.test.tsx src/features/product/product-real-flow.test.tsx
pnpm test
pnpm typecheck
pnpm lint
pnpm run build
```

结果：

- `product-rich-content + product-real-flow`：2 files / 11 tests 通过。
- 全量测试：43 files / 214 tests 通过。
- TypeScript：通过。
- ESLint：0 errors，4 warnings；warning 均为 promotion 模块既有 `<img>` 规则提示，不属于本次商品富文本改造。
- Next build：通过。

## 已知限制

- 真实商品 `content` 最终展示效果仍需要 App 注入有效 `mallToken` 后在测试环境端上确认。
- 出于安全边界，H5 不允许富文本中的 `script`、`iframe`、事件属性和危险协议；如运营内容依赖这类能力，需后续重新评估契约。
