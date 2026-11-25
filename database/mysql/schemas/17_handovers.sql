CREATE TABLE
    IF NOT EXISTS `handovers` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with transaction_headers.id (CTI)',
        `transaction_header_type` varchar(63) NOT NULL DEFAULT 'handover' COMMENT 'CTI discriminator, always handover',
        `request_id` bigint unsigned NOT NULL,
        `request_type` varchar(63) NOT NULL COMMENT 'Denormalized; decides who receives',
        `picking_id` bigint unsigned NOT NULL,
        `from_warehouse_id` bigint unsigned NOT NULL COMMENT 'The picking warehouse',
        `to_warehouse_id` bigint unsigned DEFAULT NULL COMMENT 'NULL for an outbound',
        `handed_by` bigint unsigned NOT NULL,
        `received_by` bigint unsigned DEFAULT NULL COMMENT 'NULL exactly for an outbound',
        `receiver_name` varchar(127) DEFAULT NULL COMMENT 'Driver or courier; required exactly for an outbound',
        `delivery_note_id` bigint unsigned DEFAULT NULL COMMENT 'Issued delivery note; required exactly for an outbound',
        `handed_over_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `active_key` tinyint DEFAULT '1' COMMENT '1 = draft or signed; NULL = reversed or deleted',
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_handovers_id_picking_id` (`id`, `picking_id`) COMMENT 'Target of fk_handover_details_handover',
        UNIQUE KEY `uq_handovers_picking_id_active_key` (`picking_id`, `active_key`) COMMENT 'One active handover per picking',
        UNIQUE KEY `uq_handovers_delivery_note_id_active_key` (`delivery_note_id`, `active_key`) COMMENT 'One active handover per delivery note',
        KEY `ix_handovers_request` (`request_id`, `request_type`),
        KEY `ix_handovers_picking` (`picking_id`, `request_id`),
        KEY `ix_handovers_from_warehouse_id` (`from_warehouse_id`),
        KEY `ix_handovers_to_warehouse_id` (`to_warehouse_id`),
        KEY `ix_handovers_handed_by` (`handed_by`),
        KEY `ix_handovers_received_by` (`received_by`),
        CONSTRAINT `fk_handovers_parent` FOREIGN KEY (`id`, `transaction_header_type`) REFERENCES `transaction_headers` (`id`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_handovers_request` FOREIGN KEY (`request_id`, `request_type`) REFERENCES `requests` (`id`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_handovers_picking` FOREIGN KEY (`picking_id`, `request_id`) REFERENCES `pickings` (`id`, `request_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_handovers_from_warehouse_id` FOREIGN KEY (`from_warehouse_id`) REFERENCES `warehouses` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_handovers_to_warehouse_id` FOREIGN KEY (`to_warehouse_id`) REFERENCES `warehouses` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_handovers_handed_by` FOREIGN KEY (`handed_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_handovers_received_by` FOREIGN KEY (`received_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_handovers_delivery_note_id` FOREIGN KEY (`delivery_note_id`) REFERENCES `delivery_notes` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_handovers_transaction_header_type` CHECK ((`transaction_header_type` = _utf8mb4 'handover')),
        CONSTRAINT `ck_handovers_active_key` CHECK (((`active_key` is null) or (`active_key` = 1)))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of transaction_headers: picked material passed to the receiver; no stock effect';

CREATE TABLE
    IF NOT EXISTS `handover_details` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with transactions.id (CTI)',
        `transaction_type` varchar(63) NOT NULL DEFAULT 'handover_detail' COMMENT 'CTI discriminator, always handover_detail',
        `transaction_header_type` varchar(63) NOT NULL DEFAULT 'handover',
        `handover_id` bigint unsigned NOT NULL COMMENT '= transactions.transaction_header_id',
        `picking_id` bigint unsigned NOT NULL COMMENT 'Denormalized from the handover',
        `picking_detail_id` bigint unsigned NOT NULL,
        `amount` decimal(20, 3) NOT NULL COMMENT 'Actually handed over, in unit_of_measurement_id',
        `unit_of_measurement_id` bigint unsigned NOT NULL,
        `base_amount` decimal(20, 3) NOT NULL COMMENT 'In the item base unit; set by trigger',
        `remarks` text DEFAULT NULL,
        `active_key` tinyint DEFAULT '1' COMMENT '1 = draft or signed; NULL = reversed or deleted',
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_handover_details_picking_detail_id_active_key` (`picking_detail_id`, `active_key`) COMMENT 'One active line per picked line',
        KEY `ix_handover_details_handover` (`handover_id`, `picking_id`),
        KEY `ix_handover_details_picking_detail` (`picking_detail_id`, `picking_id`),
        KEY `ix_handover_details_unit_of_measurement_id` (`unit_of_measurement_id`),
        CONSTRAINT `fk_handover_details_parent` FOREIGN KEY (`id`, `transaction_type`, `transaction_header_type`) REFERENCES `transactions` (`id`, `transaction_type`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_handover_details_own_header` FOREIGN KEY (`id`, `handover_id`) REFERENCES `transactions` (`id`, `transaction_header_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_handover_details_handover` FOREIGN KEY (`handover_id`, `picking_id`) REFERENCES `handovers` (`id`, `picking_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_handover_details_picking_detail` FOREIGN KEY (`picking_detail_id`, `picking_id`) REFERENCES `picking_details` (`id`, `picking_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_handover_details_unit_of_measurement_id` FOREIGN KEY (`unit_of_measurement_id`) REFERENCES `unit_of_measurements` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_handover_details_types` CHECK (
            (
                (`transaction_type` = _utf8mb4 'handover_detail')
                and (`transaction_header_type` = _utf8mb4 'handover')
            )
        ),
        CONSTRAINT `ck_handover_details_amounts_positive` CHECK (
            (
                (`amount` > 0)
                and (`base_amount` > 0)
            )
        ),
        CONSTRAINT `ck_handover_details_active_key` CHECK (((`active_key` is null) or (`active_key` = 1)))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of transactions: quantity actually handed over per picked line';
