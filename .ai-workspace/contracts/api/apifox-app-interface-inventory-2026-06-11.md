# Apifox APP 接口清单快照

## 基本信息

- 来源：Apifox
- 项目 ID：`4403987`
- 项目名称：`喵呜AI`
- 团队 ID：`2525564`
- 目标目录：`喵呜商城/APP接口`
- 目标目录 ID：`87569790`
- 读取日期：`2026-06-11`
- 状态：`inventory`

## 说明

本文件只记录当前从 Apifox 读取到的 APP 接口清单，作为后续 H5 HTTP 架构、BFF service、API 契约和联调任务的输入材料。

当前后端接口仍不完整，本文件不是已确认 API 契约，不能直接作为实现完成标准。正式接入前仍需要补齐：

- 请求参数。
- 响应 schema。
- 错误码。
- 鉴权要求。
- 缓存策略。
- 分页规则。
- 空状态和异常状态。
- 与 H5 页面模型的字段映射。

## 读取命令

```bash
apifox project get 4403987 --access-token "$APIFOX_TOKEN"
apifox folder list --project 4403987 --type endpoint --access-token "$APIFOX_TOKEN"
apifox endpoint list --project 4403987 --folder-id <folderId> --access-token "$APIFOX_TOKEN"
apifox endpoint get <endpointId> --project 4403987 --access-token "$APIFOX_TOKEN"
apifox schema get <schemaId> --project 4403987 --access-token "$APIFOX_TOKEN"
```

## 目录结构

| 目录 | folderId |
| --- | --- |
| `喵呜商城/APP接口` | `87569790` |
| `喵呜商城/APP接口/喵呜达人首页接口` | `87570137` |
| `喵呜商城/APP接口/达人等级接口` | `87722410` |
| `喵呜商城/APP接口/达人主页接口` | `87978834` |
| `喵呜商城/APP接口/分销员收入接口` | `87992717` |
| `喵呜商城/APP接口/达人激励活动接口` | `88000566` |
| `喵呜商城/APP接口/达人推广排行榜接口` | `88001139` |

## 接口清单

| 分组 | endpointId | 方法 | 路径 | 名称 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 喵呜达人首页接口 | `468539323` | GET | `/p/app/home/index` | 首页聚合数据 | released |
| 喵呜达人首页接口 | `468539324` | GET | `/p/app/home/recommendProds` | 首页推荐商品分页 | released |
| 喵呜达人首页接口 | `469157763` | GET | `/p/app/home/forYouProds` | 为您推荐商品分页 | released |
| 达人等级接口 | `470107706` | GET | `/p/daren/level/myLevel` | 查询我的达人等级 | released |
| 达人等级接口 | `470107707` | GET | `/p/daren/level/list` | 达人等级列表 | released |
| 达人主页接口 | `470727778` | POST | `/p/distribution/home/reportVisit` | 上报达人店铺访问 | released |
| 达人主页接口 | `470727779` | POST | `/p/distribution/home/favoriteShop` | 收藏达人店铺 | released |
| 达人主页接口 | `470727780` | POST | `/p/distribution/home/cancelFavoriteShop` | 取消收藏达人店铺 | released |
| 达人主页接口 | `470727781` | GET | `/p/distribution/home/isFavoriteShop` | 是否已收藏达人店铺 | released |
| 达人主页接口 | `470834898` | GET | `/p/distribution/home/overview` | 推广页概览 | released |
| 分销员收入接口 | `470804575` | GET | `/p/distribution/income/myPromotionOrder` | 我的推广订单 | released |
| 分销员收入接口 | `470805383` | GET | `/p/distribution/income/summary` | 推广收益汇总 | released |
| 达人激励活动接口 | `470846666` | GET | `/p/distribution/incentive/center` | 激励活动中心 | released |
| 达人激励活动接口 | `470846667` | GET | `/p/distribution/incentive/detail/{id}` | 激励活动详情 | released |
| 达人激励活动接口 | `470846668` | GET | `/p/distribution/incentive/myReward/page` | 我的激励获奖记录 | released |
| 达人激励活动接口 | `470846669` | GET | `/p/distribution/incentive/reward/detail/{rewardId}` | 激励奖励详情 | released |
| 达人激励活动接口 | `470846670` | POST | `/p/distribution/incentive/reward/receivePhysical` | 领取实物奖励 | released |
| 达人推广排行榜接口 | `470849886` | GET | `/p/distribution/rank/list` | 推广排行榜 | released |
| 达人推广排行榜接口 | `470849887` | GET | `/p/distribution/rank/myReport` | 我的排行榜战报 | released |
| 达人推广排行榜接口 | `471480490` | GET | `/p/distribution/rank/battleReport` | 我的推广战报 | released |

## 已验证详情读取

接口 `468539323`（首页聚合数据）已验证可通过 `apifox endpoint get` 读取详情。响应 `200` 引用 schema：

```text
#/definitions/281593898
```

schema `281593898` 已验证可通过 `apifox schema get` 读取，名称为：

```text
ServerResponseEntityAppHomeVO
```

## 后续整理建议

1. 按页面域建立 H5 BFF service 草案：`home`、`promotion`、`talent-level`、`income`、`incentive`、`rank`。
2. 为每个 Apifox endpoint 拉取详情和响应 schema，整理字段映射表。
3. 对比现有 H5 mock model，标出字段缺口、命名差异、数据类型差异。
4. 补根级 API 契约，状态保持 `draft`，等后端确认后再进入 `ready`。
5. 真实接入时通过 H5 BFF 转发，不让浏览器端直接持有 token 调后端。
