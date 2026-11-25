CREATE TABLE
    IF NOT EXISTS `stock_movements` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with transaction_headers.id (CTI)',
        `transaction_header_type` varchar(63) NOT NULL COMMENT 'CTI discriminator; stock_movement = bin move inside one warehouse (no subtype table)',
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_stock_movements_id_transaction_header_type` (`id`, `transaction_header_type`) COMMENT 'Target of the subtype FKs',
        CONSTRAINT `fk_stock_movements_parent` FOREIGN KEY (`id`, `transaction_header_type`) REFERENCES `transaction_headers` (`id`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_stock_movements_transaction_header_type` CHECK (
            (
                `transaction_header_type` in (
                    _utf8mb4 'stock_movement',
                    _utf8mb4 'picking',
                    _utf8mb4 'put_away',
                    _utf8mb4 'item_reclassification'
                )
            )
        )
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of transaction_headers, CTI parent of every document that changes stock';

CREATE TABLE
    IF NOT EXISTS `stock_movement_details` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with transactions.id (CTI)',
        `transaction_type` varchar(63) NOT NULL COMMENT 'CTI discriminator; stock_movement_detail has no subtype table',
        `transaction_header_type` varchar(63) NOT NULL,
        `warehouse_bin_inventory_id` bigint unsigned NOT NULL,
        `type` enum ('in', 'out') NOT NULL COMMENT 'A bin move is one out and one in line',
        `amount` decimal(20, 3) NOT NULL COMMENT 'In the item base unit',
        `pallet_count` int unsigned DEFAULT NULL COMMENT 'NULL = not counted',
        `moved_by` bigint unsigned NOT NULL,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_stock_movement_details_id_types` (`id`, `transaction_type`, `transaction_header_type`) COMMENT 'Target of the subtype FKs',
        UNIQUE KEY `uq_stock_movement_details_id_type` (`id`, `type`) COMMENT 'Target of FKs that need an in or an out line',
        KEY `ix_stock_movement_details_warehouse_bin_inventory_id` (`warehouse_bin_inventory_id`),
        KEY `ix_stock_movement_details_moved_by` (`moved_by`),
        CONSTRAINT `fk_stock_movement_details_parent` FOREIGN KEY (`id`, `transaction_type`, `transaction_header_type`) REFERENCES `transactions` (`id`, `transaction_type`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_stock_movement_details_bin_inventory` FOREIGN KEY (`warehouse_bin_inventory_id`) REFERENCES `warehouse_bin_inventories` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_stock_movement_details_moved_by` FOREIGN KEY (`moved_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_stock_movement_details_amount_positive` CHECK ((`amount` > 0))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of transactions, CTI parent of picking_details and put_away_details: stock into or out of a bin inventory';
