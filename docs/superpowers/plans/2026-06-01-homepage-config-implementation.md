# 首页配置生产化 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建立首页配置的后端发布、管理端配置和 H5 消费闭环。

**Architecture:** `server-meumall` 新增独立首页配置表和 API；`admin-meumall` 新增内容配置视图和结构化编辑；`hybird-meumall` 把首页从静态数据改为配置驱动，并保留静态兜底。根目录契约 `.ai-workspace/contracts/homepage-config-contract.md` 是三端共同标准。

**Tech Stack:** FastAPI + Pydantic + SQLite + pytest；React + Vite + TypeScript + Vitest；Next.js App Router + React + Tailwind + Vitest。

---

## Files And Responsibilities

### Root

- Modify: `.ai-workspace/tasks/TASK-2026-0601-001-homepage-config.md`  
  记录实现进度、验证结果和最终状态。

### Server

- Modify: `server-meumall/app/main.py`  
  新增首页配置模型、校验、SQLite 表、CRUD、发布和 H5 active 接口。
- Modify: `server-meumall/tests/test_api.py`  
  覆盖首页配置创建、更新、删除、发布、active 唯一、H5 查询、非法配置。

### Admin

- Modify: `admin-meumall/src/lib/configApi.ts`  
  新增首页配置类型、API 方法、normalize 方法。
- Modify: `admin-meumall/src/lib/configApi.test.ts`  
  覆盖首页配置 API URL、payload 和字段归一化。
- Create: `admin-meumall/src/features/home-config/homeConfigDefaults.ts`  
  管理端首页配置默认值和 helper。
- Create: `admin-meumall/src/features/home-config/HomeConfigPage.tsx`  
  首页配置列表、编辑、保存草稿、发布和删除草稿页面。
- Modify: `admin-meumall/src/App.tsx`  
  加入“发布控制 / 内容配置”导航，并挂载首页配置页面。

### H5

- Modify: `hybird-meumall/src/app/page.tsx`  
  改为渲染 `HomeScreen`。
- Create: `hybird-meumall/src/features/home/types.ts`  
  首页配置、模块、事件和页面状态类型。
- Create: `hybird-meumall/src/features/home/default-config.ts`  
  静态兜底配置，保留当前首页主要结构。
- Create: `hybird-meumall/src/features/home/api.ts`  
  获取 active 首页配置，校验模块结构，处理 timeout。
- Create: `hybird-meumall/src/features/home/home-cache.ts`  
  浏览器短缓存读写和 stale 判断。
- Create: `hybird-meumall/src/features/home/HomeSkeleton.tsx`  
  首页骨架屏。
- Create: `hybird-meumall/src/features/home/HomeModules.tsx`  
  banner、分类、活动和推荐区域渲染。
- Create: `hybird-meumall/src/features/home/HomeScreen.tsx`  
  加载流程：骨架屏、远端配置、缓存兜底、静态兜底。
- Create: `hybird-meumall/src/features/home/home.test.tsx`  
  覆盖加载、成功、失败兜底和模块渲染。

---

## Task 1: Server Tests For Homepage Config API

**Files:**
- Modify: `server-meumall/tests/test_api.py`

- [ ] **Step 1: Add homepage config fixture**

Add this helper near `make_manifest`:

```python
def make_home_config(config_version: str = "2026.06.01-001") -> dict:
    return {
        "schemaVersion": "1.0",
        "pageId": "home",
        "configVersion": config_version,
        "generatedAt": "2026-06-01T00:00:00Z",
        "cache": {
            "ttlSeconds": 300,
            "staleWhileRevalidateSeconds": 1800,
        },
        "performance": {
            "requestTimeoutMs": 4000,
            "skeletonMinMs": 200,
            "preloadImageCount": 1,
            "lcpCandidateModuleId": "home-banner",
            "telemetrySampleRate": 1,
        },
        "modules": [
            {
                "id": "home-banner",
                "type": "banner_carousel",
                "enabled": True,
                "sortOrder": 10,
                "items": [
                    {
                        "id": "banner-1",
                        "title": "会员日",
                        "imageUrl": "https://cdn.example.com/banner.png",
                        "alt": "会员日活动",
                        "event": {
                            "type": "h5_route",
                            "target": "/promotion",
                            "params": {"source": "home_banner"},
                        },
                        "trackingId": "home_banner_member_day",
                        "priority": True,
                        "enabled": True,
                        "sortOrder": 10,
                    }
                ],
            },
            {
                "id": "home-category",
                "type": "category_grid",
                "enabled": True,
                "sortOrder": 20,
                "columns": 5,
                "rows": 2,
                "items": [
                    {
                        "id": "cat-hot",
                        "name": "热门商品",
                        "iconUrl": "https://cdn.example.com/hot.png",
                        "event": {
                            "type": "h5_route",
                            "target": "/category",
                            "params": {"categoryId": "hot"},
                        },
                        "enabled": True,
                        "sortOrder": 10,
                    }
                ],
            },
        ],
    }
```

- [ ] **Step 2: Add failing CRUD and publish tests**

Append these tests:

```python
def test_home_config_crud_and_publish(tmp_path):
    api = client(tmp_path)
    home_config = make_home_config()

    create_response = api.post(
        "/api/home/configs",
        json={
            "name": "首页生产配置",
            "environment": "prod",
            "configVersion": home_config["configVersion"],
            "config": home_config,
            "source": "admin",
            "createdBy": "codex",
            "notes": "first home config",
        },
    )

    assert create_response.status_code == 201
    created = create_response.json()
    assert created["name"] == "首页生产配置"
    assert created["status"] == "draft"
    assert created["config"] == home_config

    update_response = api.put(
        f"/api/home/configs/{created['id']}",
        json={
            "name": "首页生产配置 v2",
            "notes": "updated",
            "config": {
                **home_config,
                "configVersion": "2026.06.01-002",
            },
        },
    )

    assert update_response.status_code == 200
    assert update_response.json()["name"] == "首页生产配置 v2"
    assert update_response.json()["configVersion"] == "2026.06.01-002"

    publish_response = api.post(f"/api/home/configs/{created['id']}/publish")
    assert publish_response.status_code == 200
    assert publish_response.json()["status"] == "active"
    assert publish_response.json()["published_at"] is not None

    active_response = api.get("/api/h5/home/config/active?environment=prod")
    assert active_response.status_code == 200
    assert active_response.headers["cache-control"] == "no-cache, max-age=0, must-revalidate"
    assert active_response.json()["pageId"] == "home"
    assert active_response.json()["configVersion"] == "2026.06.01-002"
```

- [ ] **Step 3: Add failing active uniqueness and validation tests**

Append these tests:

```python
def test_publishing_home_config_archives_previous_active(tmp_path):
    api = client(tmp_path)
    first = make_home_config("2026.06.01-001")
    second = make_home_config("2026.06.01-002")

    first_created = api.post(
        "/api/home/configs",
        json={"name": "first", "environment": "prod", "config": first},
    ).json()
    api.post(f"/api/home/configs/{first_created['id']}/publish")

    second_created = api.post(
        "/api/home/configs",
        json={"name": "second", "environment": "prod", "config": second},
    ).json()
    api.post(f"/api/home/configs/{second_created['id']}/publish")

    configs = api.get("/api/home/configs?environment=prod").json()["items"]
    active_configs = [item for item in configs if item["status"] == "active"]
    archived_configs = [item for item in configs if item["status"] == "archived"]

    assert [item["id"] for item in active_configs] == [second_created["id"]]
    assert [item["id"] for item in archived_configs] == [first_created["id"]]


def test_home_config_rejects_cart_event_target(tmp_path):
    api = client(tmp_path)
    home_config = make_home_config()
    home_config["modules"][0]["items"][0]["event"]["target"] = "/cart"

    response = api.post(
        "/api/home/configs",
        json={"name": "bad", "environment": "prod", "config": home_config},
    )

    assert response.status_code == 422
    assert "购物车" in response.json()["detail"]


def test_active_home_config_returns_404_when_missing(tmp_path):
    response = client(tmp_path).get("/api/h5/home/config/active?environment=prod")

    assert response.status_code == 404
    assert response.json()["code"] == "HOME_CONFIG_NOT_FOUND"
```

- [ ] **Step 4: Run tests to verify they fail**

Run:

```bash
cd /Users/mac/person_code/meu-mall/server-meumall
pytest tests/test_api.py -k "home_config" -v
```

Expected: FAIL with 404 or missing route errors for `/api/home/configs`.

---

## Task 2: Server Homepage Config Implementation

**Files:**
- Modify: `server-meumall/app/main.py`
- Modify: `server-meumall/tests/test_api.py`

- [ ] **Step 1: Add Pydantic models**

Add near existing request models:

```python
HomeConfigStatus = Literal["draft", "active", "archived"]


class HomePageConfig(BaseModel):
    model_config = ConfigDict(extra="allow")

    schemaVersion: Literal["1.0"]
    pageId: Literal["home"]
    configVersion: str = Field(min_length=1)
    generatedAt: str = Field(min_length=1)
    cache: dict[str, Any]
    performance: dict[str, Any] | None = None
    modules: list[dict[str, Any]]


class CreateHomeConfigRequest(BaseModel):
    name: str = Field(min_length=1)
    environment: str = Field(default="prod", min_length=1)
    configVersion: str | None = Field(default=None, min_length=1)
    config: HomePageConfig
    source: str | None = Field(default=None, min_length=1)
    createdBy: str | None = Field(default=None, min_length=1)
    notes: str | None = None


class UpdateHomeConfigRequest(BaseModel):
    name: str | None = Field(default=None, min_length=1)
    environment: str | None = Field(default=None, min_length=1)
    configVersion: str | None = Field(default=None, min_length=1)
    config: HomePageConfig | None = None
    source: str | None = Field(default=None, min_length=1)
    createdBy: str | None = Field(default=None, min_length=1)
    notes: str | None = None
```

- [ ] **Step 2: Add table and migration**

Add functions near `create_manifest_configs_table`:

```python
def create_home_page_configs_table(connection: sqlite3.Connection) -> None:
    connection.execute(
        """
        CREATE TABLE IF NOT EXISTS home_page_configs (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          environment TEXT NOT NULL,
          status TEXT NOT NULL CHECK(status IN ('draft', 'active', 'archived')),
          config_version TEXT NOT NULL,
          config_json TEXT NOT NULL,
          source TEXT,
          created_by TEXT,
          notes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          published_at TEXT
        )
        """
    )
    connection.execute(
        "CREATE INDEX IF NOT EXISTS idx_home_page_configs_env_status_updated ON home_page_configs(environment, status, updated_at)"
    )
    connection.execute(
        """
        CREATE UNIQUE INDEX IF NOT EXISTS idx_home_page_configs_active_environment
        ON home_page_configs(environment)
        WHERE status = 'active'
        """
    )


def migrate_home_page_configs_table(connection: sqlite3.Connection) -> None:
    create_home_page_configs_table(connection)
```

Call `migrate_home_page_configs_table(connection)` in the existing startup database setup next to manifest migration.

- [ ] **Step 3: Add validation helpers**

Add helper functions:

```python
def contains_cart_target(value: Any) -> bool:
    if isinstance(value, dict):
        for key, item in value.items():
            if key == "target" and isinstance(item, str) and item.strip("/").startswith("cart"):
                return True
            if contains_cart_target(item):
                return True
    if isinstance(value, list):
        return any(contains_cart_target(item) for item in value)
    return False


def validate_home_config(config: dict[str, Any]) -> None:
    modules = config.get("modules")
    if not isinstance(modules, list):
        raise HTTPException(status_code=422, detail="首页 modules 必须是数组")

    module_ids: set[str] = set()
    for module in modules:
        if not isinstance(module, dict):
            raise HTTPException(status_code=422, detail="首页模块必须是对象")
        module_id = str(module.get("id") or "")
        if not module_id:
            raise HTTPException(status_code=422, detail="首页模块 id 不能为空")
        if module_id in module_ids:
            raise HTTPException(status_code=422, detail=f"首页模块 id 重复：{module_id}")
        module_ids.add(module_id)

        if module.get("type") == "category_grid":
            columns = int(module.get("columns") or 0)
            rows = int(module.get("rows") or 0)
            if columns < 2 or columns > 5:
                raise HTTPException(status_code=422, detail="分类 columns 必须在 2 到 5 之间")
            if rows < 1 or rows > 3:
                raise HTTPException(status_code=422, detail="分类 rows 必须在 1 到 3 之间")

    if contains_cart_target(config):
        raise HTTPException(status_code=422, detail="首页配置不允许指向购物车")
```

- [ ] **Step 4: Add row helpers**

Add:

```python
def row_to_home_config(row: sqlite3.Row) -> dict[str, Any]:
    return {
        "id": row["id"],
        "name": row["name"],
        "environment": row["environment"],
        "status": row["status"],
        "configVersion": row["config_version"],
        "config": json.loads(row["config_json"]),
        "source": row["source"],
        "created_by": row["created_by"],
        "notes": row["notes"],
        "created_at": row["created_at"],
        "updated_at": row["updated_at"],
        "published_at": row["published_at"],
    }


def get_home_config_or_404(connection: sqlite3.Connection, config_id: str) -> sqlite3.Row:
    row = connection.execute(
        "SELECT * FROM home_page_configs WHERE id = ?",
        (config_id,),
    ).fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Home config not found")
    return row
```

- [ ] **Step 5: Add API routes**

Inside `create_app`, add routes:

```python
    @app.get("/api/home/configs")
    def list_home_configs(
        environment: str | None = Query(default=None),
        status_filter: HomeConfigStatus | None = Query(default=None, alias="status"),
    ) -> dict[str, list[dict[str, Any]]]:
        query = "SELECT * FROM home_page_configs"
        params: list[Any] = []
        filters: list[str] = []
        if environment:
            filters.append("environment = ?")
            params.append(environment)
        if status_filter:
            filters.append("status = ?")
            params.append(status_filter)
        if filters:
            query += " WHERE " + " AND ".join(filters)
        query += " ORDER BY updated_at DESC"
        with connect(database_path) as connection:
            rows = connection.execute(query, params).fetchall()
        return {"items": [row_to_home_config(row) for row in rows]}

    @app.post("/api/home/configs", status_code=status.HTTP_201_CREATED)
    def create_home_config(payload: CreateHomeConfigRequest) -> dict[str, Any]:
        now = utc_now()
        config = payload.config.model_dump(mode="json")
        validate_home_config(config)
        config_version = payload.configVersion or payload.config.configVersion
        config_id = str(uuid4())
        with connect(database_path) as connection:
            connection.execute(
                """
                INSERT INTO home_page_configs (
                  id, name, environment, status, config_version, config_json,
                  source, created_by, notes, created_at, updated_at, published_at
                ) VALUES (?, ?, ?, 'draft', ?, ?, ?, ?, ?, ?, ?, NULL)
                """,
                (
                    config_id,
                    payload.name,
                    payload.environment,
                    config_version,
                    json.dumps(config, ensure_ascii=False),
                    payload.source,
                    payload.createdBy,
                    payload.notes,
                    now,
                    now,
                ),
            )
            row = get_home_config_or_404(connection, config_id)
            connection.commit()
            return row_to_home_config(row)
```

Then add `GET`, `PUT`, `DELETE`, `publish`, and H5 active routes following the same pattern. `PUT` and `DELETE` must reject non-draft rows with `409`. `publish` must archive the current active row for the same environment before setting the selected row active.

- [ ] **Step 6: Run server tests**

Run:

```bash
cd /Users/mac/person_code/meu-mall/server-meumall
pytest tests/test_api.py -k "home_config" -v
pytest
```

Expected: all tests pass.

---

## Task 3: Admin API Types And Tests

**Files:**
- Modify: `admin-meumall/src/lib/configApi.ts`
- Modify: `admin-meumall/src/lib/configApi.test.ts`

- [ ] **Step 1: Add failing API tests**

Append tests in `configApi.test.ts`:

```ts
it('creates and normalizes home configs', async () => {
  vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
    ok: true,
    text: () => Promise.resolve(JSON.stringify({
      id: 'home-1',
      name: '首页配置',
      environment: 'prod',
      status: 'draft',
      config_version: '2026.06.01-001',
      config: { schemaVersion: '1.0', pageId: 'home', configVersion: '2026.06.01-001', generatedAt: '2026-06-01T00:00:00Z', cache: { ttlSeconds: 300 }, modules: [] },
      created_at: '2026-06-01T00:00:00Z',
      updated_at: '2026-06-01T00:00:00Z',
      published_at: null,
    })),
  }));

  const created = await configApi.createHomeConfig({
    name: '首页配置',
    environment: 'prod',
    config: { schemaVersion: '1.0', pageId: 'home', configVersion: '2026.06.01-001', generatedAt: '2026-06-01T00:00:00Z', cache: { ttlSeconds: 300 }, modules: [] },
  });

  expect(fetch).toHaveBeenCalledWith(
    'http://127.0.0.1:4100/api/home/configs',
    expect.objectContaining({ method: 'POST' }),
  );
  expect(created.configVersion).toBe('2026.06.01-001');
  expect(created.updatedAt).toBe('2026-06-01T00:00:00Z');
});
```

- [ ] **Step 2: Run test to verify failure**

Run:

```bash
cd /Users/mac/person_code/meu-mall/admin-meumall
pnpm test -- src/lib/configApi.test.ts
```

Expected: FAIL because `createHomeConfig` is missing.

- [ ] **Step 3: Add types and API methods**

Add to `configApi.ts`:

```ts
export type HomeConfigStatus = 'draft' | 'active' | 'archived';

export interface HomeConfigItem {
  id: string;
  name: string;
  environment: string;
  status: HomeConfigStatus;
  configVersion: string;
  config: JsonRecord;
  source?: string | null;
  createdBy?: string | null;
  notes?: string | null;
  createdAt?: string;
  updatedAt?: string;
  publishedAt?: string | null;
}

export interface HomeConfigPayload {
  name: string;
  environment?: string;
  configVersion?: string;
  config: JsonRecord;
  source?: string;
  createdBy?: string;
  notes?: string;
}

function normalizeHomeConfig(item: HomeConfigItem & {
  config_version?: string;
  created_by?: string | null;
  created_at?: string;
  updated_at?: string;
  published_at?: string | null;
}): HomeConfigItem {
  return {
    ...item,
    configVersion: item.configVersion || item.config_version || '',
    createdBy: item.createdBy ?? item.created_by,
    createdAt: item.createdAt || item.created_at,
    updatedAt: item.updatedAt || item.updated_at,
    publishedAt: item.publishedAt ?? item.published_at,
  };
}
```

Add methods to `configApi`:

```ts
  listHomeConfigs: async (environment = 'prod') =>
    (
      await request<{ items: HomeConfigItem[] }>(
        `/api/home/configs?environment=${encodeURIComponent(environment)}`,
      )
    ).items.map(normalizeHomeConfig),
  createHomeConfig: (payload: HomeConfigPayload) =>
    request<HomeConfigItem>('/api/home/configs', {
      method: 'POST',
      body: JSON.stringify(payload),
    }).then(normalizeHomeConfig),
  updateHomeConfig: (id: string, payload: Partial<HomeConfigPayload>) =>
    request<HomeConfigItem>(`/api/home/configs/${encodeURIComponent(id)}`, {
      method: 'PUT',
      body: JSON.stringify(payload),
    }).then(normalizeHomeConfig),
  deleteHomeConfig: (id: string) =>
    request<{ ok?: boolean }>(`/api/home/configs/${encodeURIComponent(id)}`, {
      method: 'DELETE',
    }),
  publishHomeConfig: (id: string) =>
    request<HomeConfigItem>(`/api/home/configs/${encodeURIComponent(id)}/publish`, {
      method: 'POST',
    }).then(normalizeHomeConfig),
  getActiveHomeConfig: (environment: string) =>
    request<JsonRecord>(
      `/api/h5/home/config/active?environment=${encodeURIComponent(environment)}`,
    ),
```

- [ ] **Step 4: Run API tests**

Run:

```bash
cd /Users/mac/person_code/meu-mall/admin-meumall
pnpm test -- src/lib/configApi.test.ts
```

Expected: PASS.

---

## Task 4: Admin Home Config Page

**Files:**
- Create: `admin-meumall/src/features/home-config/homeConfigDefaults.ts`
- Create: `admin-meumall/src/features/home-config/HomeConfigPage.tsx`
- Modify: `admin-meumall/src/App.tsx`

- [ ] **Step 1: Add default config helper**

Create `homeConfigDefaults.ts`:

```ts
import { JsonRecord } from '../../lib/configApi';

export function createDefaultHomeConfig(): JsonRecord {
  return {
    schemaVersion: '1.0',
    pageId: 'home',
    configVersion: new Date().toISOString().slice(0, 10).replaceAll('-', '.') + '-001',
    generatedAt: new Date().toISOString(),
    cache: {
      ttlSeconds: 300,
      staleWhileRevalidateSeconds: 1800,
    },
    performance: {
      requestTimeoutMs: 4000,
      skeletonMinMs: 200,
      preloadImageCount: 1,
      lcpCandidateModuleId: 'home-banner',
      telemetrySampleRate: 1,
    },
    modules: [
      {
        id: 'home-banner',
        type: 'banner_carousel',
        enabled: true,
        sortOrder: 10,
        items: [],
      },
      {
        id: 'home-category',
        type: 'category_grid',
        enabled: true,
        sortOrder: 20,
        columns: 5,
        rows: 2,
        items: [],
      },
      {
        id: 'home-activity',
        type: 'activity_section',
        enabled: true,
        sortOrder: 30,
        title: '限时活动',
        displayMode: 'card_grid',
        items: [],
      },
    ],
  };
}
```

- [ ] **Step 2: Implement page with structured JSON editor baseline**

Create `HomeConfigPage.tsx`. First version may use structured sections plus JSON textarea for the config body, but the UI must expose banner、分类、活动区域 headers and save/publish actions.

```tsx
import { FormEvent, useEffect, useState } from 'react';

import { HomeConfigItem, configApi, formatManifestJson, parseManifestJson } from '../../lib/configApi';
import { createDefaultHomeConfig } from './homeConfigDefaults';

export function HomeConfigPage() {
  const [environment, setEnvironment] = useState('prod');
  const [configs, setConfigs] = useState<HomeConfigItem[]>([]);
  const [selectedId, setSelectedId] = useState('');
  const [name, setName] = useState('首页配置');
  const [notes, setNotes] = useState('');
  const [configText, setConfigText] = useState(formatManifestJson(createDefaultHomeConfig()));
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');

  async function loadConfigs(nextEnvironment = environment) {
    setLoading(true);
    setError('');
    try {
      const items = await configApi.listHomeConfigs(nextEnvironment);
      setConfigs(items);
      const first = items[0];
      if (first) {
        setSelectedId(first.id);
        setName(first.name);
        setNotes(first.notes || '');
        setConfigText(formatManifestJson(first.config));
      }
    } catch (nextError) {
      setError(nextError instanceof Error ? nextError.message : '加载首页配置失败');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void loadConfigs(environment);
  }, [environment]);

  async function handleSave(event: FormEvent) {
    event.preventDefault();
    setSaving(true);
    setError('');
    setMessage('');
    try {
      const config = parseManifestJson(configText);
      const payload = { name, environment, notes, config, source: 'admin' };
      const saved = selectedId
        ? await configApi.updateHomeConfig(selectedId, payload)
        : await configApi.createHomeConfig(payload);
      setSelectedId(saved.id);
      setMessage('首页配置草稿已保存');
      await loadConfigs(environment);
    } catch (nextError) {
      setError(nextError instanceof Error ? nextError.message : '保存首页配置失败');
    } finally {
      setSaving(false);
    }
  }

  async function handlePublish() {
    if (!selectedId) return;
    setSaving(true);
    setError('');
    try {
      await configApi.publishHomeConfig(selectedId);
      setMessage('首页配置已发布');
      await loadConfigs(environment);
    } catch (nextError) {
      setError(nextError instanceof Error ? nextError.message : '发布首页配置失败');
    } finally {
      setSaving(false);
    }
  }

  return (
    <section className="panel">
      <div className="panel__header">
        <div>
          <p className="eyebrow">内容配置</p>
          <h2>首页配置</h2>
        </div>
        <select value={environment} onChange={(event) => setEnvironment(event.target.value)}>
          <option value="dev">dev</option>
          <option value="staging">staging</option>
          <option value="prod">prod</option>
        </select>
      </div>
      <form onSubmit={handleSave} className="editor-grid">
        <aside className="config-list">
          <button type="button" onClick={() => {
            setSelectedId('');
            setName('首页配置');
            setNotes('');
            setConfigText(formatManifestJson(createDefaultHomeConfig()));
          }}>新建草稿</button>
          {loading ? <p>加载中...</p> : configs.map((item) => (
            <button key={item.id} type="button" onClick={() => {
              setSelectedId(item.id);
              setName(item.name);
              setNotes(item.notes || '');
              setConfigText(formatManifestJson(item.config));
            }}>
              {item.name} · {item.status}
            </button>
          ))}
        </aside>
        <div className="editor-main">
          <input value={name} onChange={(event) => setName(event.target.value)} placeholder="配置名称" />
          <input value={notes} onChange={(event) => setNotes(event.target.value)} placeholder="备注" />
          <div className="module-outline">
            <strong>Banner 模块</strong>
            <strong>分类入口模块</strong>
            <strong>活动模块</strong>
          </div>
          <textarea value={configText} onChange={(event) => setConfigText(event.target.value)} rows={22} />
          {message ? <p className="success">{message}</p> : null}
          {error ? <p className="error">{error}</p> : null}
          <div className="actions">
            <button type="submit" disabled={saving}>{saving ? '保存中...' : '保存草稿'}</button>
            <button type="button" disabled={saving || !selectedId} onClick={handlePublish}>发布</button>
          </div>
        </div>
      </form>
    </section>
  );
}
```

- [ ] **Step 3: Wire navigation in App**

In `App.tsx`, import `HomeConfigPage`, add `currentView` state with values `'release' | 'manifest' | 'home-config'`, and render `HomeConfigPage` when selected. Keep existing release/manifest behavior intact.

- [ ] **Step 4: Run admin checks**

Run:

```bash
cd /Users/mac/person_code/meu-mall/admin-meumall
pnpm test
pnpm typecheck
pnpm build
```

Expected: all pass.

---

## Task 5: H5 Home Feature Tests

**Files:**
- Create: `hybird-meumall/src/features/home/home.test.tsx`

- [ ] **Step 1: Add tests for cache and rendering**

Create the test file:

```tsx
import { render, screen, waitFor } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';

import { HomeScreen } from './HomeScreen';

const config = {
  schemaVersion: '1.0',
  pageId: 'home',
  configVersion: '2026.06.01-001',
  generatedAt: '2026-06-01T00:00:00Z',
  cache: { ttlSeconds: 300, staleWhileRevalidateSeconds: 1800 },
  performance: { requestTimeoutMs: 4000, skeletonMinMs: 0, preloadImageCount: 1 },
  modules: [
    {
      id: 'home-banner',
      type: 'banner_carousel',
      enabled: true,
      sortOrder: 10,
      items: [{ id: 'banner-1', title: '会员日', imageUrl: 'https://cdn.example.com/banner.png', enabled: true, sortOrder: 10 }],
    },
    {
      id: 'home-category',
      type: 'category_grid',
      enabled: true,
      sortOrder: 20,
      columns: 5,
      rows: 2,
      items: [{ id: 'cat-hot', name: '热门商品', enabled: true, sortOrder: 10 }],
    },
  ],
};

describe('HomeScreen', () => {
  beforeEach(() => {
    localStorage.clear();
    vi.restoreAllMocks();
  });

  it('shows skeleton first and renders remote config modules', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      ok: true,
      headers: new Headers({ 'content-type': 'application/json' }),
      text: () => Promise.resolve(JSON.stringify(config)),
    }));

    render(<HomeScreen />);

    expect(screen.getByTestId('home-skeleton')).toBeInTheDocument();
    await waitFor(() => expect(screen.getByText('会员日')).toBeInTheDocument());
    expect(screen.getByText('热门商品')).toBeInTheDocument();
  });

  it('uses fallback content when remote config fails without cache', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('network down')));

    render(<HomeScreen />);

    await waitFor(() => expect(screen.getByText('喵呜AI')).toBeInTheDocument());
    expect(screen.getByText('为您推荐')).toBeInTheDocument();
  });
});
```

- [ ] **Step 2: Run test to verify failure**

Run:

```bash
cd /Users/mac/person_code/meu-mall/hybird-meumall
pnpm test -- src/features/home/home.test.tsx
```

Expected: FAIL because `HomeScreen` is missing.

---

## Task 6: H5 Home Config Implementation

**Files:**
- Modify: `hybird-meumall/src/app/page.tsx`
- Create: `hybird-meumall/src/features/home/types.ts`
- Create: `hybird-meumall/src/features/home/default-config.ts`
- Create: `hybird-meumall/src/features/home/api.ts`
- Create: `hybird-meumall/src/features/home/home-cache.ts`
- Create: `hybird-meumall/src/features/home/HomeSkeleton.tsx`
- Create: `hybird-meumall/src/features/home/HomeModules.tsx`
- Create: `hybird-meumall/src/features/home/HomeScreen.tsx`

- [ ] **Step 1: Add core types**

Create `types.ts`:

```ts
export type HomeEventType = 'h5_route' | 'external_url' | 'native_bridge';

export interface HomeEvent {
  type: HomeEventType;
  target: string;
  params?: Record<string, unknown>;
}

export interface HomeConfig {
  schemaVersion: '1.0';
  pageId: 'home';
  configVersion: string;
  generatedAt: string;
  cache: {
    ttlSeconds: number;
    staleWhileRevalidateSeconds?: number;
  };
  performance?: {
    requestTimeoutMs?: number;
    skeletonMinMs?: number;
    preloadImageCount?: number;
    lcpCandidateModuleId?: string;
    telemetrySampleRate?: number;
  };
  modules: HomeModule[];
}

export type HomeModule = BannerModule | CategoryGridModule | ActivitySectionModule;

export interface ModuleBase {
  id: string;
  type: string;
  enabled: boolean;
  sortOrder: number;
}

export interface BannerModule extends ModuleBase {
  type: 'banner_carousel';
  items: BannerItem[];
}

export interface BannerItem {
  id: string;
  title: string;
  imageUrl?: string;
  alt?: string;
  event?: HomeEvent;
  trackingId?: string;
  priority?: boolean;
  enabled: boolean;
  sortOrder: number;
}

export interface CategoryGridModule extends ModuleBase {
  type: 'category_grid';
  columns: number;
  rows: number;
  items: CategoryItem[];
}

export interface CategoryItem {
  id: string;
  name: string;
  iconUrl?: string;
  event?: HomeEvent;
  enabled: boolean;
  sortOrder: number;
}

export interface ActivitySectionModule extends ModuleBase {
  type: 'activity_section';
  title?: string;
  displayMode?: 'card_grid' | 'single_banner';
  items: ActivityItem[];
}

export interface ActivityItem {
  id: string;
  kind?: 'promotion' | 'seckill' | 'custom';
  title: string;
  subtitle?: string;
  imageUrl?: string;
  badge?: string;
  startsAt?: string;
  endsAt?: string;
  event?: HomeEvent;
  enabled: boolean;
  sortOrder: number;
}
```

- [ ] **Step 2: Add cache implementation**

Create `home-cache.ts`:

```ts
import { HomeConfig } from './types';

const KEY_PREFIX = 'meumall:home-config';

interface CacheRecord {
  savedAt: number;
  config: HomeConfig;
}

export function getHomeCacheKey(environment: string, schemaVersion = '1.0') {
  return `${KEY_PREFIX}:${environment}:${schemaVersion}`;
}

export function readCachedHomeConfig(environment: string, now = Date.now()): HomeConfig | null {
  if (typeof window === 'undefined') return null;
  const raw = window.localStorage.getItem(getHomeCacheKey(environment));
  if (!raw) return null;
  try {
    const record = JSON.parse(raw) as CacheRecord;
    const ttl = record.config.cache.ttlSeconds * 1000;
    const stale = (record.config.cache.staleWhileRevalidateSeconds || 0) * 1000;
    if (now - record.savedAt <= ttl + stale) {
      return record.config;
    }
  } catch {
    window.localStorage.removeItem(getHomeCacheKey(environment));
  }
  return null;
}

export function writeCachedHomeConfig(environment: string, config: HomeConfig, now = Date.now()) {
  if (typeof window === 'undefined') return;
  window.localStorage.setItem(
    getHomeCacheKey(environment, config.schemaVersion),
    JSON.stringify({ savedAt: now, config }),
  );
}
```

- [ ] **Step 3: Add API fetcher**

Create `api.ts`:

```ts
import { HomeConfig } from './types';

const DEFAULT_BASE_URL = process.env.NEXT_PUBLIC_CONFIG_API_BASE_URL || 'http://127.0.0.1:4100';

export function isHomeConfig(value: unknown): value is HomeConfig {
  if (!value || typeof value !== 'object') return false;
  const data = value as Partial<HomeConfig>;
  return data.schemaVersion === '1.0' && data.pageId === 'home' && Array.isArray(data.modules);
}

export async function fetchHomeConfig(environment = 'prod', timeoutMs = 4000): Promise<HomeConfig> {
  const controller = new AbortController();
  const timeout = window.setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetch(
      `${DEFAULT_BASE_URL}/api/h5/home/config/active?environment=${encodeURIComponent(environment)}`,
      { signal: controller.signal },
    );
    const data = await response.json();
    if (!response.ok) {
      throw new Error(data?.message || `首页配置请求失败：${response.status}`);
    }
    if (!isHomeConfig(data)) {
      throw new Error('首页配置结构无效');
    }
    return data;
  } finally {
    window.clearTimeout(timeout);
  }
}
```

- [ ] **Step 4: Add components and wire page**

Create `HomeSkeleton.tsx`, `HomeModules.tsx`, `HomeScreen.tsx`, and replace `page.tsx` with:

```tsx
import { HomeScreen } from '@/features/home/HomeScreen';

export default function HomePage() {
  return <HomeScreen />;
}
```

`HomeScreen` must:

- render `<HomeSkeleton />` while loading;
- call `readCachedHomeConfig('prod')` before remote fetch;
- call `fetchHomeConfig('prod')`;
- call `writeCachedHomeConfig('prod', config)` on success;
- render `DEFAULT_HOME_CONFIG` when remote and cache both fail.

- [ ] **Step 5: Run H5 checks**

Run:

```bash
cd /Users/mac/person_code/meu-mall/hybird-meumall
pnpm test -- src/features/home/home.test.tsx
pnpm test
pnpm typecheck
pnpm lint
pnpm build
```

Expected: all pass.

---

## Task 7: Integration And Verification

**Files:**
- Modify: `.ai-workspace/tasks/TASK-2026-0601-001-homepage-config.md`
- Modify as needed: project `.ai/test-reports/*.md`

- [ ] **Step 1: Start backend**

Run:

```bash
cd /Users/mac/person_code/meu-mall/server-meumall
uvicorn app.main:create_app --factory --host 127.0.0.1 --port 4100
```

Expected: server responds at `http://127.0.0.1:4100/api/health`.

- [ ] **Step 2: Seed and publish a homepage config**

Run with `curl` or the admin UI:

```bash
curl -s http://127.0.0.1:4100/api/home/configs \
  -H 'Content-Type: application/json' \
  -d '{"name":"首页 smoke 配置","environment":"prod","config":{"schemaVersion":"1.0","pageId":"home","configVersion":"2026.06.01-smoke","generatedAt":"2026-06-01T00:00:00Z","cache":{"ttlSeconds":300,"staleWhileRevalidateSeconds":1800},"modules":[]}}'
```

Expected: returns a draft `id`. Publish that `id` with `POST /api/home/configs/{id}/publish`.

- [ ] **Step 3: Start H5 and inspect homepage**

Run:

```bash
cd /Users/mac/person_code/meu-mall/hybird-meumall
pnpm dev
```

Open `http://localhost:3000/`.

Expected:

- skeleton appears during loading;
- homepage renders after config fetch;
- page width remains within mobile shell;
- no visible shopping cart entry appears.

- [ ] **Step 4: Record verification**

Update the task file status to `verified` only after all listed validation commands pass. Record command outputs, failed checks, skipped checks, and residual risks.

---

## Self-Review

Spec coverage:

- Backend CRUD, publish, active uniqueness, validation, H5 active query are covered by Tasks 1 and 2.
- Admin content route and homepage config editing are covered by Tasks 3 and 4.
- H5 skeleton, fetch, cache, fallback, module render and performance hooks baseline are covered by Tasks 5 and 6.
- Integration smoke and task status update are covered by Task 7.

Known scope decisions:

- The first admin version may use a JSON textarea inside a dedicated homepage configuration page while exposing module sections. Full drag-and-drop and image upload remain outside this task.
- Recommendation products remain existing fallback or reserved area. Recommendation API is outside this task.
