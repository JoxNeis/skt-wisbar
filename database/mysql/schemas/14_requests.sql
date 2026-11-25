CREATE TABLE
    IF NOT EXISTS `requests` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with transaction_headers.id (CTI)',
        `transaction_header_type` varchar(63) NOT NULL COMMENT 'CTI discriminator',
        `status` enum ('open', 'in_progress', 'completed', 'cancelled') NOT NULL DEFAULT 'open' COMMENT 'Fulfilment status; may change after signing',
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_requests_id_transaction_header_type` (`id`, `transaction_header_type`) COMMENT 'Target of the subtype FKs',
        KEY `ix_requests_transaction_header_type_status` (`transaction_header_type`, `status`),
        CONSTRAINT `fk_requests_parent` FOREIGN KEY (`id`, `transaction_header_type`) REFERENCES `transaction_headers` (`id`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_requests_transaction_header_type` CHECK (
            (
                `transaction_header_type` in (
                    _utf8mb4 'production_order',
                    _utf8mb4 'production_return',
                    _utf8mb4 'internal_transfer',
                    _utf8mb4 'outbound',
                    _utf8mb4 'production_reject'
                )
            )
        )
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of transaction_headers, CTI parent of every request flow';

CREATE TABLE
    IF NOT EXISTS `production_orders` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with requests.id (CTI)',
        `transaction_header_type` varchar(63) NOT NULL DEFAULT 'production_order' COMMENT 'CTI discriminator, always production_order',
        `production_id` bigint unsigned NOT NULL,
        `production_date` date NOT NULL COMMENT 'Location local date',
        `required_at` datetime DEFAULT NULL COMMENT 'When the material must be on the line; NULL = not given',
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        KEY `ix_production_orders_production_id_production_date` (`production_id`, `production_date`),
        CONSTRAINT `fk_production_orders_parent` FOREIGN KEY (`id`, `transaction_header_type`) REFERENCES `requests` (`id`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_orders_production_id` FOREIGN KEY (`production_id`) REFERENCES `productions` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_production_orders_transaction_header_type` CHECK ((`transaction_header_type` = _utf8mb4 'production_order'))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of requests: material a production facility needs for the day';

CREATE TABLE
    IF NOT EXISTS `production_returns` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with requests.id (CTI)',
        `transaction_header_type` varchar(63) NOT NULL DEFAULT 'production_return' COMMENT 'CTI discriminator, always production_return',
        `production_id` bigint unsigned NOT NULL,
        `production_date` date NOT NULL COMMENT 'Production day whose leftover is returned, location local date',
        `from_warehouse_id` bigint unsigned NOT NULL COMMENT 'Staging warehouse of the production',
        `from_storage_type` enum ('staging', 'return') NOT NULL DEFAULT 'staging' COMMENT 'Always staging',
        `active_key` tinyint DEFAULT '1' COMMENT '1 = draft or signed; NULL = reversed or deleted',
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_production_returns_production_date_active` (`production_id`, `production_date`, `active_key`) COMMENT 'One active return per production per day',
        KEY `ix_production_returns_from_warehouse` (`from_warehouse_id`, `production_id`, `from_storage_type`),
        CONSTRAINT `fk_production_returns_parent` FOREIGN KEY (`id`, `transaction_header_type`) REFERENCES `requests` (`id`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_returns_from_warehouse` FOREIGN KEY (`from_warehouse_id`, `production_id`, `from_storage_type`) REFERENCES `production_warehouses` (`id`, `production_id`, `storage_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_returns_production_id` FOREIGN KEY (`production_id`) REFERENCES `productions` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_production_returns_types` CHECK (
            (
                (`transaction_header_type` = _utf8mb4 'production_return')
                and (`from_storage_type` = _utf8mb4 'staging')
            )
        ),
        CONSTRAINT `ck_production_returns_active_key` CHECK (((`active_key` is null) or (`active_key` = 1)))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of requests: end-of-day leftover moved from staging into the production return bins';

CREATE TABLE
    IF NOT EXISTS `internal_transfers` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with requests.id (CTI)',
        `transaction_header_type` varchar(63) NOT NULL DEFAULT 'internal_transfer' COMMENT 'CTI discriminator, always internal_transfer',
        `from_warehouse_id` bigint unsigned NOT NULL,
        `to_warehouse_id` bigint unsigned NOT NULL COMMENT 'Same location as from_warehouse_id',
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        KEY `ix_internal_transfers_from_warehouse_id` (`from_warehouse_id`),
        KEY `ix_internal_transfers_to_warehouse_id` (`to_warehouse_id`),
        CONSTRAINT `fk_internal_transfers_parent` FOREIGN KEY (`id`, `transaction_header_type`) REFERENCES `requests` (`id`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_internal_transfers_from_warehouse_id` FOREIGN KEY (`from_warehouse_id`) REFERENCES `warehouses` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_internal_transfers_to_warehouse_id` FOREIGN KEY (`to_warehouse_id`) REFERENCES `warehouses` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_internal_transfers_transaction_header_type` CHECK ((`transaction_header_type` = _utf8mb4 'internal_transfer')),
        CONSTRAINT `ck_internal_transfers_distinct_warehouses` CHECK ((`from_warehouse_id` <> `to_warehouse_id`))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of requests: stock moved between two warehouses of one location';

CREATE TABLE
    IF NOT EXISTS `outbounds` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with requests.id (CTI)',
        `transaction_header_type` varchar(63) NOT NULL DEFAULT 'outbound' COMMENT 'CTI discriminator, always outbound',
        `from_warehouse_id` bigint unsigned NOT NULL,
        `to_organization_id` bigint unsigned NOT NULL,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        KEY `ix_outbounds_from_warehouse_id` (`from_warehouse_id`),
        KEY `ix_outbounds_to_organization_id` (`to_organization_id`),
        CONSTRAINT `fk_outbounds_parent` FOREIGN KEY (`id`, `transaction_header_type`) REFERENCES `requests` (`id`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_outbounds_from_warehouse_id` FOREIGN KEY (`from_warehouse_id`) REFERENCES `warehouses` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_outbounds_to_organization_id` FOREIGN KEY (`to_organization_id`) REFERENCES `organizations` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_outbounds_transaction_header_type` CHECK ((`transaction_header_type` = _utf8mb4 'outbound'))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of requests: stock shipped to another organization';

CREATE TABLE
    IF NOT EXISTS `production_rejects` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with requests.id (CTI)',
        `transaction_header_type` varchar(63) NOT NULL DEFAULT 'production_reject' COMMENT 'CTI discriminator, always production_reject',
        `production_id` bigint unsigned NOT NULL,
        `from_warehouse_id` bigint unsigned NOT NULL COMMENT 'Staging or return warehouse of the production',
        `from_storage_type` enum ('staging', 'return') NOT NULL DEFAULT 'staging',
        `to_warehouse_id` bigint unsigned NOT NULL COMMENT 'Quarantine warehouse',
        `to_warehouse_type` enum ('main', 'production', 'quarantine') NOT NULL DEFAULT 'quarantine' COMMENT 'Always quarantine',
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        KEY `ix_production_rejects_production_id` (`production_id`),
        KEY `ix_production_rejects_from_warehouse` (`from_warehouse_id`, `production_id`, `from_storage_type`),
        KEY `ix_production_rejects_to_warehouse` (`to_warehouse_id`, `to_warehouse_type`),
        CONSTRAINT `fk_production_rejects_parent` FOREIGN KEY (`id`, `transaction_header_type`) REFERENCES `requests` (`id`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_rejects_production_id` FOREIGN KEY (`production_id`) REFERENCES `productions` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_rejects_from_warehouse` FOREIGN KEY (`from_warehouse_id`, `production_id`, `from_storage_type`) REFERENCES `production_warehouses` (`id`, `production_id`, `storage_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_rejects_to_warehouse` FOREIGN KEY (`to_warehouse_id`, `to_warehouse_type`) REFERENCES `warehouses` (`id`, `warehouse_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_production_rejects_types` CHECK (
            (
                (`transaction_header_type` = _utf8mb4 'production_reject')
                and (`to_warehouse_type` = _utf8mb4 'quarantine')
            )
        )
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of requests: unfit material moved from a production warehouse into quarantine';

CREATE TABLE
    IF NOT EXISTS `request_details` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with transactions.id (CTI)',
        `transaction_type` varchar(63) NOT NULL DEFAULT 'request_detail' COMMENT 'CTI discriminator, always request_detail',
        `transaction_header_type` varchar(63) NOT NULL,
        `request_id` bigint unsigned NOT NULL COMMENT '= transactions.transaction_header_id',
        `item_id` bigint unsigned NOT NULL,
        `batch_id` bigint unsigned DEFAULT NULL COMMENT 'NULL exactly on a production order',
        `amount` decimal(20, 3) NOT NULL COMMENT 'In unit_of_measurement_id',
        `unit_of_measurement_id` bigint unsigned NOT NULL,
        `base_amount` decimal(20, 3) NOT NULL COMMENT 'In the item base unit; set by trigger',
        `remarks` text DEFAULT NULL,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_request_details_id_request_id` (`id`, `request_id`) COMMENT 'Target of fk_allocations_request_detail',
        KEY `ix_request_details_request` (`request_id`, `transaction_header_type`),
        KEY `ix_request_details_item_id` (`item_id`),
        KEY `ix_request_details_batch_id_item_id` (`batch_id`, `item_id`),
        KEY `ix_request_details_unit_of_measurement_id` (`unit_of_measurement_id`),
        CONSTRAINT `fk_request_details_parent` FOREIGN KEY (`id`, `transaction_type`, `transaction_header_type`) REFERENCES `transactions` (`id`, `transaction_type`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_request_details_own_header` FOREIGN KEY (`id`, `request_id`) REFERENCES `transactions` (`id`, `transaction_header_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_request_details_request` FOREIGN KEY (`request_id`, `transaction_header_type`) REFERENCES `requests` (`id`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_request_details_item_id` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_request_details_batch_item` FOREIGN KEY (`batch_id`, `item_id`) REFERENCES `batches` (`id`, `item_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_request_details_unit_of_measurement_id` FOREIGN KEY (`unit_of_measurement_id`) REFERENCES `unit_of_measurements` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_request_details_transaction_type` CHECK ((`transaction_type` = _utf8mb4 'request_detail')),
        CONSTRAINT `ck_request_details_amounts_positive` CHECK (
            (
                (`amount` > 0)
                and (`base_amount` > 0)
            )
        )
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of transactions: requested items or batches of every request flow';
