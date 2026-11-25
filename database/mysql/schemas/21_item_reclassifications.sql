CREATE TABLE
    IF NOT EXISTS `item_reclassifications` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with stock_movements.id (CTI)',
        `transaction_header_type` varchar(63) NOT NULL DEFAULT 'item_reclassification' COMMENT 'CTI discriminator, always item_reclassification',
        `out_stock_movement_detail_id` bigint unsigned NOT NULL COMMENT 'Takes the old item and batch out of the bin',
        `out_movement_type` enum ('in', 'out') NOT NULL DEFAULT 'out' COMMENT 'Always out',
        `in_stock_movement_detail_id` bigint unsigned NOT NULL COMMENT 'Puts the new item and batch into the same bin',
        `in_movement_type` enum ('in', 'out') NOT NULL DEFAULT 'in' COMMENT 'Always in',
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_item_reclassifications_out_line` (`out_stock_movement_detail_id`),
        UNIQUE KEY `uq_item_reclassifications_in_line` (`in_stock_movement_detail_id`),
        KEY `ix_item_reclassifications_out_line_type` (`out_stock_movement_detail_id`, `out_movement_type`),
        KEY `ix_item_reclassifications_in_line_type` (`in_stock_movement_detail_id`, `in_movement_type`),
        KEY `ix_item_reclassifications_out_line_header` (`out_stock_movement_detail_id`, `id`),
        KEY `ix_item_reclassifications_in_line_header` (`in_stock_movement_detail_id`, `id`),
        CONSTRAINT `fk_item_reclassifications_parent` FOREIGN KEY (`id`, `transaction_header_type`) REFERENCES `stock_movements` (`id`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_item_reclassifications_out_line` FOREIGN KEY (`out_stock_movement_detail_id`, `out_movement_type`) REFERENCES `stock_movement_details` (`id`, `type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_item_reclassifications_in_line` FOREIGN KEY (`in_stock_movement_detail_id`, `in_movement_type`) REFERENCES `stock_movement_details` (`id`, `type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_item_reclassifications_out_line_header` FOREIGN KEY (`out_stock_movement_detail_id`, `id`) REFERENCES `transactions` (`id`, `transaction_header_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_item_reclassifications_in_line_header` FOREIGN KEY (`in_stock_movement_detail_id`, `id`) REFERENCES `transactions` (`id`, `transaction_header_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_item_reclassifications_types` CHECK (
            (
                (`transaction_header_type` = _utf8mb4 'item_reclassification')
                and (`out_movement_type` = _utf8mb4 'out')
                and (`in_movement_type` = _utf8mb4 'in')
            )
        )
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of stock_movements: stock in one bin re-recorded under another item or batch (one out and one in line)';
