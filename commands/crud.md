# /crud - 快速生成 CRUD 代码

作为 CRUD 代码生成助手，基于已存在的数据库表快速生成标准后端 CRUD 代码。

## 🎯 适用场景

### ✅ 适合使用 `/crud` 的情况

- ✅ **数据库表已存在** - 表结构已设计完毕
- ✅ **只需标准 CRUD** - 增删改查、导入导出等标准功能
- ✅ **无复杂业务逻辑** - 没有特殊的业务规则
- ✅ **快速原型开发** - 需要快速搭建基础功能

### ❌ 不适合使用 `/crud` 的情况

- ❌ **表结构尚未设计** 
- ❌ **需要复杂业务逻辑** 
- ❌ **需要特殊的查询条件** 

### 📋 支持的模板类型

| 模板类型 | 适用场景 | 特点 |
|---------|---------|------|
| **crud** | 普通表 | 标准增删改查、分页列表 |


---

## 📋 执行流程

### 第一步：连接数据库并查看表结构

#### 1.1 询问用户

```
请提供表名：
（如：sys_notice, demo_xxx）
```

#### 1.2 连接数据库并查看表结构

```bash
# 查看表结构
SHOW CREATE TABLE [表名];

# 查看字段详情
DESC [表名];

```

#### 1.3 字段类型映射规则

| 数据库类型 | Java类型 | 说明 |
|-----------|---------|------|
| BIGINT(20), BIGINT | Long | 长整数 |
| INT(11), INT | Integer | 整数 |
| VARCHAR(n), CHAR(n) | String | 字符串 |
| TEXT, LONGTEXT | String | 长文本 |
| DATETIME, TIMESTAMP | Date | 日期时间 |
| DECIMAL(m,n) | BigDecimal | 高精度数值 |
| TINYINT(1), CHAR(1) | String | 状态字段（0/1）|

#### 1.4 输出表结构分析

```markdown
## 📊 表结构分析

**表名**：[表名]
**注释**：[表注释]

**字段列表**：
| 字段名 | 类型 | 是否必填 | 默认值 | 注释 |
|--------|------|---------|--------|------|
| id | BIGINT(20) | 是 | - | 主键ID |
| tenant_id | int(11) | 否 | '000000' | 租户ID |
| xxx_name | VARCHAR(100) | 是 | - | 名称 |
| status | CHAR(1) | 否 | '1' | 状态 |
| creater| varchar(36) | 否 | NULL | 创建人 |
| create_time | DATETIME | 否 | CURRENT_TIMESTAMP | 创建时间 |
| updater | varchar(36) | 否 | NULL | 修改人 |
| update_time | DATETIME | 否 | CURRENT_TIMESTAMP | 更新时间 |
| del_flag | CHAR(1) | 否 | '0' | 删除标志 |

**审计字段**：✅ 完整（包含  creater, create_time, updater, update_time）
**逻辑删除**：✅ 已配置（del_flag）
**租户支持**：✅ 已支持（tenant_id）

---

### 提取功能名称

根据表名 `sys_notice` 提取功能名称：
- 中文名：公告
- 英文名：Notice
- 类名前缀：Notice

确认功能名称，或自定义修改？
```

---

### 第 1.5 步：选择模板类型（新增）⭐⭐⭐⭐⭐

根据表结构特征，询问用户选择模板类型（本版本不需要询问只有普通表）：

```
1. **crud** - 普通表（默认）
   适用于：标准增删改查，无层级关系
   示例：通知公告、用户反馈等
```

---

### 第二步：生成后端代码

#### 3.0 **指定生成规则（可选，ARGUMENTS无值则全部生成）**

根据ARGUMENTS识别生成用户指定的代码。

**强制规则**：
- **Entity**：不存在则必须生成（不取决于用户决定），已存在则跳过
- **Service**：生成时必须同时生成 **ServiceImpl**
- **Mapper**：仅生成接口，**不生成** mapper.xml（使用 MyBatis Plus BaseMapper）

**生成规则对照表**：

| ARGUMENTS | 生成内容 | 说明 |
|-----------|---------|------|
| 空（默认） | Entity + Request + Query + VO + Mapper + Service + ServiceImpl + Controller | 完整 CRUD |
| 仅mapper | Entity + Mapper | 仅数据访问层，Mapper 继承 BaseMapper，不需要 XML |
| 仅service | Entity + Service + ServiceImpl | 仅业务逻辑层 |
| 仅controller | Entity + Controller | 仅 API 层 |

**具体示例**：

**示例1.1**：生成 Mapper（Entity 不存在）
```
命令：/crud 仅mapper
表名：tbl_electric_terms_use_system_relation

生成文件：
✅ ElectricTermsUseSystemRelation.java (Entity)
✅ ElectricTermsUseSystemRelationMapper.java (Mapper 接口)
❌ 不生成 ElectricTermsUseSystemRelationMapper.xml
```

**示例1.2**：生成 Mapper（Entity 已存在）
```
前提：ElectricTermsUseSystemRelation.java 已存在

命令：/crud 仅mapper
表名：tbl_electric_terms_use_system_relation

生成文件：
✅ ElectricTermsUseSystemRelationMapper.java (Mapper 接口)
❌ 跳过 Entity
❌ 不生成 mapper.xml
```

**示例2.1**：生成 Service
```
命令：/crud 仅service
表名：tbl_electric_terms_use_system_relation

生成文件：
✅ ElectricTermsUseSystemRelation.java (Entity，如果不存在)
✅ IElectricTermsUseSystemRelationService.java (Service 接口)
✅ ElectricTermsUseSystemRelationServiceImpl.java (ServiceImpl 实现)
```

#### 3.1 学习现有代码 + 学习代码规范（强制执行）

‼️当现有代码和代码规范冲突时，进行综合。示例如下

```
//现有代码
/**
 * 电子条款信息订阅表
 * @TableName tbl_electric_terms_subscribe
 */
@TableName(value ="tbl_electric_terms_subscribe")
@Data
public class ElectricTermsSubscribe {
    /**
     * 
     */
    @TableId
    private Integer id;
    .......
}

// 代码规范
/**
 * {表注释} 对象
 *
 * @author {authorName}
 */
@Data
@EqualsAndHashCode(callSuper = true)
@Accessors(chain = true)
@TableName("tbl_xxx")
@ApiModel(value = "Xxx对象", description = "{表注释}")
public class Xxx extends BaseEntity {  

    private static final long serialVersionUID = 1L;

    /**
     * 主键 ID
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;
}

✅正确结果为
/**
 * {表注释} 对象
 *
 * @TableName tbl_electric_terms_subscribe
 * @author {authorName}
 */
@Data
@EqualsAndHashCode(callSuper = true)
@Accessors(chain = true)
@TableName("tbl_xxx")
@ApiModel(value = "Xxx对象", description = "{表注释}")
public class Xxx extends BaseEntity {  

    private static final long serialVersionUID = 1L;

    /**
     * 主键 ID
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;
}
```

##### 学习现有代码

```bash
# 必须先阅读 demo 模块代码作为参考（标准 CRUD 写法）
Read @src/main/java/com/sf/contract/controller/ElectricTermsSubscribeController.java
Read @src/main/java/com/sf/contract/service/impl/ElectricTermsSubscribeServiceImpl.java
Read @src/main/java/com/sf/contract/entity/ElectricTermsSubscribe.java
Read @src/main/java/com/sf/contract/vo/request/ElectricTermsSubscribeSaveRequest.java
Read @src/main/java/com/sf/contract/vo/ElectricTermsVO.java
Read @src/main/java/com/sf/contract/vo/ElectricTermsQuery.java

```

##### 学习代码规范

###### 1. Entity 实体类（继承 BaseEntity）

```java
package com.sf.contract.entity;

import com.baomidou.mybatisplus.annotation.*;
import com.sf.contract.entity.base.BaseEntity;
import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;

/**
 * {表注释} 对象
 *
 * @author {authorName}
 */
@Data
@EqualsAndHashCode(callSuper = true)
@Accessors(chain = true)
@TableName("tbl_xxx")
@ApiModel(value = "Xxx对象", description = "{表注释}")
public class Xxx extends BaseEntity {  

    private static final long serialVersionUID = 1L;

    /**
     * 主键 ID
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 名称
     */
    private String xxxName;

    /**
     * 状态（0正常，1停用）
     */
    private String status;
  
    /**
     * 租户ID
     */
    private Integer tenantId;
  
    /**
     * 删除标志（0代表存在，1代表删除）
     */
    private String delFlag;
}
```

⚠️BaseEntity类已存在，当表中有字段creater、updater、create_time、update_time是，生成的Entity中不需要再写这四个字段，但是要继承BaseEntity类

###### 2. Service 接口

```java
package com.sf.ctc.contract.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.IService;
import com.sf.boot.base.vo.PageQueryReq;
import com.sf.contract.entity.Xxx;
import com.sf.contract.vo.XxxQuery;
import com.sf.contract.vo.XxxVO;

/**
 * {表注释} 服务接口
 *
 * @author {authorName}
 */
public interface IXxxService extends IService<Xxx>{

    /**
     * 根据 ID 查询
     */
    // （待补充，本次会话不参考）XxxVo queryById(Long id);

    /**
     * 查询列表
     */
    // （待补充，本次会话不参考）List<XxxVo> queryList(XxxQuery req);

    /**
     * 分页查询列表
     */
    Page<XxxVo> queryPageList(PageQueryReq<XxxVO, XxxQuery> req);

    /**
     * 保存
     */
    // （待补充，本次会话不参考）Boolean save(XxxRequest request);

    /**
     * 删除
     */
    // （待补充，本次会话不参考）Boolean delete(Collection<Long> ids);
}
```

---

###### 3. Service 实现类（⭐ 核心：三层架构，NO DAO 层）

```java
package com.sf.contract.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.sf.boot.base.vo.PageQueryReq;
import com.sf.contract.entity.XxxRecovery;
import com.sf.contract.mapper.XxxMapper;
import com.sf.contract.service.IXxxService;
import com.sf.contract.vo.XxxQuery;
import com.sf.contract.vo.XxxVO;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.collections4.CollectionUtils;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;

/**
 * {表注释} 服务实现
 *
 * @author {authorName}
 */
@Service
@Slf4j
public class XxxServiceImpl extends ServiceImpl<XxxMapper, Xxx> implements IXxxService {
    
    @Resource
    private XxxMapper baseMapper;  // ✅ 直接注入 Mapper（NO DAO!）

    @Override
    public Page<XxxVo> queryPageList(PageQueryReq<XxxVO, XxxQuery> req) {
        LambdaQueryWrapper<Xxx> lqw = buildQueryWrapper(req.getCondition());  // ✅ Service 层构建查询
        Page<XxxVo> result = baseMapper.selectVoPage(req.newPage(), lqw);
        return result;
    }

    /**
     * 构建查询条件
     * ✅ Service 层直接构建（不是 DAO 层）
     */
    private LambdaQueryWrapper<Xxx> buildQueryWrapper(XxxQuery queryCondition) {
        LambdaQueryWrapper<Xxx> lqw = Wrappers.lambdaQuery();
       
        if (queryCondition == null) {
            return lqw;
        }
        
        // ✅ 租户支持(如果有租户支持字段执行该流程)
        lqw.eq(xxx::getTenantId, "0");    
        
        // ✅ 逻辑删除(如果有逻辑删除字段执行该流程)
        lqw.eq(xxx::getDelFlag, "0");
      
        // ✅ 精确匹配(如果需要精确匹配执行该流程)
        lqw.eq(queryCondition.getId() != null, Xxx::getId, bo.getId());
        lqw.eq(StringUtils.isNotBlank(queryCondition.getStatus()), Xxx::getStatus, queryCondition.getStatus());

        // ✅ 模糊匹配(如果需要模糊匹配执行该流程)
        lqw.like(StringUtils.isNotBlank(queryCondition.getXxxName()), Xxx::getXxxName, queryCondition.getXxxName());

        // ✅ 时间范围(如果需要时间范围执行该流程)
        lqw.ge(queryCondition.getXxxStart() != null,
            Xxx::getXxx, queryCondition.getXxxStart());
        lqw.le(queryCondition.getXxxEnd() != null,
            Xxx::getXxx, queryCondition.getXxxEnd());

        // ✅ 排序(如果需要排序执行该流程)
        lqw.orderByDesc(Xxx::getId);
        return lqw;
    }

}
```

---

###### 6. Mapper 接口

```java
package com.sf.contract.mapper;

import com.baomidou.mybatisplus.core.conditions.Wrapper;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.sf.contract.entity.Xxx;
import com.sf.contract.vo.XxxVO;
import org.apache.ibatis.annotations.Mapper;

/**
 * {表注释} Mapper 接口
 *
 * @author authorName
 */
public interface XxxMapper extends BaseMapper<Xxx> {
  
   /**
   * 分页查询列表
   */
   Page<ElectricTermsListVO> selectVoPage(Page<ElectricTermsListVO> page, Wrapper ew);
}
```

---

###### 7.Mapper 接口实现XxxMapper.xml

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN"
        "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="com.sf.contract.mapper.SignedDocumentRecoveryMapper">

    <!-- 分页查询列表 -->
    <select id="selectVoPage" resultType="com.sf.contract.vo.SignedDocumentRecoveryVO">
        SELECT
            id,
            xxx_name,
            status,
            creater,
            updater,
            create_time,
            update_time
        FROM tbl_xxx

        <if test="ew != null">
            ${ew.customSqlSegment}
        </if>
    </select>

</mapper>
```

------

###### 8. Controller 控制器（标准 RESTful 路径）

```java
package com.sf.contract.controller;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.sf.boot.base.vo.PageQueryReq;
import com.sf.boot.base.vo.Result;
import com.sf.contract.service.IXxxService;
import com.sf.contract.vo.XxxQuery;
import com.sf.contract.vo.XxxVO;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.extern.slf4j.Slf4j;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * {表注释} 管理控制器
 *
 * @author {authorName}
 */
@Validated
@RestController
@RequestMapping("/xxx")
@Api(value = "XXX")
public class XxxController  { 
    
    @Resource
    private IXxxService xxxService;

    /**
     * 分页查询列表
     */
    @PostMapping("/queryPageList")
    @ApiOperation(value = "分页查询列表")
    public Result<Page<XxxVO>> queryPageList(@RequestBody PageQueryReq<XxxVO, XxxQuery> req) {
        return xxxService.queryPageList(req);
    }
}
```

###### 9.写{authorName} 规则

使用`git config user.name`命令读取名字，如果是汉字，转为拼音。其他无需转换

```
示例1:
命令：git config user.name
命令结果：周晓旭
authorName赋值为zhouxiaoxu

示例1:
命令：git config user.name
命令结果：01450358
authorName赋值为01450358
```

------

###### 10.写{表注释} 规则

{表注释}的内容为数据库表的注释

###### 11.Query注意事项

当包含时间类型Data时，添加@JsonFormat和@DateTimeFormat注解

```
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss", timezone = "GMT+8")
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private Date XxxTimeStart;

    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss", timezone = "GMT+8")
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private Date XxxTimeEnd;
```

#### 3.2 生成代码顺序（三层架构）

按照以下顺序生成：

1. **Entity** - 字段从表结构映射
2. **Request** - 非分页功能请求对象
3. **Query**-分页功能请求对象
4. **VO** - 响应对象
5. **Mapper** - 继承 BaseMapper
6. **Service 接口** - 标准 CRUD 方法声明
7. **ServiceImpl** - 业务逻辑实现，包含 buildQueryWrapper
8. **Controller** - 标准接口 

#### 3.3 字段类型映射规则

| 数据库类型 | Java类型 |
|-----------|---------|
| BIGINT(20) | Long |
| VARCHAR/CHAR | String |
| TEXT | String |
| DATETIME | Date |
| DECIMAL | BigDecimal |
| INT | Integer |

---

### 第三步：输出代码清单

```markdown
✅ CRUD 代码生成完成！

## 已生成文件清单

### 后端代码 (8个文件)
- ✅ entity/Xxx.java (Entity)
- ✅ vo/request/Xxxrequest.java (request)
- ✅ vo/XxxVo.java (VO)
- ✅ vo/XxxQuery.java (Query)
- ✅ mapper/XxxMapper.java (Mapper接口)
- ✅ src/main/resources/mapper/XxxMapper.xml (Mapper实现)
- ✅ service/IXxxService.java (Service接口)
- ✅ service/impl/XxxServiceImpl.java (Service实现)
- ✅ controller/XxxController.java (Controller)

---
```

