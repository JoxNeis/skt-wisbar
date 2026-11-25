CREATE TABLE
    IF NOT EXISTS `stock_reversals` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with stock_movements.id (CTI)',
        `transaction_header_type` varchar(63) NOT NULL DEFAULT 'stock_reversal' COMMENT 'CTI discriminator, always stock_reversal',
        `reversed_transaction_header_id` bigint unsigned NOT NULL COMMENT 'Signed stock document this cancels',
        `reversed_header_type` varchar(63) NOT NULL COMMENT 'Never stock_reversal: a reversal is not reversed',
        `active_key` tinyint DEFAULT '1' COMMENT '1 = draft or signed; NULL = deleted',
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_stock_reversals_id_reversed_header_id` (`id`, `reversed_transaction_header_id`) COMMENT 'Target of fk_stock_reversal_details_reversal',
        UNIQUE KEY `uq_stock_reversals_reversed_header_active_key` (`reversed_transaction_header_id`, `active_key`) COMMENT 'One active reversal per document',
        KEY `ix_stock_reversals_reversed_header` (`reversed_transaction_header_id`, `reversed_header_type`),
        CONSTRAINT `fk_stock_reversals_parent` FOREIGN KEY (`id`, `transaction_header_type`) REFERENCES `stock_movements` (`id`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_stock_reversals_reversed_document` FOREIGN KEY (`reversed_transaction_header_id`, `reversed_header_type`) REFERENCES `stock_movements` (`id`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_stock_reversals_types` CHECK (
            (
                (`transaction_header_type` = _utf8mb4 'stock_reversal')
                and (`reversed_header_type` <> _utf8mb4 'stock_reversal')
            )
        ),
        CONSTRAINT `ck_stock_reversals_active_key` CHECK (((`active_key` is null) or (`active_key` = 1)))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of stock_movements: cancels a signed stock document; signing it reverses that document';

CREATE TABLE
    IF NOT EXISTS `stock_reversal_details` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with stock_movement_details.id (CTI)',
        `transaction_type` varchar(63) NOT NULL DEFAULT 'stock_reversal_detail' COMMENT 'CTI discriminator, always stock_reversal_detail',
        `transaction_header_type` varchar(63) NOT NULL DEFAULT 'stock_reversal',
        `stock_reversal_id` bigint unsigned NOT NULL COMMENT '= transactions.transaction_header_id',
        `reversed_transaction_header_id` bigint unsigned NOT NULL COMMENT 'Denormalized from the reversal',
        `reverses_stock_movement_detail_id` bigint unsigned NOT NULL COMMENT 'Original line; this line is its exact opposite',
        `active_key` tinyint DEFAULT '1' COMMENT '1 = draft or signed; NULL = deleted',
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_stock_reversal_details_reverses_active_key` (`reverses_stock_movement_detail_id`, `active_key`) COMMENT 'A line is reversed by one active line only',
        KEY `ix_stock_reversal_details_reversal` (`stock_reversal_id`, `reversed_transaction_header_id`),
        KEY `ix_stock_reversal_details_original_line` (`reverses_stock_movement_detail_id`, `reversed_transaction_header_id`),
        CONSTRAINT `fk_stock_reversal_details_parent` FOREIGN KEY (`id`, `transaction_type`, `transaction_header_type`) REFERENCES `stock_movement_details` (`id`, `transaction_type`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_stock_reversal_details_own_header` FOREIGN KEY (`id`, `stock_reversal_id`) REFERENCES `transactions` (`id`, `transaction_header_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_stock_reversal_details_reversal` FOREIGN KEY (`stock_reversal_id`, `reversed_transaction_header_id`) REFERENCES `stock_reversals` (`id`, `reversed_transaction_header_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_stock_reversal_details_original_line` FOREIGN KEY (`reverses_stock_movement_detail_id`) REFERENCES `stock_movement_details` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_stock_reversal_details_original_document` FOREIGN KEY (`reverses_stock_movement_detail_id`, `reversed_transaction_header_id`) REFERENCES `transactions` (`id`, `transaction_header_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_stock_reversal_details_types` CHECK (
            (
                (`transaction_type` = _utf8mb4 'stock_reversal_detail')
                and (`transaction_header_type` = _utf8mb4 'stock_reversal')
            )
        ),
        CONSTRAINT `ck_stock_reversal_details_active_key` CHECK (((`active_key` is null) or (`active_key` = 1)))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of stock_movement_details: the exact opposite of one line of the reversed document';
