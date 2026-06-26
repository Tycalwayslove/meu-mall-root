# H5 商品分类列表真实接口契约

## 基本信息

- 契约编号：API-2026-0624-003
- 状态：implemented
- 提供方：Java 后端，Apifox 项目 `4403987`
- 消费方：`hybird-meumall`
- 适用环境：test / prod
- 关联页面：`/category`

## Apifox 来源

- 项目：`4403987`
- 分支：`main`
- 标签：`分类接口`

| 名称 | Method | Java Path | H5 BFF |
| --- | --- | --- | --- |
| 获取分类列表 | GET | `/category/list` | `/api/bff/category/list` |

## 鉴权

H5 BFF 从 `mallToken` Cookie 读取 Java token，并按当前联调口径发送：

```http
Authorization: <mallToken>
```

## 请求

```http
GET /category/list?parentId=-1&shopId=0&depth=3
```

Query：

| 字段 | 类型 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `parentId` | integer | 是 | `-1` | 父级分类 ID，`-1` 表示基础分类级别，即一级分类。 |
| `shopId` | integer | 是 | `0` | 店铺 ID，平台为 `0`。 |
| `depth` | integer | 是 | `3` | 分类深度，含起始层；当前分类页固定传 `3`，一次取一级、二级、三级分类。 |

Apifox 说明：`grade=0` 时仅允许平台查询（`shopId=0`）；一级分类只有平台才能查询。当前 Java 联调口径要求 `depth` 必传，H5 分类页固定传 `3`。

## Java 响应

```ts
type ServerResponseEntityCategoryListTreeVOArray = {
  code?: string;
  msg?: string;
  data?: CategoryListTreeVO[] | null;
  version?: string;
  timestamp?: number;
  sign?: string;
  success?: boolean;
};

type CategoryListTreeVO = {
  categoryId?: number;
  shopId?: number;
  baseCategoryId?: number;
  parentId?: number;
  categoryName?: string;
  icon?: string;
  pic?: string;
  seq?: number;
  deductionRate?: number;
  status?: number;
  recTime?: string;
  grade?: number;
  updateTime?: string;
  actualDeductionRate?: number;
  children?: CategoryListTreeVO[];
};
```

## H5 BFF 响应

```ts
type CategoryListBffData = {
  view: CategoryPageData;
  modules: {
    categories: CategoryListTreeVO[];
  };
  debugRaw?: {
    categoryList: ServerResponseEntityCategoryListTreeVOArray;
  };
};

type CategoryPageData = {
  activeCategoryId: string;
  primaryCategories: Array<{
    id: string;
    label: string;
  }>;
  categorySectionsByPrimaryId: Record<string, Array<{
    id: string;
    title: string;
    items: Array<{
      id: string;
      label: string;
      href: string;
      imageUrl?: string;
    }>;
  }>>;
};
```

映射规则：

- 一级分类来自 Java 顶层 `data[]`。
- 右侧 section 使用一级分类的 `children[]` 作为二级分类。
- 二级分类的 `children[]` 映射为三级分类宫格；如没有三级分类，则将二级分类自身作为可点击 leaf。
- `status=0` 的分类不进入视图。
- 分类按 `seq` 升序展示。
- leaf 点击进入 `/search?categoryId=<categoryId>`。
- `pic` / `icon` 相对路径通过 `JAVA_OSS_ASSET_BASE_URL` 拼接，完整 URL 原样保留。

## H5 渲染策略

- `/category` 首屏展示骨架屏，不渲染本地 mock 分类。
- BFF 成功后只展示真实分类树。
- Java 返回空数组时展示通用空态“暂无分类”。
- BFF 失败时展示“分类加载失败”，不回退 mock。

## 测试方式

- `src/features/category/category-real-api.test.ts` 覆盖 Java path、字段映射、排序、图片拼接和空数组不 fallback。
- `src/app/category/page.test.tsx` 覆盖 `/category` 首屏骨架和不渲染 mock 分类。

## 回滚方式

H5 可回滚到上一版 active manifest；当前联调阶段不使用本地 mock 分类兜底。
