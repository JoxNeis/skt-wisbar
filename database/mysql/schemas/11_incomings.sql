CREATE TABLE
    IF NOT EXISTS `incomings` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with transaction_headers.id (CTI)',
        `transaction_header_type` varchar(63) NOT NULL DEFAULT 'incoming' COMMENT 'CTI discriminator, always incoming',
        `delivery_note_id` bigint unsigned NOT NULL,
        `from_organization_id` bigint unsigned NOT NULL COMMENT 'Actual sender',
        `to_organization_id` bigint unsigned NOT NULL COMMENT 'Actual receiver',
        `vehicle_plate_number` varchar(15) NOT NULL COMMENT 'Vehicle that actually arrived',
        `driver_name` varchar(127) DEFAULT NULL,
        `actual_arrival_date` date NOT NULL COMMENT 'Location local date',
        `service_name` varchar(127) NOT NULL COMMENT 'Service that actually delivered',
        `active_key` tinyint DEFAULT '1' COMMENT '1 = draft or signed; NULL = reversed or deleted',
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_incomings_id_delivery_note_id` (`id`, `delivery_note_id`) COMMENT 'Target of fk_incoming_details_incoming',
        UNIQUE KEY `uq_incomings_delivery_note_id_active_key` (`delivery_note_id`, `active_key`) COMMENT 'One active incoming per delivery note',
        KEY `ix_incomings_to_organization_id_actual_arrival_date` (`to_organization_id`, `actual_arrival_date`),
        KEY `ix_incomings_from_organization_id` (`from_organization_id`),
        CONSTRAINT `fk_incomings_parent` FOREIGN KEY (`id`, `transaction_header_type`) REFERENCES `transaction_headers` (`id`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_incomings_delivery_note_id` FOREIGN KEY (`delivery_note_id`) REFERENCES `delivery_notes` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_incomings_from_organization_id` FOREIGN KEY (`from_organization_id`) REFERENCES `organizations` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_incomings_to_organization_id` FOREIGN KEY (`to_organization_id`) REFERENCES `organizations` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_incomings_transaction_header_type` CHECK ((`transaction_header_type` = _utf8mb4 'incoming')),
        CONSTRAINT `ck_incomings_distinct_organizations` CHECK ((`from_organization_id` <> `to_organization_id`)),
        CONSTRAINT `ck_incomings_active_key` CHECK (((`active_key` is null) or (`active_key` = 1)))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of transaction_headers: goods received against a delivery note';

CREATE TABLE
    IF NOT EXISTS `incoming_details` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with transactions.id (CTI)',
        `transaction_type` varchar(63) NOT NULL DEFAULT 'incoming_detail' COMMENT 'CTI discriminator, always incoming_detail',
        `transaction_header_type` varchar(63) NOT NULL DEFAULT 'incoming',
        `incoming_id` bigint unsigned NOT NULL COMMENT '= transactions.transaction_header_id',
        `delivery_note_id` bigint unsigned NOT NULL COMMENT 'Denormalized from the incoming',
        `delivery_note_detail_id` bigint unsigned DEFAULT NULL COMMENT 'Line compared with; NULL = not on the delivery note',
        `batch_id` bigint unsigned NOT NULL,
        `amount` decimal(20, 3) NOT NULL COMMENT 'As counted, in unit_of_measurement_id',
        `unit_of_measurement_id` bigint unsigned NOT NULL,
        `base_amount` decimal(20, 3) NOT NULL COMMENT 'In the item base unit; set by trigger',
        `acceptance` enum ('accepted', 'rejected') NOT NULL DEFAULT 'accepted' COMMENT 'accepted = to a storage bin; rejected = to a quarantine bin',
        `reject_reason` varchar(255) DEFAULT NULL COMMENT 'Required when rejected',
        `remarks` text DEFAULT NULL,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_incoming_details_id_incoming_id` (`id`, `incoming_id`) COMMENT 'Target of fk_weighings_incoming_line',
        KEY `ix_incoming_details_incoming` (`incoming_id`, `delivery_note_id`),
        KEY `ix_incoming_details_delivery_note_line` (`delivery_note_detail_id`, `delivery_note_id`),
        KEY `ix_incoming_details_acceptance` (`acceptance`),
        KEY `ix_incoming_details_batch_id` (`batch_id`),
        KEY `ix_incoming_details_unit_of_measurement_id` (`unit_of_measurement_id`),
        CONSTRAINT `fk_incoming_details_parent` FOREIGN KEY (`id`, `transaction_type`, `transaction_header_type`) REFERENCES `transactions` (`id`, `transaction_type`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_incoming_details_own_header` FOREIGN KEY (`id`, `incoming_id`) REFERENCES `transactions` (`id`, `transaction_header_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_incoming_details_incoming` FOREIGN KEY (`incoming_id`, `delivery_note_id`) REFERENCES `incomings` (`id`, `delivery_note_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_incoming_details_delivery_note_line` FOREIGN KEY (`delivery_note_detail_id`, `delivery_note_id`) REFERENCES `delivery_note_details` (`id`, `delivery_note_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_incoming_details_batch_id` FOREIGN KEY (`batch_id`) REFERENCES `batches` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_incoming_details_unit_of_measurement_id` FOREIGN KEY (`unit_of_measurement_id`) REFERENCES `unit_of_measurements` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_incoming_details_types` CHECK (
            (
                (`transaction_type` = _utf8mb4 'incoming_detail')
                and (`transaction_header_type` = _utf8mb4 'incoming')
            )
        ),
        CONSTRAINT `ck_incoming_details_amounts_positive` CHECK (
            (
                (`amount` > 0)
                and (`base_amount` > 0)
            )
        )
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of transactions: batches and quantities received, accepted or rejected';

CREATE TABLE
    IF NOT EXISTS `weighings` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with transactions.id (CTI)',
        `transaction_type` varchar(63) NOT NULL DEFAULT 'weighing' COMMENT 'CTI discriminator, always weighing',
        `transaction_header_type` varchar(63) NOT NULL DEFAULT 'incoming',
        `incoming_id` bigint unsigned NOT NULL COMMENT '= transactions.transaction_header_id',
        `incoming_detail_id` bigint unsigned NOT NULL COMMENT 'Weighed line',
        `box_count` int unsigned NOT NULL,
        `written_net_weight` decimal(20, 3) NOT NULL COMMENT 'As stated on the document or label',
        `written_gross_weight` decimal(20, 3) NOT NULL COMMENT 'As stated on the document or label',
        `actual_packaging_weight` decimal(20, 3) NOT NULL COMMENT 'Boxes, ropes, plastic',
        `actual_gross_weight` decimal(20, 3) NOT NULL,
        `measured_net_weight` decimal(21, 3) GENERATED ALWAYS AS ((`actual_gross_weight` - `actual_packaging_weight`)) STORED,
        `net_weight_variance` decimal(22, 3) GENERATED ALWAYS AS (((`actual_gross_weight` - `actual_packaging_weight`) - `written_net_weight`)) STORED COMMENT 'Negative = shortage',
        `weight_unit_of_measurement_id` bigint unsigned NOT NULL COMMENT 'Unit of every weight; a mass unit',
        `weight_unit_type` enum ('length', 'volume', 'mass', 'count') NOT NULL DEFAULT 'mass' COMMENT 'Always mass',
        `moisture_content` decimal(6, 3) DEFAULT NULL COMMENT 'Percent; NULL = not measured',
        `remarks` text DEFAULT NULL,
        `weighed_by` bigint unsigned NOT NULL,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        KEY `ix_weighings_weighed_by` (`weighed_by`),
        CONSTRAINT `fk_weighings_parent` FOREIGN KEY (`id`, `transaction_type`, `transaction_header_type`) REFERENCES `transactions` (`id`, `transaction_type`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_weighings_own_header` FOREIGN KEY (`id`, `incoming_id`) REFERENCES `transactions` (`id`, `transaction_header_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_weighings_incoming_line` FOREIGN KEY (`incoming_detail_id`, `incoming_id`) REFERENCES `incoming_details` (`id`, `incoming_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_weighings_weight_unit` FOREIGN KEY (`weight_unit_of_measurement_id`, `weight_unit_type`) REFERENCES `unit_of_measurements` (`id`, `type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_weighings_weighed_by` FOREIGN KEY (`weighed_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_weighings_types` CHECK (
            (
                (`transaction_type` = _utf8mb4 'weighing')
                and (`transaction_header_type` = _utf8mb4 'incoming')
                and (`weight_unit_type` = _utf8mb4 'mass')
            )
        ),
        CONSTRAINT `ck_weighings_actual_gross_covers_packaging` CHECK ((`actual_gross_weight` >= `actual_packaging_weight`)),
        CONSTRAINT `ck_weighings_actual_packaging_weight_not_negative` CHECK ((`actual_packaging_weight` >= 0)),
        CONSTRAINT `ck_weighings_box_count_positive` CHECK ((`box_count` > 0)),
        CONSTRAINT `ck_weighings_written_gross_covers_net` CHECK ((`written_gross_weight` >= `written_net_weight`)),
        CONSTRAINT `ck_weighings_written_net_weight_not_negative` CHECK ((`written_net_weight` >= 0)),
        CONSTRAINT `ck_weighings_moisture_content_range` CHECK (
            (
                (`moisture_content` is null)
                or (`moisture_content` between 0 and 100)
            )
        )
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of transactions: written and measured weights of a received line';
