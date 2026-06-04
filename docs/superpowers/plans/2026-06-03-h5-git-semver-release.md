# H5 Git 语义化版本发布改造计划

## 目标

将 H5 多容器发布从手填日期版本升级为 `package.json version -> vX.Y.Z -> h5/vX.Y.Z Git tag -> release manifest` 的统一链路。

## 规则

- `hybird-meumall/package.json` 的 `version` 是唯一版本源。
- H5 线上版本号固定为 `v{packageVersion}`。
- 正式部署必须存在 `h5/v{packageVersion}` tag。
- 当前 H5 工作区 HEAD 必须等于发布 Git ref 指向的 commit。
- 正式部署时 H5 工作区必须干净。
- 回滚目标不再手填，由部署脚本从线上 active manifest 的 `stableVersion` 自动读取。

## 实施步骤

1. 为 `hybird-meumall/package.json` 增加版本字段。
2. 改造 H5 部署脚本，派生版本、校验 Git ref/tag、读取 active manifest、注册 release。
3. 扩展 release 注册 payload 的 `buildMeta`。
4. 收窄 Jenkins 参数，只保留 `GIT_REF`。
5. 更新发布规范、API 文档和工作项记录。
6. 执行 bash 语法、dry-run、release 注册脚本测试和工作流检查。

## 后续操作

首次真实发布前，需要提交 H5 改动并创建 tag：

```bash
cd hybird-meumall
git add package.json pnpm-lock.yaml
git commit -m "release(h5): v1.0.0"
git tag h5/v1.0.0
git push origin HEAD
git push origin h5/v1.0.0
```
