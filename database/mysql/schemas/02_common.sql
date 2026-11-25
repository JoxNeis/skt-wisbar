CREATE TABLE
    IF NOT EXISTS `unit_of_measurements` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `type` enum ('length', 'volume', 'mass', 'count') NOT NULL COMMENT 'count = pieces, boxes, rolls, sacks, pallets',
        `name` varchar(100) NOT NULL,
        `code` varchar(30) NOT NULL,
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_unit_of_measurements_id_type` (`id`, `type`) COMMENT 'Target of FKs that accept one unit type only',
        UNIQUE KEY `uq_unit_of_measurements_code` (`code`, (nullif(`is_deleted`, 1)))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Units of measurement';

CREATE TABLE
    IF NOT EXISTS `attachments` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `file_type` enum ('image', 'document', 'other') NOT NULL,
        `file_address` varchar(255) NOT NULL COMMENT 'Storage path, object key or URL',
        `file_name` varchar(255) NOT NULL COMMENT 'Without path',
        `file_extension` varchar(15) NOT NULL COMMENT 'Without leading dot, e.g. pdf',
        `mime_type` varchar(127) DEFAULT NULL,
        `alt_text` text,
        `byte_size` bigint unsigned NOT NULL,
        `valid_from` datetime NOT NULL,
        `valid_until` datetime DEFAULT NULL COMMENT 'NULL = never expires',
        `checksum_sha256` char(64) CHARACTER SET ascii COLLATE ascii_bin DEFAULT NULL,
        `uploaded_by` bigint unsigned NOT NULL,
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        KEY `ix_attachments_checksum_sha256` (`checksum_sha256`),
        KEY `ix_attachments_file_type_created_at` (`file_type`, `created_at`),
        KEY `ix_attachments_uploaded_by` (`uploaded_by`),
        CONSTRAINT `fk_attachments_uploaded_by` FOREIGN KEY (`uploaded_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_attachments_byte_size_positive` CHECK ((`byte_size` > 0)),
        CONSTRAINT `ck_attachments_validity_period` CHECK (
            (
                (`valid_until` is null)
                or (`valid_until` >= `valid_from`)
            )
        )
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Uploaded file metadata and storage reference';
