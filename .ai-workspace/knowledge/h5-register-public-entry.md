# H5 注册公开入口与二维码投放规则

## 结论

运营二维码固定使用：

```text
https://hybird.aigcpop.com/register
```

不要把下面这种版本化地址投放给用户：

```text
https://hybird.aigcpop.com/h5-v/v1.0.28/register
```

原因是 H5 采用多版本容器发布，`/h5-v/<version>` 会随发版、回滚和容器保留策略变化；二维码必须保持长期稳定。

## 入口解析规则

独立 Node resolver 提供 `GET /register`：

1. 按当前 H5 环境配置读取 `JAVA_H5_RELEASE_API_BASE_URL`。
2. 调用 Java `GET /platform/h5Release/active`，不拼接 `environment` query。
3. 确认 active manifest 中声明了 `/register` route。
4. 按 `assets.serviceBaseUrl + assets.basePath + routes["/register"].path` 拼出当前 H5 版本注册页。
5. 返回 302 跳转。
6. 保留运营 query 参数；测试和正式环境通过域名区分，不在 URL 中拼接 `environment`。

示例：

```text
GET https://hybird.aigcpop.com/register?utm=qr
302 https://hybird.aigcpop.com/h5-v/v1.0.28/register?utm=qr
```

## 职责边界

| 角色 | 责任 |
| --- | --- |
| 运营 | 二维码只投放固定入口 `/register` |
| Jenkins/CI | 部署并启动 `meu-mall-register-resolver` Node 容器 |
| 运维/nginx | 将公网 `/register` 转发到 Node resolver |
| Node resolver | 查询 Java active manifest 并 302 到当前注册页 |
| Java H5 版本管理 | 提供不带 `environment` query 的 active manifest 接口 |
| hybird-meumall | 确保 H5 版本内存在 `/register` 页面，发版 manifest 包含该 route |
| 发布负责人 | 先激活包含 `/register` 的版本，再对外投放二维码 |

## 产品边界

喵呜 App 内仍只有登录，没有 App 内注册入口。本规则只用于运营外部注册 H5，是私域用户引入链路的例外入口。

## 验收

- active manifest 包含 `/register` 时，`GET /register` 返回 302。
- 302 Location 指向当前 active H5 版本的 `/register`。
- active manifest 未声明 `/register` 时，`GET /register` 返回 404。
- active manifest 回滚后，固定入口自动指向回滚版本。

## 飞书同步记录

- 目标知识库：新款app开发资料 / 前端知识库
- 同步日期：2026-07-06
- 飞书链接：https://v05ctaei9gn.feishu.cn/wiki/P8bGwOGHuiW2elkUWBUcfiFpnQh
- docx token：`IdfNdKMJUoQyfmxptZIcY8zynOd`
- wiki node token：`P8bGwOGHuiW2elkUWBUcfiFpnQh`
- 创建 revision：3
- 同步记录回写后 revision：4
- 2026-07-06 二次更新：移除 `/register` 的 `environment` query 口径，最新 revision：6
- 2026-07-06 三次更新：实现改为独立 Node resolver 容器；规则页同步至 revision 11，页面盘点同步至 revision 73，H5 发版流程同步至 revision 7。
