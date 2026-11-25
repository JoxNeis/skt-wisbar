CREATE TABLE
    IF NOT EXISTS `pickings` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with stock_movements.id (CTI)',
        `transaction_header_type` varchar(63) NOT NULL DEFAULT 'picking' COMMENT 'CTI discriminator, always picking',
        `request_id` bigint unsigned NOT NULL,
        `from_warehouse_id` bigint unsigned NOT NULL COMMENT 'Every line comes from a bin of this warehouse',
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_pickings_id_request_id` (`id`, `request_id`) COMMENT 'Target of (picking_id, request_id) FKs',
        KEY `ix_pickings_request_id` (`request_id`),
        KEY `ix_pickings_from_warehouse_id` (`from_warehouse_id`),
        CONSTRAINT `fk_pickings_parent` FOREIGN KEY (`id`, `transaction_header_type`) REFERENCES `stock_movements` (`id`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_pickings_request_id` FOREIGN KEY (`request_id`) REFERENCES `requests` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_pickings_from_warehouse_id` FOREIGN KEY (`from_warehouse_id`) REFERENCES `warehouses` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_pickings_transaction_header_type` CHECK ((`transaction_header_type` = _utf8mb4 'picking'))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of stock_movements: takes allocated stock of a request out of its bins';

CREATE TABLE
    IF NOT EXISTS `picking_details` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with stock_movement_details.id (CTI)',
        `transaction_type` varchar(63) NOT NULL DEFAULT 'picking_detail' COMMENT 'CTI discriminator, always picking_detail',
        `transaction_header_type` varchar(63) NOT NULL DEFAULT 'picking',
        `picking_id` bigint unsigned NOT NULL COMMENT '= transactions.transaction_header_id',
        `request_id` bigint unsigned NOT NULL COMMENT 'Denormalized from the picking',
        `allocation_id` bigint unsigned NOT NULL COMMENT 'Moves the bin inventory of this allocation',
        `active_key` tinyint DEFAULT '1' COMMENT '1 = draft or signed; NULL = reversed or deleted',
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_picking_details_id_picking_id` (`id`, `picking_id`) COMMENT 'Target of fk_handover_details_picking_detail',
        UNIQUE KEY `uq_picking_details_allocation_id_active_key` (`allocation_id`, `active_key`) COMMENT 'One active line per allocation',
        KEY `ix_picking_details_picking` (`picking_id`, `request_id`),
        KEY `ix_picking_details_allocation` (`allocation_id`, `request_id`),
        CONSTRAINT `fk_picking_details_parent` FOREIGN KEY (`id`, `transaction_type`, `transaction_header_type`) REFERENCES `stock_movement_details` (`id`, `transaction_type`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_picking_details_own_header` FOREIGN KEY (`id`, `picking_id`) REFERENCES `transactions` (`id`, `transaction_header_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_picking_details_picking` FOREIGN KEY (`picking_id`, `request_id`) REFERENCES `pickings` (`id`, `request_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_picking_details_allocation` FOREIGN KEY (`allocation_id`, `request_id`) REFERENCES `allocations` (`id`, `request_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_picking_details_types` CHECK (
            (
                (`transaction_type` = _utf8mb4 'picking_detail')
                and (`transaction_header_type` = _utf8mb4 'picking')
            )
        ),
        CONSTRAINT `ck_picking_details_active_key` CHECK (((`active_key` is null) or (`active_key` = 1)))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of stock_movement_details: out line that carries out one allocation';
