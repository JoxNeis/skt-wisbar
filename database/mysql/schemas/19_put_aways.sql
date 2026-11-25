CREATE TABLE
    IF NOT EXISTS `put_aways` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with stock_movements.id (CTI)',
        `transaction_header_type` varchar(63) NOT NULL DEFAULT 'put_away' COMMENT 'CTI discriminator, always put_away',
        `source_header_id` bigint unsigned NOT NULL COMMENT 'Handover, incoming or day sheet whose plotted stock is put away',
        `source_header_type` varchar(63) NOT NULL,
        `active_key` tinyint DEFAULT '1' COMMENT '1 = draft or signed; NULL = reversed or deleted',
        `one_per_source_key` tinyint GENERATED ALWAYS AS (if ((`source_header_type` in (_utf8mb4 'handover', _utf8mb4 'incoming')), `active_key`, NULL)) STORED COMMENT 'One active put away per handover or incoming; a day sheet may have several',
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_put_aways_id_source_header_id` (`id`, `source_header_id`) COMMENT 'Target of fk_put_away_details_put_away',
        UNIQUE KEY `uq_put_aways_source_header_id_one_per_source_key` (`source_header_id`, `one_per_source_key`),
        KEY `ix_put_aways_source_header` (`source_header_id`, `source_header_type`),
        CONSTRAINT `fk_put_aways_parent` FOREIGN KEY (`id`, `transaction_header_type`) REFERENCES `stock_movements` (`id`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_put_aways_source_header` FOREIGN KEY (`source_header_id`, `source_header_type`) REFERENCES `transaction_headers` (`id`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_put_aways_types` CHECK (
            (
                (`transaction_header_type` = _utf8mb4 'put_away')
                and (`source_header_type` in (_utf8mb4 'handover', _utf8mb4 'incoming', _utf8mb4 'production_group_usage'))
            )
        ),
        CONSTRAINT `ck_put_aways_active_key` CHECK (((`active_key` is null) or (`active_key` = 1)))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of stock_movements: puts the plotted stock of one source document into its bins';

CREATE TABLE
    IF NOT EXISTS `put_away_details` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with stock_movement_details.id (CTI)',
        `transaction_type` varchar(63) NOT NULL DEFAULT 'put_away_detail' COMMENT 'CTI discriminator, always put_away_detail',
        `transaction_header_type` varchar(63) NOT NULL DEFAULT 'put_away',
        `put_away_id` bigint unsigned NOT NULL COMMENT '= transactions.transaction_header_id',
        `source_header_id` bigint unsigned NOT NULL COMMENT 'Denormalized from the put away',
        `plotting_id` bigint unsigned NOT NULL COMMENT 'Moves the bin inventory of this plotting',
        `active_key` tinyint DEFAULT '1' COMMENT '1 = draft or signed; NULL = reversed or deleted',
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_put_away_details_plotting_id_active_key` (`plotting_id`, `active_key`) COMMENT 'One active line per plotting',
        KEY `ix_put_away_details_put_away` (`put_away_id`, `source_header_id`),
        KEY `ix_put_away_details_plotting` (`plotting_id`, `source_header_id`),
        CONSTRAINT `fk_put_away_details_parent` FOREIGN KEY (`id`, `transaction_type`, `transaction_header_type`) REFERENCES `stock_movement_details` (`id`, `transaction_type`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_put_away_details_own_header` FOREIGN KEY (`id`, `put_away_id`) REFERENCES `transactions` (`id`, `transaction_header_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_put_away_details_put_away` FOREIGN KEY (`put_away_id`, `source_header_id`) REFERENCES `put_aways` (`id`, `source_header_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_put_away_details_plotting` FOREIGN KEY (`plotting_id`, `source_header_id`) REFERENCES `plottings` (`id`, `source_header_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_put_away_details_types` CHECK (
            (
                (`transaction_type` = _utf8mb4 'put_away_detail')
                and (`transaction_header_type` = _utf8mb4 'put_away')
            )
        ),
        CONSTRAINT `ck_put_away_details_active_key` CHECK (((`active_key` is null) or (`active_key` = 1)))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of stock_movement_details: in line that carries out one plotting';
