CREATE TABLE
    IF NOT EXISTS `document_sequences` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `document_type` varchar(63) NOT NULL COMMENT 'A transaction_header_type, or employee',
        `prefix` varchar(15) NOT NULL COMMENT 'May be empty',
        `period_format` varchar(15) DEFAULT '%y%m%d' COMMENT 'DATE_FORMAT pattern after the prefix; NULL = no period',
        `current_period` varchar(15) DEFAULT NULL COMMENT 'The counter resets when the period changes',
        `current_value` bigint unsigned NOT NULL DEFAULT '0' COMMENT 'Last issued number',
        `padding_length` tinyint unsigned NOT NULL DEFAULT '6',
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_document_sequences_document_type` (`document_type`, (nullif(`is_deleted`, 1))),
        CONSTRAINT `ck_document_sequences_padding_length_range` CHECK ((`padding_length` between 1 and 18)),
        CONSTRAINT `ck_document_sequences_document_type` CHECK (
            (
                `document_type` in (
                    _utf8mb4 'production_order',
                    _utf8mb4 'production_return',
                    _utf8mb4 'internal_transfer',
                    _utf8mb4 'outbound',
                    _utf8mb4 'production_reject',
                    _utf8mb4 'stock_movement',
                    _utf8mb4 'picking',
                    _utf8mb4 'put_away',
                    _utf8mb4 'item_reclassification',
                    _utf8mb4 'stock_reversal',
                    _utf8mb4 'incoming',
                    _utf8mb4 'handover',
                    _utf8mb4 'production_group_usage',
                    _utf8mb4 'delivery_note',
                    _utf8mb4 'employee'
                )
            )
        )
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Numbering rule and counter of each document type, shared by every location';

CREATE TABLE
    IF NOT EXISTS `transaction_headers` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `uuid` varchar(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT (uuid()),
        `transaction_header_type` varchar(63) NOT NULL COMMENT 'CTI discriminator: the leaf table that owns the header',
        `location_id` bigint unsigned NOT NULL,
        `document_number` varchar(63) NOT NULL COMMENT 'Never reused, also after a draft is deleted',
        `status` enum ('unsigned', 'signed', 'reversed') NOT NULL DEFAULT 'unsigned' COMMENT 'unsigned = draft; signed = locked; reversed = cancelled after signing',
        `remarks` text DEFAULT NULL,
        `created_by` bigint unsigned NOT NULL COMMENT 'Their supervisor signs the document',
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL COMMENT 'Only a draft can be deleted',
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_transaction_headers_uuid` (`uuid`),
        UNIQUE KEY `uq_transaction_headers_location_type_document_number` (`location_id`, `transaction_header_type`, `document_number`),
        UNIQUE KEY `uq_transaction_headers_id_transaction_header_type` (`id`, `transaction_header_type`) COMMENT 'Target of the subtype FKs',
        KEY `ix_transaction_headers_type_status_created_at` (`transaction_header_type`, `status`, `created_at`),
        KEY `ix_transaction_headers_location_type_created_at` (`location_id`, `transaction_header_type`, `created_at`),
        KEY `ix_transaction_headers_status_created_at` (`status`, `created_at`),
        KEY `ix_transaction_headers_created_by` (`created_by`),
        CONSTRAINT `fk_transaction_headers_location_id` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_transaction_headers_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_transaction_headers_transaction_header_type` CHECK (
            (
                `transaction_header_type` in (
                    _utf8mb4 'production_order',
                    _utf8mb4 'production_return',
                    _utf8mb4 'internal_transfer',
                    _utf8mb4 'outbound',
                    _utf8mb4 'production_reject',
                    _utf8mb4 'stock_movement',
                    _utf8mb4 'picking',
                    _utf8mb4 'put_away',
                    _utf8mb4 'item_reclassification',
                    _utf8mb4 'stock_reversal',
                    _utf8mb4 'incoming',
                    _utf8mb4 'handover',
                    _utf8mb4 'production_group_usage',
                    _utf8mb4 'delivery_note'
                )
            )
        ),
        CONSTRAINT `ck_transaction_headers_uuid_format` CHECK (
            regexp_like (
                `uuid`,
                _utf8mb4 '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
                _utf8mb4 'c'
            )
        )
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI parent of every document: number, lifecycle and creator';

CREATE TABLE
    IF NOT EXISTS `transactions` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `transaction_header_id` bigint unsigned NOT NULL,
        `transaction_header_type` varchar(63) NOT NULL COMMENT 'Denormalized from the header',
        `transaction_type` varchar(63) NOT NULL COMMENT 'CTI discriminator: the leaf line table that owns the line',
        `occurred_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Business time of the operation',
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL COMMENT 'Only lines of a draft can be deleted',
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_transactions_id_types` (`id`, `transaction_type`, `transaction_header_type`) COMMENT 'Target of the subtype FKs',
        UNIQUE KEY `uq_transactions_id_transaction_header_id` (`id`, `transaction_header_id`) COMMENT 'Target of the own-header FKs',
        KEY `ix_transactions_header_id_header_type` (`transaction_header_id`, `transaction_header_type`),
        KEY `ix_transactions_transaction_type_occurred_at` (`transaction_type`, `occurred_at`),
        KEY `ix_transactions_occurred_at` (`occurred_at`),
        CONSTRAINT `fk_transactions_header` FOREIGN KEY (`transaction_header_id`, `transaction_header_type`) REFERENCES `transaction_headers` (`id`, `transaction_header_type`) ON DELETE RESTRICT ON UPDATE RESTRICT
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI parent of every document line';

CREATE TABLE
    IF NOT EXISTS `transaction_header_sign_offs` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `transaction_header_id` bigint unsigned NOT NULL,
        `decision` enum ('signed', 'rejected') NOT NULL COMMENT 'signed = document becomes signed; rejected = stays a draft',
        `remarks` text DEFAULT NULL COMMENT 'Required when rejected',
        `signed_by` bigint unsigned NOT NULL COMMENT 'Supervisor of the document creator',
        `signed_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `hash_algorithm` varchar(15) NOT NULL DEFAULT 'hmac-sha256',
        `hash_key` varchar(128) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT 'Lowercase hex HMAC of the signed payload, made by the API',
        `signed_key` tinyint GENERATED ALWAYS AS (if ((`decision` = _utf8mb4 'signed'), 1, NULL)) STORED COMMENT '1 when signed; NULL when rejected',
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_transaction_header_sign_offs_header_id_signed_key` (`transaction_header_id`, `signed_key`) COMMENT 'One signed sign-off per document',
        UNIQUE KEY `uq_transaction_header_sign_offs_hash_key` (`hash_key`),
        KEY `ix_transaction_header_sign_offs_signed_by_signed_at` (`signed_by`, `signed_at`),
        KEY `ix_transaction_header_sign_offs_decision_signed_at` (`decision`, `signed_at`),
        CONSTRAINT `fk_transaction_header_sign_offs_transaction_header_id` FOREIGN KEY (`transaction_header_id`) REFERENCES `transaction_headers` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_transaction_header_sign_offs_signed_by` FOREIGN KEY (`signed_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_transaction_header_sign_offs_hash_algorithm_format` CHECK (regexp_like (`hash_algorithm`, _utf8mb4 '^[a-z0-9-]+$', _utf8mb4 'c')),
        CONSTRAINT `ck_transaction_header_sign_offs_hash_key_format` CHECK (regexp_like (`hash_key`, _utf8mb4 '^[0-9a-f]{64,128}$', _utf8mb4 'c'))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Append-only sign-off decisions of the creator supervisor; a signed one signs the document';

CREATE TABLE
    IF NOT EXISTS `transaction_attachments` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `transaction_header_id` bigint unsigned NOT NULL,
        `transaction_id` bigint unsigned DEFAULT NULL COMMENT 'Line of the document; NULL = the whole document',
        `attachment_id` bigint unsigned NOT NULL,
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_transaction_attachments_attachment_id` (`attachment_id`, (nullif(`is_deleted`, 1))),
        KEY `ix_transaction_attachments_transaction_header_id` (`transaction_header_id`),
        CONSTRAINT `fk_transaction_attachments_transaction_header_id` FOREIGN KEY (`transaction_header_id`) REFERENCES `transaction_headers` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_transaction_attachments_line` FOREIGN KEY (`transaction_id`, `transaction_header_id`) REFERENCES `transactions` (`id`, `transaction_header_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_transaction_attachments_attachment_id` FOREIGN KEY (`attachment_id`) REFERENCES `attachments` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Files attached to a document or one of its lines; may be added after signing';
