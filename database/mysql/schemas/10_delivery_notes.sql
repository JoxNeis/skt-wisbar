CREATE TABLE
    IF NOT EXISTS `delivery_notes` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with transaction_headers.id (CTI)',
        `transaction_header_type` varchar(63) NOT NULL DEFAULT 'delivery_note' COMMENT 'CTI discriminator, always delivery_note',
        `delivery_number` varchar(63) NOT NULL COMMENT 'Number printed by the sender',
        `delivery_date` date DEFAULT NULL COMMENT 'Date printed on the note; NULL = none',
        `from_organization_id` bigint unsigned NOT NULL,
        `to_organization_id` bigint unsigned NOT NULL,
        `vehicle_plate_number` varchar(15) NOT NULL,
        `estimated_arrival_date` date NOT NULL,
        `service_name` varchar(127) NOT NULL COMMENT 'Delivery or logistics service',
        `active_key` tinyint DEFAULT '1' COMMENT '1 = draft or signed; NULL = reversed or deleted',
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_delivery_notes_from_organization_delivery_number_active` (`from_organization_id`, `delivery_number`, `active_key`) COMMENT 'Delivery number is unique per sender',
        KEY `ix_delivery_notes_to_organization_id_estimated_arrival_date` (`to_organization_id`, `estimated_arrival_date`),
        CONSTRAINT `fk_delivery_notes_parent` FOREIGN KEY (`id`, `transaction_header_type`) REFERENCES `transaction_headers` (`id`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_delivery_notes_from_organization_id` FOREIGN KEY (`from_organization_id`) REFERENCES `organizations` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_delivery_notes_to_organization_id` FOREIGN KEY (`to_organization_id`) REFERENCES `organizations` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_delivery_notes_transaction_header_type` CHECK ((`transaction_header_type` = _utf8mb4 'delivery_note')),
        CONSTRAINT `ck_delivery_notes_distinct_organizations` CHECK ((`from_organization_id` <> `to_organization_id`)),
        CONSTRAINT `ck_delivery_notes_active_key` CHECK (((`active_key` is null) or (`active_key` = 1)))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of transaction_headers: who sends goods to whom, by which vehicle, and when';

CREATE TABLE
    IF NOT EXISTS `delivery_note_details` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with transactions.id (CTI)',
        `transaction_type` varchar(63) NOT NULL DEFAULT 'delivery_note_detail' COMMENT 'CTI discriminator, always delivery_note_detail',
        `transaction_header_type` varchar(63) NOT NULL DEFAULT 'delivery_note',
        `delivery_note_id` bigint unsigned NOT NULL COMMENT '= transactions.transaction_header_id',
        `item_id` bigint unsigned NOT NULL,
        `batch_id` bigint unsigned DEFAULT NULL COMMENT 'NULL = not on the note or not created yet',
        `amount` decimal(20, 3) NOT NULL COMMENT 'As written, in unit_of_measurement_id',
        `unit_of_measurement_id` bigint unsigned NOT NULL,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_delivery_note_details_id_delivery_note_id` (`id`, `delivery_note_id`) COMMENT 'Target of fk_incoming_details_delivery_note_line',
        KEY `ix_delivery_note_details_delivery_note_id_item_id` (`delivery_note_id`, `item_id`),
        KEY `ix_delivery_note_details_item_id` (`item_id`),
        KEY `ix_delivery_note_details_batch_id_item_id` (`batch_id`, `item_id`),
        KEY `ix_delivery_note_details_unit_of_measurement_id` (`unit_of_measurement_id`),
        CONSTRAINT `fk_delivery_note_details_parent` FOREIGN KEY (`id`, `transaction_type`, `transaction_header_type`) REFERENCES `transactions` (`id`, `transaction_type`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_delivery_note_details_own_header` FOREIGN KEY (`id`, `delivery_note_id`) REFERENCES `transactions` (`id`, `transaction_header_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_delivery_note_details_delivery_note_id` FOREIGN KEY (`delivery_note_id`) REFERENCES `delivery_notes` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_delivery_note_details_item_id` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_delivery_note_details_batch_item` FOREIGN KEY (`batch_id`, `item_id`) REFERENCES `batches` (`id`, `item_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_delivery_note_details_unit_of_measurement_id` FOREIGN KEY (`unit_of_measurement_id`) REFERENCES `unit_of_measurements` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_delivery_note_details_types` CHECK (
            (
                (`transaction_type` = _utf8mb4 'delivery_note_detail')
                and (`transaction_header_type` = _utf8mb4 'delivery_note')
            )
        ),
        CONSTRAINT `ck_delivery_note_details_amount_positive` CHECK ((`amount` > 0))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of transactions: items, batches and quantities written on a delivery note';
