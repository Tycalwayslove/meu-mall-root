# H5 HTTP 请求架构与线上定位方案

## 文档目的

这份文档用于一次技术宣讲：我们为什么要重新梳理 H5 的 HTTP 请求体系，以及为什么要把 `requestId`、BFF、后端透传和日志定位作为一整套能力来设计。

这不是为了把架构做复杂。恰恰相反，它是为了让后续联调、上线和排查问题更简单。接口会越来越多，后端也还在补齐。如果现在让页面直接调用后端接口，短期看起来最快，但一旦线上出现问题，我们会很难判断问题到底在页面、BFF、后端、鉴权、网络还是接口契约。

所以这套方案的核心目标是：

```text
页面少知道一点，链路多记录一点，问题定位快一点。
```

## 当前背景

喵呜 H5 运行在原生 App WebView 中。登录在原生 App 完成，H5 通过 Cookie 从 App 获得登录态。后端目前主要分为 Java / mall 服务和 Python 服务，不同后端使用不同 token。

当前 H5 已经有一个基础方向：

```text
浏览器端 H5
  -> H5 BFF
  -> Java / Python 后端
```

也就是说，浏览器端页面不直接持有 token，也不直接请求 Java / Python 后端。浏览器只请求 H5 自己的 `/api/bff/**`。H5 BFF 在服务端读取 Cookie，然后转成后端需要的 `Authorization: Bearer <token>`。

这个方向是对的。接下来要做的是把它从“能请求”升级为“可治理、可联调、可定位、可演进”。

## 本次架构变化

这次落地不是单纯给请求加几个 header，而是把 H5 的请求链路从“能跑的 BFF 请求”整理成一套固定的工程结构。

变化一：页面不再直接拼 BFF 路径。

过去页面里可以直接出现类似 `/api/bff/runtime/context` 的路径。短期很方便，但接口一多，路径、query 参数和返回类型会散在各个组件里。现在新增了 feature API adapter：

```text
页面组件
  -> features/<domain>/api.ts
  -> createH5Client()
  -> /api/bff/**
```

首页 Runtime 面板已经迁移到 `src/features/home/runtime-api.ts`，推广模块也新增了 `src/features/promotion/api.ts`。后续搜索、秒杀、商品、订单等模块接真实接口时，也应优先建立自己的 adapter。

变化二：H5 client 从“发请求”升级为“请求入口”。

`createH5Client()` 现在统一负责：

- 生成 `x-request-id`。
- 带上页面会话 `x-page-session-id`。
- 带上 App / 系统 / 设备 / WebView 上下文。
- 保留 `credentials: "include"`，让 Cookie 登录态继续只走服务端。
- 记录最近请求、最近失败 requestId 和诊断快照。

这意味着页面不需要每次自己考虑 requestId 怎么生成、设备信息怎么传、失败时怎么留线索。

变化三：BFF route 有了统一上下文入口。

新增 `createBffRequestContext(request)` 后，BFF route 不再重复写读取 Cookie、读取 header、创建 backend client、取 Java/Python token 这些样板代码。route 只需要表达这次要调哪个后端、哪个路径、是否需要鉴权。

这样做的好处是，后续新增 BFF route 时，不容易漏掉客户端上下文、`user-agent` 透传和 backend call logger。

变化四：后端调用日志变成结构化事件。

backend client 不只返回请求结果，还可以输出安全的 backend call log。日志里有 requestId、backend、path、status、duration、错误码、App 版本、系统版本和设备型号，但不包含 token、完整 Cookie 或个人敏感信息。

这让线上排查从“看截图猜”变成“拿 requestId 查链路”。如果后端也按同一套 requestId 打日志，H5、BFF、Java、Python 就能串成一条线。

变化五：技术文档和任务状态同步进入可执行状态。

本次同时补齐了：

- Apifox APP 接口清单本地留档。
- H5 BFF HTTP 鉴权契约。
- H5 API 规范。
- ADR 决策记录。
- 根级任务和 H5 项目验证报告。

换句话说，这套架构不是只停在聊天或想法里，已经有代码入口、测试、验证记录和团队宣讲材料。

## 我们为什么不让页面直接调后端

页面直接调后端，看起来少了一层，但会带来几个长期问题。

第一，token 会进入浏览器端逻辑。H5 在 WebView 里运行，环境复杂，页面代码不应该读取、拼接、打印或持久化 token。登录态应该停留在 HttpOnly Cookie 和 H5 服务端。

第二，后端接口还没完全稳定。Apifox 里现在能看到一批 APP 接口，但参数、响应、错误码、分页、缓存策略和字段语义都还要继续补。如果页面直接消费后端原始字段，后端每变一次，页面就要跟着抖。

第三，线上问题不好定位。页面报错时，我们需要知道后端原始响应是什么，H5 BFF 有没有转错，mapper 有没有把字段转错，页面有没有误判状态。如果没有中间层，所有问题都会混在一起。

第四，后续会出现多个后端。Java、Python、release server、可能的推荐服务、活动服务和配置服务，不应该把这些差异散落在页面组件里。

因此，我们保留 BFF，不是为了“多绕一层”，而是为了把复杂度收在服务端边界里。

## 目标请求架构

建议的整体链路如下：

```text
页面组件
  -> feature api / query adapter
  -> H5 BFF route
  -> server domain service
  -> backend gateway / backend client
  -> Java / Python 后端
```

每一层只做自己该做的事。

当前 H5 代码已经把这条链路拆成了几个固定入口：

| 层级 | 当前落点 | 说明 |
| --- | --- | --- |
| 页面组件 | `src/features/**` | 只处理渲染、交互和页面状态。 |
| feature api | `src/features/home/runtime-api.ts`、`src/features/promotion/api.ts` | 统一收口 BFF path 和 query 参数，组件不直接拼接口路径。 |
| H5 client | `src/lib/http/h5-client.ts` | 生成 `x-request-id`，注入客户端上下文，记录最近请求诊断。 |
| 请求诊断 | `src/lib/http/request-diagnostics.ts` | 维护 `pageSessionId`、最近请求、最近失败 requestId 和可复制诊断快照。 |
| BFF context | `src/server/http/bff-context.ts` | 从请求里读取 Cookie auth、客户端上下文，并创建带日志的 backend client。 |
| backend client | `src/server/http/backend-client.ts` | 请求 Java / Python，透传 `user-agent`、`x-request-id` 和设备上下文，输出结构化 backend call log。 |

后续接新接口时，不要从组件里直接写 `fetch("/api/bff/...")`。推荐顺序是：先在对应 `features/<domain>/api.ts` 增加方法，再让 BFF route 调 server service，最后由 server service 通过 backend client 请求真实后端。

### 页面组件

页面组件只关心页面展示和交互状态。它不应该知道真实后端路径，也不应该知道接口来自 Java 还是 Python。

页面需要的应该是稳定的 H5 页面模型，比如：

```text
HomePageData
PromotionHomeData
TalentLevelData
RankListData
IncentiveActivityData
```

这类模型服务于 H5 页面，而不是照搬后端表结构或接口字段。

### feature api / query adapter

这一层给页面提供明确的方法，例如：

```text
getPromotionHome()
getRankList()
getTalentLevel()
favoriteShop()
```

页面通过这些方法请求数据，而不是在组件里手写 `/api/bff/...`。这样后续换接口、改分页、加缓存、加重试时，不需要改一堆页面。

现在已有两个样板：

```text
createRuntimeApi(client).getNativeRuntimeContext()
createPromotionApi(client).getHome()
createPromotionApi(client).getRanking("sales", { period: "week" })
```

这个模式的价值不是多包一层函数，而是把“业务想要什么”和“接口怎么拼”分开。页面只说我要榜单，adapter 决定它走哪个 BFF path、query 怎么编码、返回什么 H5 页面模型。

### H5 BFF route

BFF route 是浏览器请求进入服务端的入口。它负责：

- 读取 query / body。
- 做基础参数校验。
- 读取 Cookie 登录态。
- 生成或接收 `requestId`。
- 调用 server domain service。
- 返回统一 BFF 响应。

BFF route 不应该堆业务转换逻辑。复杂逻辑应该下沉到 server domain service。

BFF route 里优先使用 `createBffRequestContext(request)`，不要每个 route 自己重复读取 Cookie、解析客户端 header、创建 backend client。这样我们才能保证每个接口都用同一套 requestId、鉴权和日志规则。

### server domain service

这是后续真实接口接入的关键层。

它负责把“后端接口模型”转换成“H5 页面模型”。后端字段可以叫 `prodName`，H5 可以叫 `title`；后端状态可以是数字，H5 可以转成枚举；后端空字段可以在这里给安全默认值。

线上定位时，这一层也很重要。我们可以清楚地区分：

```text
后端原始响应不对 -> 后端或契约问题
后端响应对，但转换后不对 -> H5 mapper 问题
转换后数据对，但页面展示不对 -> 前端页面问题
```

### backend gateway / backend client

backend client 负责真正请求 Java / Python 后端。它应该集中处理：

- backend 选择。
- base URL。
- Authorization。
- timeout。
- requestId 透传。
- 客户端上下文透传。
- 后端 HTTP 状态。
- 网络错误。
- 响应解析。
- 日志记录。

页面和业务 service 不应该自己拼后端 base URL。

## 请求头要带客户端上下文

线上问题不一定只和接口有关，也可能和手机型号、系统版本、App 版本或 WebView 容器有关。比如某个 iOS 版本的 WebView Cookie 行为异常，某个 Android 机型的系统 WebView 太旧，某个 App 版本漏写了 Cookie。这些问题如果没有客户端上下文，排查时只能靠用户描述，很难准。

所以请求链路里除了 `requestId`，还应该带一组客户端上下文 header。

第一类是标准 `User-Agent`。它应该保留浏览器或 WebView 的基础 UA 信息，不要被 H5 随意覆盖。基础 UA 里通常能看到系统、WebKit、浏览器内核和部分设备信息。

第二类是我们自己定义的稳定 header。UA 字符串不适合承载所有业务信息，也不稳定。App 相关信息、设备型号和系统版本建议用明确字段传递：

```http
user-agent: <WebView 原始 User-Agent + App 标识片段>
x-request-id: req-xxxx
x-page-session-id: page-xxxx
x-h5-version: 1.2.0
x-h5-route: /promotion
x-app-name: MeuMall
x-app-version: 1.0.0
x-app-build: 100
x-platform: ios
x-os-version: 18.5
x-device-model: iPhone16,2
x-webview-version: 617.1.17
```

这里有一个取舍：`User-Agent` 适合给网关、后端和日志系统做通用识别，但不要把所有信息都塞进 UA。我们自己的 `x-*` header 更适合做精确筛选，比如“只看 iOS 18.5 + App 1.0.0 + iPhone16,2 的失败请求”。

这些 header 不应该包含手机号、用户姓名、token、定位、完整地址或其它隐私信息。设备型号、系统版本和 App 版本属于排障上下文，足够帮助我们判断问题是否和终端环境有关。

最终目标是：线上反馈一个 `requestId` 后，我们不仅能知道接口哪里失败，还能知道它发生在哪个 App 版本、哪个系统版本、哪类设备上。

## 统一响应结构

浏览器端收到的 BFF 响应建议保持统一：

```ts
type H5BffResult<T> =
  | {
      success: true;
      data: T;
      requestId: string;
    }
  | {
      success: false;
      code: string;
      message: string;
      requestId?: string;
      recoverable: boolean;
    };
```

页面可以根据 `success` 判断展示成功态还是失败态。失败时，页面不需要理解所有后端细节，但必须能拿到 `requestId`。

## 线上为什么必须有 requestId

线上问题最怕一句话：

```text
用户说页面坏了，但我们不知道是哪一次请求坏了。
```

`requestId` 的作用就是给每一次请求一张“身份证”。它要从 H5 页面进入 BFF，再从 BFF 进入 Java / Python 后端，最后出现在每一层日志里。

理想链路是：

```text
H5 client 生成 x-request-id
  -> 请求 H5 BFF

H5 BFF 接收 x-request-id
  -> 写 BFF access log
  -> 请求 Java / Python 时继续带 x-request-id 和客户端上下文

Java / Python 接收 x-request-id 和客户端上下文
  -> 写入服务端日志上下文
  -> 调下游时继续透传
  -> 响应 header 里 echo x-request-id

H5 BFF 收到后端响应
  -> 记录 backend、path、status、duration、requestId
  -> 返回给 H5 页面

H5 页面失败时
  -> 展示或可复制 requestId
```

这样用户反馈一个追踪号，我们就能沿着链路查：

```text
这个 requestId 是否到达 H5 BFF？
H5 BFF 调了哪个后端？
后端返回了什么状态？
耗时是多少？
出问题的设备型号、系统版本和 App 版本是什么？
有没有鉴权失败？
mapper 有没有报错？
页面拿到的最终数据是什么？
```

这比“看截图猜原因”可靠得多。

H5 侧还会在内存里保留最近 10 次请求记录。这个记录不是长期日志，也不包含 token；它的作用是当用户在错误页、客服入口或调试面板里提交反馈时，H5 可以把最近失败的 `requestId`、当前路由、App 版本、系统版本和设备型号一起带上。这样即使用户没有手动复制 requestId，我们也还有机会从反馈里拿到线索。

## 线上怎么拿到 requestId

不要指望线上用户打开浏览器 Network 面板。requestId 必须进入用户能反馈、系统能收集的地方。

建议放在三个位置。

第一，放在响应 header：

```http
x-request-id: req-xxxx
```

这方便研发和网关日志排查。

第二，放在 BFF JSON：

```json
{
  "success": false,
  "code": "TIMEOUT",
  "message": "请求超时，请稍后重试",
  "requestId": "req-xxxx",
  "recoverable": true
}
```

这方便页面拿到并展示。

第三，放在页面错误态或诊断信息里。

测试包可以直接展示：

```text
加载失败，请稍后重试
错误码：TIMEOUT
追踪号：req-xxxx
```

正式包可以弱化展示，例如：

```text
加载失败，请稍后重试
问题编号：req-xxxx
```

也可以放到“复制诊断信息”里。用户点一下，就复制：

```json
{
  "requestId": "req-xxxx",
  "route": "/promotion",
  "h5Version": "1.2.0",
  "appName": "MeuMall",
  "appVersion": "1.0.0",
  "appBuild": "100",
  "platform": "ios",
  "osVersion": "18.5",
  "deviceModel": "iPhone16,2"
}
```

对普通用户来说，它只是问题编号。对研发来说，它是入口。

## 不只要 requestId，还要 pageSessionId

有些线上问题不是单个接口失败，而是“页面数据怪”“状态跳错”“刚才点完收藏后列表没变”。这种问题只看一个 requestId 不够。

建议 H5 在页面生命周期里维护一个 `pageSessionId`：

```text
用户进入某个 H5 页面 -> 生成 pageSessionId
页面内所有请求 -> 同时带 requestId 和 pageSessionId
```

两者分工不同：

| 标识 | 用途 |
| --- | --- |
| `requestId` | 定位某一次请求。 |
| `pageSessionId` | 串起一次页面访问里的多次请求和交互。 |
| `traceId` | 后续接入 OpenTelemetry 时做分布式链路追踪。 |

第一阶段可以先做 `requestId`。第二阶段再补 `pageSessionId`，用于用户反馈和前端埋点。

## Java 和 Python 需要怎么配合

Java 和 Python 不需要一开始就接入复杂的观测平台。第一阶段只要做到五件事：

```text
接收 x-request-id
接收客户端上下文 header
日志打印 x-request-id
调用下游时透传 x-request-id
响应时返回 x-request-id
```

### Java 侧建议

Java 服务可以用 Filter 或 Interceptor 读取请求头：

```http
x-request-id: req-xxxx
```

如果请求没有带，就生成一个新的。然后把它放进 MDC，让这一条请求里的日志自动带上 requestId。

日志效果应该类似：

```text
requestId=req-xxxx method=GET path=/p/app/home/index status=200 duration=84ms appVersion=1.0.0 platform=ios osVersion=18.5 deviceModel=iPhone16,2
```

如果 Java 服务再调用其他服务，也继续把 `x-request-id` 带下去。客户端上下文是否继续透传给更下游，可以按隐私和日志成本决定；至少 Java 自己的入口日志里要记录。

### Python 侧建议

Python FastAPI 可以用 middleware 读取请求头：

```http
x-request-id: req-xxxx
```

如果没有，就生成一个新的。然后放到 request state 或 contextvar，日志格式里统一输出。

日志效果应该类似：

```text
request_id=req-xxxx method=GET path=/xxx status=200 duration=84ms app_version=1.0.0 platform=ios os_version=18.5 device_model=iPhone16,2
```

如果 Python 服务再调用下游，也继续透传 `x-request-id`。客户端上下文至少要写在入口日志里，方便按设备和版本聚合问题。

## 后端不适配会怎样

如果 Java / Python 暂时不适配，H5 这边仍然可以先做一半：

```text
H5 页面 -> H5 BFF -> 后端
```

H5 BFF 可以记录：

- requestId。
- H5 route。
- User-Agent。
- App 名称和版本。
- 设备型号。
- 系统版本。
- backend。
- backend path。
- HTTP status。
- duration。
- timeout。
- 返回体摘要。

这样至少能判断问题在 H5 BFF 之前还是之后。

但如果后端日志没有 requestId，我们查到后端时就会断掉，只能靠时间、用户、路径和状态码模糊匹配。这个效率会低很多。

所以后端适配不是“锦上添花”。它决定线上排查能不能从 H5 一路查到后端。

## 错误码怎么设计

错误码要能帮助我们快速分层，不要把所有失败都叫“系统异常”。

建议第一阶段至少区分：

| code | 含义 | 通常归因 |
| --- | --- | --- |
| `TOKEN_MISSING` | H5 BFF 没拿到 token。 | App Cookie / 登录态 / H5 鉴权读取 |
| `AUTH_FAILED` | 后端返回 401 / 403。 | token 过期 / 后端鉴权 |
| `VALIDATION_ERROR` | BFF 参数校验失败。 | H5 调用参数 / 页面逻辑 |
| `BACKEND_ERROR` | 后端返回业务错误或 5xx。 | 后端业务或服务异常 |
| `MAPPER_ERROR` | 后端响应无法映射成 H5 页面模型。 | 契约不一致 / H5 mapper |
| `NETWORK_ERROR` | 网络请求失败。 | 网络 / 网关 / 域名 / 服务不可达 |
| `TIMEOUT` | 请求超时。 | 后端慢 / 网络慢 / 超时配置 |
| `PARSE_ERROR` | 响应体无法解析。 | 后端响应格式 / 网关异常 |

页面展示文案可以很温和，但日志里的 code 必须具体。

## 日志应该记录什么

日志不是越多越好。我们要记录能定位问题的信息，同时避免泄露敏感数据。

H5 BFF access log 建议记录：

```text
requestId
pageSessionId
route
bffPath
method
status
duration
userAgent
h5Version
appName
appVersion
appBuild
platform
osVersion
deviceModel
webviewVersion
```

后端调用日志建议记录：

```text
requestId
backend
backendPath
backendMethod
backendStatus
duration
errorCode
timeoutMs
appVersion
platform
osVersion
deviceModel
```

mapper 错误日志建议记录：

```text
requestId
mapperName
missingFields
invalidFields
backendPath
schemaVersion
```

不要记录：

```text
token
手机号
身份证
完整地址
支付敏感信息
完整 Cookie
```

调试阶段可以在受控环境里看更多信息，但正式环境必须脱敏。

## 线上排查流程

当用户反馈问题时，我们希望排查路径是固定的。

```text
1. 拿到问题编号 requestId。
2. 查 H5 BFF 日志。
3. 看 BFF 是否收到请求。
4. 看 BFF 是否调用后端。
5. 看后端路径、状态码和耗时。
6. 看问题是否集中在某个 App 版本、系统版本或设备型号。
7. 查 Java / Python 同 requestId 日志。
8. 判断后端原始响应是否正确。
9. 如果后端正确，查 H5 mapper 日志。
10. 如果 mapper 正确，查页面错误日志和用户操作路径。
```

这套流程的好处是，每一步都能排除一层。排查不会从“大家一起猜”开始，而是从事实开始。

## 对团队的收益

对 H5 来说，收益是页面更稳定。页面拿到的是 H5 自己的领域模型，不跟后端字段强绑定。后端接口变化时，优先改 server service 和 mapper。

对后端来说，收益是联调更清楚。H5 发来的每次请求都有 requestId、route、h5Version、appVersion、platform、deviceModel 和 appEnv。后端能知道是哪一个 H5 版本、哪一个 App 版本、哪一种设备、哪一个页面、哪一次请求出了问题。

对测试来说，收益是 bug 更容易复现和归因。测试反馈时只要带上问题编号、页面、操作步骤，研发就能查到链路。

对产品和客服来说，收益是沟通成本更低。用户不用描述一大堆技术细节，只要提供截图或问题编号。

对项目整体来说，收益是后续接口越来越多时，不会变成不可维护的“页面直连接口网”。我们把复杂度放在该放的地方，系统会更耐改。

## 分阶段落地建议

### 第一阶段：先打通 requestId

目标：

- H5 client 生成或传递 `x-request-id`。
- H5 client / BFF 透传 `User-Agent` 和客户端上下文 header。
- BFF 响应体返回 `requestId`。
- BFF 调后端继续透传 `x-request-id`。
- BFF 记录 access log 和 backend call log。
- 页面错误态能展示或复制 requestId。

这一阶段就能明显提升排查效率。

### 第二阶段：补齐后端适配

目标：

- Java 接收、记录、透传、返回 `x-request-id`。
- Python 接收、记录、透传、返回 `x-request-id`。
- Java / Python 入口日志记录 App 版本、系统版本和设备型号。
- 后端日志平台可以按 requestId 搜索。
- 后端日志平台可以按 appVersion、platform、osVersion、deviceModel 聚合问题。

这一阶段让链路从 H5 查到后端。

### 第三阶段：建立页面诊断信息

目标：

- H5 维护 `pageSessionId`。
- H5 保存最近 N 次请求的轻量记录。
- 用户反馈时自动带上 route、h5Version、appVersion、platform、requestId。

这一阶段解决“页面状态怪，但不是单次接口失败”的问题。

### 第四阶段：接入标准链路追踪

目标：

- 引入 `traceparent`。
- Java / Python 接入 OpenTelemetry。
- 日志、trace 和错误平台能关联。

这一阶段适合在基础链路稳定后再做，不建议一开始就把目标定太大。

## 当前接口清单的位置

当前从 Apifox 读取到的 APP 接口清单已经保存到：

```text
.ai-workspace/contracts/api/apifox-app-interface-inventory-2026-06-11.md
```

它只是接口清单快照，不是正式 API 契约。后续每个业务域进入真实接入前，都需要继续补：

- Apifox endpoint 详情。
- schema 详情。
- H5 页面模型。
- 字段映射表。
- 错误码。
- 缓存策略。
- 验收方式。

## 结论

这套 HTTP 架构的目的，不是追求形式完整，而是解决真实问题：

```text
接口不稳定时，页面不要跟着乱。
线上出问题时，团队不要靠猜。
后端补接口时，H5 不要大面积返工。
联调出分歧时，大家能看同一条链路证据。
```

先把 BFF、领域模型、requestId 和日志边界做好，后续无论接口怎么补，系统都会更容易接、更容易查、更容易维护。
