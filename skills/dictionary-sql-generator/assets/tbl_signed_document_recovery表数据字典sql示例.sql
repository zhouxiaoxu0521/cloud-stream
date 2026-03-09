/*
CREATE TABLE `tbl_signed_document_recovery` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `ecp_process_code` varchar(64) DEFAULT NULL COMMENT 'ECP流程编号',
  `contract_id` varchar(64) DEFAULT NULL COMMENT '合同ID',
  `contract_code` varchar(64) DEFAULT NULL COMMENT '合同编号',
  `business_system_no` varchar(200) DEFAULT NULL COMMENT '业务系统关联编号',
  `contract_name` varchar(256) DEFAULT NULL COMMENT '合同名称',
  `sys_source_abbreviation` char(1) NOT NULL COMMENT '系统来源简称（0-CTC）',
  `applicant_code` varchar(36) DEFAULT NULL COMMENT '申请人工号',
  `applicant_name` varchar(64) DEFAULT NULL COMMENT '申请人姓名',
  `applicant_org_code` varchar(64) DEFAULT NULL COMMENT '申请人所属组织编码',
  `applicant_org_name` varchar(255) DEFAULT NULL COMMENT '申请人所属组织名称',
  `legal_bp_code` varchar(36) DEFAULT NULL COMMENT '责任法务BP工号',
  `legal_bp_name` varchar(64) DEFAULT NULL COMMENT '责任法务BP姓名',
  `status` char(1) DEFAULT NULL COMMENT '状态（0-待回收，1-已回收，2-无需回收，3-无法回收）',
  `overdue_status` char(1) DEFAULT NULL DEFAULT 0 COMMENT '逾期状态（0-正常，1-即将逾期，2-已逾期）',
  `process_archived_time` datetime DEFAULT NULL COMMENT '流程归档时间',
  `actual_recovery_time` datetime DEFAULT NULL COMMENT '实际回收时间',
  `remark` text COMMENT '备注',
  `tenant_id` int(11) DEFAULT NULL COMMENT '租户ID',
  `creater` varchar(36) DEFAULT NULL COMMENT '创建人',
  `updater` varchar(36) DEFAULT NULL COMMENT '更新人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `del_flag` char(1) default '0' comment '删除标志（0-代表存在，1-代表删除）',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_ecp_process_code` (`ecp_process_code`) USING BTREE,
  KEY `idx_contract_code` (`contract_code`) USING BTREE,
  KEY `business_system_no` (`business_system_no`) USING BTREE,
  KEY `idx_tenant_id_del_flag` (`tenant_id`, `del_flag`) USING BTREE
) ENGINE=InnoDB  CHARSET=utf8mb4 COMMENT='签订件回收管理主表';
*/


-- 1. 插入模块字典：签订件回收管理
INSERT INTO ts_dictionary
(DIC_KEY, DIC_NAME, DESCRIPT, PARENT_ID, DIC_VALUE, SN, PKEY_PATH, STATUS, CREATE_BY, UPDATE_BY)
VALUES ('SIGNED_DOCUMENT_RECOVERY', '签订件回收管理', NULL, 1,
        '签订件回收管理', 1, 'SysArguSetting', 1, NULL, NULL);

-- 2.1 插入类别字典：状态
INSERT INTO ts_dictionary
(DIC_KEY, DIC_NAME, DESCRIPT, PARENT_ID, DIC_VALUE, SN, PKEY_PATH, STATUS, CREATE_BY, UPDATE_BY)
VALUES ('STATUS', '状态', NULL, (SELECT t.DIC_ID
                                 FROM (SELECT DIC_ID
                                       FROM ts_dictionary
                                       WHERE DIC_KEY = 'SIGNED_DOCUMENT_RECOVERY'
                                         AND PKEY_PATH = 'SysArguSetting'
                                       LIMIT 1) t),
        '状态', 1, 'SysArguSetting.SIGNED_DOCUMENT_RECOVERY', 1, NULL, NULL);

-- 2.2 插入类别字典：逾期状态
INSERT INTO ts_dictionary
(DIC_KEY, DIC_NAME, DESCRIPT, PARENT_ID, DIC_VALUE, SN, PKEY_PATH, STATUS, CREATE_BY, UPDATE_BY)
VALUES ('OVERDUE_STATUS', '逾期状态', NULL, (SELECT t.DIC_ID
                                             FROM (SELECT DIC_ID
                                                   FROM ts_dictionary
                                                   WHERE DIC_KEY = 'SIGNED_DOCUMENT_RECOVERY'
                                                     AND PKEY_PATH = 'SysArguSetting'
                                                   LIMIT 1) t),
        '逾期状态', 2, 'SysArguSetting.SIGNED_DOCUMENT_RECOVERY', 1, NULL, NULL);

-- 2.3 插入类别字典：系统来源
INSERT INTO ts_dictionary
(DIC_KEY, DIC_NAME, DESCRIPT, PARENT_ID, DIC_VALUE, SN, PKEY_PATH, STATUS, CREATE_BY, UPDATE_BY)
VALUES ('SYS_SOURCE', '系统来源', NULL, (SELECT t.DIC_ID
                                         FROM (SELECT DIC_ID
                                               FROM ts_dictionary
                                               WHERE DIC_KEY = 'SIGNED_DOCUMENT_RECOVERY'
                                                 AND PKEY_PATH = 'SysArguSetting'
                                               LIMIT 1) t),
        '系统来源', 3, 'SysArguSetting.SIGNED_DOCUMENT_RECOVERY', 1, NULL, NULL);

-- 3.1 插入项字典：状态
INSERT INTO ts_dictionary
(DIC_KEY, DIC_NAME, DESCRIPT, PARENT_ID, DIC_VALUE, SN, PKEY_PATH, STATUS, CREATE_BY, UPDATE_BY)
VALUES ('WAITING_RECOVERY', '待回收', NULL, (SELECT t.DIC_ID
                                             FROM (SELECT DIC_ID
                                                   FROM ts_dictionary
                                                   WHERE DIC_KEY = 'STATUS'
                                                     AND PKEY_PATH = 'SysArguSetting.SIGNED_DOCUMENT_RECOVERY'
                                                   LIMIT 1) t),
        '0', 1, 'SysArguSetting.SIGNED_DOCUMENT_RECOVERY.STATUS', 1, NULL, NULL);

INSERT INTO ts_dictionary
(DIC_KEY, DIC_NAME, DESCRIPT, PARENT_ID, DIC_VALUE, SN, PKEY_PATH, STATUS, CREATE_BY, UPDATE_BY)
VALUES ('RECOVERED', '已回收', NULL, (SELECT t.DIC_ID
                                      FROM (SELECT DIC_ID
                                            FROM ts_dictionary
                                            WHERE DIC_KEY = 'STATUS'
                                              AND PKEY_PATH = 'SysArguSetting.SIGNED_DOCUMENT_RECOVERY'
                                            LIMIT 1) t),
        '1', 2, 'SysArguSetting.SIGNED_DOCUMENT_RECOVERY.STATUS', 1, NULL, NULL);

INSERT INTO ts_dictionary
(DIC_KEY, DIC_NAME, DESCRIPT, PARENT_ID, DIC_VALUE, SN, PKEY_PATH, STATUS, CREATE_BY, UPDATE_BY)
VALUES ('NO_NEED_RECOVERY', '无需回收', NULL, (SELECT t.DIC_ID
                                               FROM (SELECT DIC_ID
                                                     FROM ts_dictionary
                                                     WHERE DIC_KEY = 'STATUS'
                                                       AND PKEY_PATH = 'SysArguSetting.SIGNED_DOCUMENT_RECOVERY'
                                                     LIMIT 1) t),
        '2', 3, 'SysArguSetting.SIGNED_DOCUMENT_RECOVERY.STATUS', 1, NULL, NULL);

INSERT INTO ts_dictionary
(DIC_KEY, DIC_NAME, DESCRIPT, PARENT_ID, DIC_VALUE, SN, PKEY_PATH, STATUS, CREATE_BY, UPDATE_BY)
VALUES ('CANNOT_RECOVERY', '无法回收', NULL, (SELECT t.DIC_ID
                                              FROM (SELECT DIC_ID
                                                    FROM ts_dictionary
                                                    WHERE DIC_KEY = 'STATUS'
                                                      AND PKEY_PATH = 'SysArguSetting.SIGNED_DOCUMENT_RECOVERY'
                                                    LIMIT 1) t),
        '3', 4, 'SysArguSetting.SIGNED_DOCUMENT_RECOVERY.STATUS', 1, NULL, NULL);

-- 3.2 插入项字典：逾期状态
INSERT INTO ts_dictionary
(DIC_KEY, DIC_NAME, DESCRIPT, PARENT_ID, DIC_VALUE, SN, PKEY_PATH, STATUS, CREATE_BY, UPDATE_BY)
VALUES ('NORMAL', '正常', NULL, (SELECT t.DIC_ID
                                 FROM (SELECT DIC_ID
                                       FROM ts_dictionary
                                       WHERE DIC_KEY = 'OVERDUE_STATUS'
                                         AND PKEY_PATH = 'SysArguSetting.SIGNED_DOCUMENT_RECOVERY'
                                       LIMIT 1) t),
        '0', 1, 'SysArguSetting.SIGNED_DOCUMENT_RECOVERY.OVERDUE_STATUS', 1, NULL, NULL);

INSERT INTO ts_dictionary
(DIC_KEY, DIC_NAME, DESCRIPT, PARENT_ID, DIC_VALUE, SN, PKEY_PATH, STATUS, CREATE_BY, UPDATE_BY)
VALUES ('ABOUT_TO_OVERDUE', '即将逾期', NULL, (SELECT t.DIC_ID
                                               FROM (SELECT DIC_ID
                                                     FROM ts_dictionary
                                                     WHERE DIC_KEY = 'OVERDUE_STATUS'
                                                       AND PKEY_PATH = 'SysArguSetting.SIGNED_DOCUMENT_RECOVERY'
                                                     LIMIT 1) t),
        '1', 2, 'SysArguSetting.SIGNED_DOCUMENT_RECOVERY.OVERDUE_STATUS', 1, NULL, NULL);

INSERT INTO ts_dictionary
(DIC_KEY, DIC_NAME, DESCRIPT, PARENT_ID, DIC_VALUE, SN, PKEY_PATH, STATUS, CREATE_BY, UPDATE_BY)
VALUES ('ALREADY_OVERDUE', '已逾期', NULL, (SELECT t.DIC_ID
                                            FROM (SELECT DIC_ID
                                                  FROM ts_dictionary
                                                  WHERE DIC_KEY = 'OVERDUE_STATUS'
                                                    AND PKEY_PATH = 'SysArguSetting.SIGNED_DOCUMENT_RECOVERY'
                                                  LIMIT 1) t),
        '2', 3, 'SysArguSetting.SIGNED_DOCUMENT_RECOVERY.OVERDUE_STATUS', 1, NULL, NULL);

-- 3.3 插入项字典：系统来源
INSERT INTO ts_dictionary
(DIC_KEY, DIC_NAME, DESCRIPT, PARENT_ID, DIC_VALUE, SN, PKEY_PATH, STATUS, CREATE_BY, UPDATE_BY)
VALUES ('CTC', 'CTC', NULL, (SELECT t.DIC_ID
                             FROM (SELECT DIC_ID
                                   FROM ts_dictionary
                                   WHERE DIC_KEY = 'SYS_SOURCE'
                                     AND PKEY_PATH = 'SysArguSetting.SIGNED_DOCUMENT_RECOVERY'
                                   LIMIT 1) t),
        '0', 1, 'SysArguSetting.SIGNED_DOCUMENT_RECOVERY.SYS_SOURCE', 1, NULL, NULL);