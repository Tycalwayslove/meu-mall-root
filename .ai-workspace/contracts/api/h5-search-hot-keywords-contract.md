# H5 搜索热门词真实接口契约

## 基本信息

- 契约编号：API-2026-0624-002
- 状态：implemented
- 提供方：Java 后端，Apifox 项目 `4403987`
- 消费方：`hybird-meumall`
- 适用环境：test / prod
- 关联页面：`/search`

## Apifox 来源

- 项目：`4403987`
- 分支：`main`
- 目录：`喵呜商城/APP接口/搜索接口`

| 名称 | Method | Java Path | H5 BFF |
| --- | --- | --- | --- |
| 查看全局热搜 | GET | `/search/hotSearch` | `/api/bff/search/hot-keywords` |

## 鉴权

H5 BFF 从 `mallToken` Cookie 读取 Java token，并按当前联调口径发送：

```http
Authorization: <mallToken>
```

## 请求

```http
GET /search/hotSearch?type=1
```

Query：

| 字段 | 类型 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `type` | integer | 否 | `1` | 热搜类型，`1` 商品，`2` 店铺。搜索首页当前使用商品热词。 |

## Java 响应

```ts
type ServerResponseEntityHotSearchDtoArray = {
  code?: string;
  msg?: string;
  data?: HotSearchDto[] | null;
  version?: string;
  timestamp?: number;
  sign?: string;
  success?: boolean;
};

type HotSearchDto = {
  hotSearchId?: number;
  title?: string;
  content?: string;
  status?: number;
  type?: number;
  seq?: number;
  shopId?: number;
  jumpType?: number;
  jumpValue?: string;
};
```

Apifox 描述：APP 搜索热词来自后台 `tz_hot_search` 配置，合计最多 7 条；`type=2` 店铺热词不插入热榜条目，最多返回 7 条店铺热词。

## H5 BFF 响应

```ts
type SearchHotKeywordsBffData = {
  view: {
    hotKeywords: string[];
  };
  modules: {
    hotSearches: HotSearchDto[];
  };
  debugRaw?: {
    hotSearch: ServerResponseEntityHotSearchDtoArray;
  };
};
```

映射规则：

- `view.hotKeywords` 优先取 `title`，缺失时取 `content`。
- `status=0` 的热词不进入视图。
- 按 `seq` 升序展示，缺失 `seq` 时保留原相对顺序。
- 空标题或空内容不进入视图。
- 最多展示 7 条。

## H5 渲染策略

- `/search` 首屏热门搜索区域先展示骨架屏。
- BFF 成功后只展示真实热词。
- Java 返回空数组时展示“暂无热门搜索”，不拼接本地 mock 热词。
- BFF 失败时展示“热门搜索加载失败”，不回退 mock。
- 搜索历史仅保存在前端 localStorage，key 为 `meumall.search.history`；提交搜索或点击热词会写入本地历史，支持清空全部历史和单条删除指定关键词。

## 测试方式

- `src/features/search/search-real-api.test.ts` 覆盖 Java path、字段映射、空数组不 fallback。
- `src/features/search/search-history.test.ts` 覆盖本地历史写入、去重、上限、清空、单条删除和坏数据兜底。
- `src/features/search/search.test.tsx` 覆盖热门词骨架和搜索历史空态。

## 回滚方式

H5 可回滚到上一版 active manifest；当前联调阶段不使用本地 mock 热词兜底。
