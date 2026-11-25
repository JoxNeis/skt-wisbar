CREATE TABLE
    IF NOT EXISTS `inventory_reservations` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `reservation_type` enum ('allocation', 'plotting') NOT NULL COMMENT 'CTI discriminator: allocation = to take out, plotting = to put in',
        `warehouse_bin_inventory_id` bigint unsigned NOT NULL,
        `batch_id` bigint unsigned NOT NULL COMMENT 'Denormalized from the bin inventory',
        `amount` decimal(20, 3) NOT NULL COMMENT 'In the item base unit',
        `remarks` text DEFAULT NULL,
        `reserved_by` bigint unsigned NOT NULL,
        `reserved_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_inventory_reservations_id_reservation_type` (`id`, `reservation_type`) COMMENT 'Target of the subtype FKs',
        KEY `ix_inventory_reservations_bin_inventory_type` (`warehouse_bin_inventory_id`, `reservation_type`),
        KEY `ix_inventory_reservations_bin_inventory_batch` (`warehouse_bin_inventory_id`, `batch_id`),
        KEY `ix_inventory_reservations_batch_id` (`batch_id`),
        KEY `ix_inventory_reservations_reserved_by` (`reserved_by`),
        CONSTRAINT `fk_inventory_reservations_bin_inventory_batch` FOREIGN KEY (`warehouse_bin_inventory_id`, `batch_id`) REFERENCES `warehouse_bin_inventories` (`id`, `batch_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_inventory_reservations_batch_id` FOREIGN KEY (`batch_id`) REFERENCES `batches` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_inventory_reservations_reserved_by` FOREIGN KEY (`reserved_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_inventory_reservations_amount_positive` CHECK ((`amount` > 0))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI parent of allocations and plottings: planned stock out of or into a bin inventory; never deleted';

CREATE TABLE
    IF NOT EXISTS `allocations` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with inventory_reservations.id (CTI)',
        `reservation_type` enum ('allocation', 'plotting') NOT NULL DEFAULT 'allocation' COMMENT 'CTI discriminator, always allocation',
        `request_detail_id` bigint unsigned NOT NULL,
        `request_id` bigint unsigned NOT NULL COMMENT 'Denormalized from the request line',
        `status` enum ('reserved', 'picked', 'released') NOT NULL DEFAULT 'reserved' COMMENT 'reserved = holds the stock; released = cancelled before picking',
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_allocations_id_request_id` (`id`, `request_id`) COMMENT 'Target of fk_picking_details_allocation',
        KEY `ix_allocations_request_detail` (`request_detail_id`, `request_id`),
        KEY `ix_allocations_request_id_status` (`request_id`, `status`),
        KEY `ix_allocations_status` (`status`),
        CONSTRAINT `fk_allocations_parent` FOREIGN KEY (`id`, `reservation_type`) REFERENCES `inventory_reservations` (`id`, `reservation_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_allocations_request_detail` FOREIGN KEY (`request_detail_id`, `request_id`) REFERENCES `request_details` (`id`, `request_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_allocations_reservation_type` CHECK ((`reservation_type` = _utf8mb4 'allocation'))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of inventory_reservations: stock reserved for a request line';
