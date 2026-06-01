# H5 缓存契约

## 契约名称

H5 Cache Contract

## 提供方

- `hybird-meumall`：页面缓存策略、客户端快照、Service Worker 边界。
- `server-meumall` 或未来业务服务：API cache header、数据一致性语义。
- `app-meumall`：原生离线兜底、Native cache、登录态变化通知。
- CDN 或部署平台：静态资源和公共内容缓存。

## 消费方

- `hybird-meumall`
- `app-meumall`
- `meumall-ci`

## 核心原则

```text
公共内容：允许缓存。
用户私有内容：默认不共享缓存。
交易数据：永远实时确认。
静态资源：尽量长缓存。
HTML：谨慎缓存。
Service Worker：只做增强，不做唯一兜底。
Native 资源包：只缓存静态资源，不缓存服务端代码。
```

优先级：

```text
安全边界 > 数据一致性 > 可回滚 > 用户体验 > 性能优化 > 实现复杂度
```

## 静态资源缓存

`/_next/static/*` 应视为可长缓存资源。

要求：

- 使用内容 hash 或 buildId 管理版本。
- 可以上传 CDN。
- 可以进入 App 本地静态资源包。
- 本地未命中时允许回退到 CDN。
- 不应人为改成短缓存，除非任务明确说明原因。

`assetPrefix` 只能用于 Next.js 静态资源域名，不应用作全站 URL 重写。

## HTML 缓存

- 公共 HTML 可以短缓存或 ISR。
- 用户私有 HTML 不得共享缓存。
- 交易类 HTML 不得离线承诺。
- SSR 私有页面必须使用 `no-store` 或等价策略。

## Service Worker 边界

Service Worker 是增强能力，不是 Hybrid App 唯一离线方案。

允许缓存：

- `offline.html`
- `/_next/static/*`
- 图片和字体。
- 公共 API 的 network-first fallback。
- 公共页面导航失败后的 fallback。

禁止缓存：

- token 或身份凭证。
- 购物车真实数据接口。
- 订单接口。
- 支付接口。
- 地址接口。
- 权限判定接口。
- 任何强一致数据。

推荐策略：

| 请求类型 | 策略 |
| --- | --- |
| `/sw.js` | no-store |
| `/offline.html` | precache |
| `/_next/static/*` | cache-first |
| 图片和字体 | cache-first 或 stale-while-revalidate |
| public API | network-first with timeout |
| private API | bypass |
| 公共页面导航 | network-first，失败时 fallback |
| 私有页面导航 | 不缓存 HTML，失败时展示离线提示 |

## API 缓存分类

### Public API

示例：首页配置、分类树、活动基础信息、帮助文档、商品基础信息。

规则：

- 可以短缓存。
- 可以使用 CDN 或服务端缓存。
- 可以写入 IndexedDB。
- 可以被 Service Worker 缓存。
- 必须有明确 TTL。

### Semi-public API

示例：搜索结果、商品列表、推荐商品、活动商品列表。

规则：

- 可以短缓存。
- 不应混入用户敏感数据。
- 若包含价格或库存，只能作为展示参考。

### Private API

示例：购物车、我的页面、订单、地址、优惠券、会员信息。

规则：

- 必须 no-store 或等价策略。
- 不得被 CDN 缓存。
- 不得被 Service Worker Cache 缓存。
- 可以保存弱快照，但 UI 必须标记为缓存数据。
- 退出登录时必须清理。

### Transactional API

示例：下单、支付、库存锁定、价格确认、优惠券核销、地址提交。

规则：

- 必须 no-store。
- 必须实时请求。
- 失败时阻止继续交易。
- 不得使用缓存结果继续交易。

## 登录态清理

登录成功时：

- 通知相关 WebView。
- 刷新购物车、我的和用户相关模块。
- 更新原生 tab badge。

退出登录时：

- 清理用户私有 IndexedDB 缓存。
- 清理购物车快照。
- 清理我的页面弱摘要。
- 清理用户相关内存状态。
- 通知所有相关 WebView。

切换账号视为退出旧账号后登录新账号。

## 验收要求

涉及 H5 缓存的工作项必须验证：

- 私有接口不会被共享缓存。
- 交易类接口不会读取缓存继续流程。
- 缓存快照有 UI 标识。
- 退出登录清理用户私有缓存。
- 弱网不会长时间白屏。
- 无网有离线兜底。
