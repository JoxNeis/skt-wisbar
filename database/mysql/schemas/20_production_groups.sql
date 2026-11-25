CREATE TABLE
    IF NOT EXISTS `production_group_usages` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with transaction_headers.id (CTI)',
        `transaction_header_type` varchar(63) NOT NULL DEFAULT 'production_group_usage' COMMENT 'CTI discriminator, always production_group_usage',
        `production_id` bigint unsigned NOT NULL,
        `usage_date` date NOT NULL COMMENT 'Production day, location local date',
        `active_key` tinyint DEFAULT '1' COMMENT '1 = draft or signed; NULL = reversed or deleted',
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_production_group_usages_id_production_id` (`id`, `production_id`) COMMENT 'Target of fk_production_group_usage_details_sheet',
        UNIQUE KEY `uq_production_group_usages_production_date_active` (`production_id`, `usage_date`, `active_key`) COMMENT 'One active day sheet per production per day',
        CONSTRAINT `fk_production_group_usages_parent` FOREIGN KEY (`id`, `transaction_header_type`) REFERENCES `transaction_headers` (`id`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_group_usages_production_id` FOREIGN KEY (`production_id`) REFERENCES `productions` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_production_group_usages_transaction_header_type` CHECK ((`transaction_header_type` = _utf8mb4 'production_group_usage')),
        CONSTRAINT `ck_production_group_usages_active_key` CHECK (((`active_key` is null) or (`active_key` = 1)))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of transaction_headers: day sheet of one production (usages, rejects, returns); no stock effect';

CREATE TABLE
    IF NOT EXISTS `production_group_usage_details` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with transactions.id (CTI)',
        `transaction_type` varchar(63) NOT NULL DEFAULT 'production_group_usage_detail' COMMENT 'CTI discriminator, always production_group_usage_detail',
        `transaction_header_type` varchar(63) NOT NULL DEFAULT 'production_group_usage',
        `production_group_usage_id` bigint unsigned NOT NULL COMMENT '= transactions.transaction_header_id',
        `production_id` bigint unsigned NOT NULL COMMENT 'Denormalized from the day sheet',
        `production_group_id` bigint unsigned NOT NULL COMMENT 'Must belong to the day sheet production',
        `batch_id` bigint unsigned NOT NULL,
        `box_count` int unsigned DEFAULT NULL COMMENT 'NULL = not counted in boxes',
        `amount` decimal(20, 3) NOT NULL COMMENT 'In unit_of_measurement_id',
        `unit_of_measurement_id` bigint unsigned NOT NULL,
        `taken_by` bigint unsigned NOT NULL COMMENT 'Member of the group on the usage date',
        `given_by` bigint unsigned NOT NULL COMMENT 'Staging staff',
        `remarks` text DEFAULT NULL,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_production_group_usage_details_id_sheet_id` (`id`, `production_group_usage_id`) COMMENT 'Target of the reject and return FKs',
        KEY `ix_production_group_usage_details_sheet` (`production_group_usage_id`, `production_id`),
        KEY `ix_production_group_usage_details_group_id` (`production_group_id`, `production_id`),
        KEY `ix_production_group_usage_details_batch_id` (`batch_id`),
        KEY `ix_production_group_usage_details_unit_id` (`unit_of_measurement_id`),
        KEY `ix_production_group_usage_details_taken_by` (`taken_by`),
        KEY `ix_production_group_usage_details_given_by` (`given_by`),
        CONSTRAINT `fk_production_group_usage_details_parent` FOREIGN KEY (`id`, `transaction_type`, `transaction_header_type`) REFERENCES `transactions` (`id`, `transaction_type`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_group_usage_details_own_header` FOREIGN KEY (`id`, `production_group_usage_id`) REFERENCES `transactions` (`id`, `transaction_header_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_group_usage_details_sheet` FOREIGN KEY (`production_group_usage_id`, `production_id`) REFERENCES `production_group_usages` (`id`, `production_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_group_usage_details_group` FOREIGN KEY (`production_group_id`, `production_id`) REFERENCES `production_groups` (`id`, `production_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_group_usage_details_batch_id` FOREIGN KEY (`batch_id`) REFERENCES `batches` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_group_usage_details_unit_id` FOREIGN KEY (`unit_of_measurement_id`) REFERENCES `unit_of_measurements` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_group_usage_details_taken_by` FOREIGN KEY (`taken_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_group_usage_details_given_by` FOREIGN KEY (`given_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_production_group_usage_details_types` CHECK (
            (
                (`transaction_type` = _utf8mb4 'production_group_usage_detail')
                and (`transaction_header_type` = _utf8mb4 'production_group_usage')
            )
        ),
        CONSTRAINT `ck_production_group_usage_details_amount_positive` CHECK ((`amount` > 0)),
        CONSTRAINT `ck_production_group_usage_details_box_count_positive` CHECK (
            (
                (`box_count` is null)
                or (`box_count` > 0)
            )
        )
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of transactions: material taken from staging by a production group';

CREATE TABLE
    IF NOT EXISTS `production_group_rejects` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with transactions.id (CTI)',
        `transaction_type` varchar(63) NOT NULL DEFAULT 'production_group_reject' COMMENT 'CTI discriminator, always production_group_reject',
        `transaction_header_type` varchar(63) NOT NULL DEFAULT 'production_group_usage',
        `production_group_usage_id` bigint unsigned NOT NULL COMMENT '= transactions.transaction_header_id',
        `production_group_usage_detail_id` bigint unsigned NOT NULL COMMENT 'Usage on the same day sheet',
        `amount` decimal(20, 3) NOT NULL COMMENT 'In unit_of_measurement_id',
        `unit_of_measurement_id` bigint unsigned NOT NULL,
        `remarks` text DEFAULT NULL,
        `recorded_by` bigint unsigned NOT NULL,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        KEY `ix_production_group_rejects_usage` (`production_group_usage_detail_id`, `production_group_usage_id`),
        KEY `ix_production_group_rejects_unit_id` (`unit_of_measurement_id`),
        KEY `ix_production_group_rejects_recorded_by` (`recorded_by`),
        CONSTRAINT `fk_production_group_rejects_parent` FOREIGN KEY (`id`, `transaction_type`, `transaction_header_type`) REFERENCES `transactions` (`id`, `transaction_type`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_group_rejects_own_header` FOREIGN KEY (`id`, `production_group_usage_id`) REFERENCES `transactions` (`id`, `transaction_header_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_group_rejects_usage` FOREIGN KEY (`production_group_usage_detail_id`, `production_group_usage_id`) REFERENCES `production_group_usage_details` (`id`, `production_group_usage_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_group_rejects_unit_id` FOREIGN KEY (`unit_of_measurement_id`) REFERENCES `unit_of_measurements` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_group_rejects_recorded_by` FOREIGN KEY (`recorded_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_production_group_rejects_types` CHECK (
            (
                (`transaction_type` = _utf8mb4 'production_group_reject')
                and (`transaction_header_type` = _utf8mb4 'production_group_usage')
            )
        ),
        CONSTRAINT `ck_production_group_rejects_amount_positive` CHECK ((`amount` > 0))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of transactions: part of a usage found unfit; no stock effect';

CREATE TABLE
    IF NOT EXISTS `production_group_wastes` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with transactions.id (CTI)',
        `transaction_type` varchar(63) NOT NULL DEFAULT 'production_group_waste' COMMENT 'CTI discriminator, always production_group_waste',
        `transaction_header_type` varchar(63) NOT NULL DEFAULT 'production_group_usage',
        `production_group_usage_id` bigint unsigned NOT NULL COMMENT '= transactions.transaction_header_id',
        `production_group_usage_detail_id` bigint unsigned NOT NULL COMMENT 'Usage on the same day sheet',
        `amount` decimal(20, 3) NOT NULL COMMENT 'In unit_of_measurement_id',
        `unit_of_measurement_id` bigint unsigned NOT NULL,
        `remarks` text DEFAULT NULL,
        `recorded_by` bigint unsigned NOT NULL,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        KEY `ix_production_group_wastes_usage` (`production_group_usage_detail_id`, `production_group_usage_id`),
        KEY `ix_production_group_wastes_unit_id` (`unit_of_measurement_id`),
        KEY `ix_production_group_wastes_recorded_by` (`recorded_by`),
        CONSTRAINT `fk_production_group_wastes_parent` FOREIGN KEY (`id`, `transaction_type`, `transaction_header_type`) REFERENCES `transactions` (`id`, `transaction_type`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_group_wastes_own_header` FOREIGN KEY (`id`, `production_group_usage_id`) REFERENCES `transactions` (`id`, `transaction_header_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_group_wastes_usage` FOREIGN KEY (`production_group_usage_detail_id`, `production_group_usage_id`) REFERENCES `production_group_usage_details` (`id`, `production_group_usage_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_group_wastes_unit_id` FOREIGN KEY (`unit_of_measurement_id`) REFERENCES `unit_of_measurements` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_group_wastes_recorded_by` FOREIGN KEY (`recorded_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_production_group_wastes_types` CHECK (
            (
                (`transaction_type` = _utf8mb4 'production_group_waste')
                and (`transaction_header_type` = _utf8mb4 'production_group_usage')
            )
        ),
        CONSTRAINT `ck_production_group_wastes_amount_positive` CHECK ((`amount` > 0))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of transactions: part of a usage wasted during production; no stock effect';

CREATE TABLE
    IF NOT EXISTS `production_group_returns` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with transactions.id (CTI)',
        `transaction_type` varchar(63) NOT NULL DEFAULT 'production_group_return' COMMENT 'CTI discriminator, always production_group_return',
        `transaction_header_type` varchar(63) NOT NULL DEFAULT 'production_group_usage',
        `production_group_usage_id` bigint unsigned NOT NULL COMMENT '= transactions.transaction_header_id',
        `production_group_usage_detail_id` bigint unsigned NOT NULL COMMENT 'Usage on the same day sheet',
        `amount` decimal(20, 3) NOT NULL COMMENT 'In unit_of_measurement_id',
        `unit_of_measurement_id` bigint unsigned NOT NULL,
        `returned_by` bigint unsigned NOT NULL COMMENT 'Group member',
        `received_by` bigint unsigned NOT NULL COMMENT 'Staging staff',
        `remarks` text DEFAULT NULL,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        KEY `ix_production_group_returns_usage` (`production_group_usage_detail_id`, `production_group_usage_id`),
        KEY `ix_production_group_returns_unit_id` (`unit_of_measurement_id`),
        KEY `ix_production_group_returns_returned_by` (`returned_by`),
        KEY `ix_production_group_returns_received_by` (`received_by`),
        CONSTRAINT `fk_production_group_returns_parent` FOREIGN KEY (`id`, `transaction_type`, `transaction_header_type`) REFERENCES `transactions` (`id`, `transaction_type`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_group_returns_own_header` FOREIGN KEY (`id`, `production_group_usage_id`) REFERENCES `transactions` (`id`, `transaction_header_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_group_returns_usage` FOREIGN KEY (`production_group_usage_detail_id`, `production_group_usage_id`) REFERENCES `production_group_usage_details` (`id`, `production_group_usage_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_group_returns_unit_id` FOREIGN KEY (`unit_of_measurement_id`) REFERENCES `unit_of_measurements` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_group_returns_returned_by` FOREIGN KEY (`returned_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_group_returns_received_by` FOREIGN KEY (`received_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_production_group_returns_types` CHECK (
            (
                (`transaction_type` = _utf8mb4 'production_group_return')
                and (`transaction_header_type` = _utf8mb4 'production_group_usage')
            )
        ),
        CONSTRAINT `ck_production_group_returns_amount_positive` CHECK ((`amount` > 0)),
        CONSTRAINT `ck_production_group_returns_distinct_parties` CHECK ((`returned_by` <> `received_by`))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of transactions: unused material brought back to staging; stock rises when it is put away';
