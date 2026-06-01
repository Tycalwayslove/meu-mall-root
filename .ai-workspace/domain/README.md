# 业务领域模型目录

本目录存放 MeuMall 的业务领域模型。领域模型用于统一商品、店铺、推广、达人、佣金、智能体、会员、购买记录等概念，避免 H5、server、admin 和原生壳各自定义一套说法。

## 已建立领域规则

1. `ecommerce-data-consistency.md`
2. `meumall-business-model.md`

## 建议继续补齐

1. `product.md`
2. `sku.md`
3. `cart.md`
4. `order.md`
5. `user.md`

## 写作要求

每个领域文档至少说明：

- 概念定义。
- 核心字段。
- 状态枚举。
- 与其他领域的关系。
- 哪些项目可以读取或修改该领域。
- 哪些行为暂不支持。
