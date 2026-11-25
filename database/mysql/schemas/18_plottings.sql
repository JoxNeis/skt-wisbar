CREATE TABLE
    IF NOT EXISTS `plottings` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with inventory_reservations.id (CTI)',
        `reservation_type` enum ('allocation', 'plotting') NOT NULL DEFAULT 'plotting' COMMENT 'CTI discriminator, always plotting',
        `source_transaction_id` bigint unsigned NOT NULL COMMENT 'Plotted line: handover_detail, incoming_detail or production_group_return',
        `source_transaction_type` varchar(63) NOT NULL,
        `source_header_id` bigint unsigned NOT NULL COMMENT 'Document of the plotted line',
        `source_header_type` varchar(63) NOT NULL,
        `status` enum ('planned', 'put_away', 'cancelled') NOT NULL DEFAULT 'planned' COMMENT 'planned = takes room in the bin',
        `cancel_reason` varchar(255) DEFAULT NULL COMMENT 'Required exactly when cancelled',
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_plottings_id_source_header_id` (`id`, `source_header_id`) COMMENT 'Target of fk_put_away_details_plotting',
        KEY `ix_plottings_source_line` (`source_transaction_id`, `source_transaction_type`, `source_header_type`),
        KEY `ix_plottings_source_line_header` (`source_transaction_id`, `source_header_id`),
        KEY `ix_plottings_source_header_id_status` (`source_header_id`, `status`),
        KEY `ix_plottings_status` (`status`),
        CONSTRAINT `fk_plottings_parent` FOREIGN KEY (`id`, `reservation_type`) REFERENCES `inventory_reservations` (`id`, `reservation_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_plottings_source_line` FOREIGN KEY (`source_transaction_id`, `source_transaction_type`, `source_header_type`) REFERENCES `transactions` (`id`, `transaction_type`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_plottings_source_header` FOREIGN KEY (`source_transaction_id`, `source_header_id`) REFERENCES `transactions` (`id`, `transaction_header_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_plottings_reservation_type` CHECK ((`reservation_type` = _utf8mb4 'plotting'))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of inventory_reservations: where a received, handed-over or returned quantity will be put';
