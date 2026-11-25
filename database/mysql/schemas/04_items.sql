CREATE TABLE
    IF NOT EXISTS `brands` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `name` varchar(255) NOT NULL,
        `code` varchar(15) NOT NULL,
        `display` varchar(273) GENERATED ALWAYS AS (concat(`code`, _utf8mb4 ' - ', `name`)) VIRTUAL,
        `valid_from` datetime NOT NULL,
        `valid_until` datetime DEFAULT NULL COMMENT 'NULL = never expires',
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_brands_code` (`code`, (nullif(`is_deleted`, 1))),
        CONSTRAINT `ck_brands_validity_period` CHECK (
            (
                (`valid_until` is null)
                or (`valid_until` >= `valid_from`)
            )
        )
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Brands and their validity period';

CREATE TABLE
    IF NOT EXISTS `item_types` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `name` varchar(127) NOT NULL,
        `code` varchar(15) NOT NULL,
        `default_unit_of_measurement_id` bigint unsigned NOT NULL COMMENT 'Base unit for a new item of this type',
        `default_days_to_expiry` int unsigned DEFAULT NULL COMMENT 'Shelf life in days; NULL = no default',
        `need_pallet` tinyint NOT NULL DEFAULT '1' COMMENT '1 = stock is also tracked in pallets',
        `need_weighing` tinyint NOT NULL DEFAULT '0' COMMENT '1 = weighed on arrival (weighings)',
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_item_types_code` (`code`, (nullif(`is_deleted`, 1))),
        KEY `ix_item_types_default_unit_of_measurement_id` (`default_unit_of_measurement_id`),
        CONSTRAINT `fk_item_types_default_unit_of_measurement_id` FOREIGN KEY (`default_unit_of_measurement_id`) REFERENCES `unit_of_measurements` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Item types (materials) with their default unit and handling needs';

CREATE TABLE
    IF NOT EXISTS `items` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `brand_id` bigint unsigned NOT NULL,
        `item_type_id` bigint unsigned NOT NULL,
        `name` varchar(255) NOT NULL,
        `code` varchar(15) NOT NULL,
        `fa_code` varchar(63) DEFAULT NULL COMMENT 'Fixed-asset or alternate code',
        `display` varchar(273) GENERATED ALWAYS AS (concat(`code`, _utf8mb4 ' - ', `name`)) VIRTUAL,
        `valid_from` date DEFAULT NULL COMMENT 'NULL = no start date',
        `valid_until` date DEFAULT NULL COMMENT 'NULL = never expires',
        `unit_of_measurement_id` bigint unsigned NOT NULL COMMENT 'Base unit: every stock amount of the item is in this unit',
        `days_to_expiry` int unsigned DEFAULT NULL COMMENT 'Shelf life in days; NULL = item type default',
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_items_code` (`code`, (nullif(`is_deleted`, 1))),
        UNIQUE KEY `uq_items_fa_code` (`fa_code`, (nullif(`is_deleted`, 1))),
        KEY `ix_items_brand_id` (`brand_id`),
        KEY `ix_items_item_type_id` (`item_type_id`),
        KEY `ix_items_unit_of_measurement_id` (`unit_of_measurement_id`),
        KEY `ix_items_name` (`name`),
        CONSTRAINT `fk_items_brand_id` FOREIGN KEY (`brand_id`) REFERENCES `brands` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_items_item_type_id` FOREIGN KEY (`item_type_id`) REFERENCES `item_types` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_items_unit_of_measurement_id` FOREIGN KEY (`unit_of_measurement_id`) REFERENCES `unit_of_measurements` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_items_validity_period` CHECK (
            (
                (`valid_until` is null)
                or (`valid_from` is null)
                or (`valid_until` >= `valid_from`)
            )
        )
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Item master data and base unit';

CREATE TABLE
    IF NOT EXISTS `item_unit_conversions` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `item_id` bigint unsigned NOT NULL,
        `unit_of_measurement_id` bigint unsigned NOT NULL COMMENT 'Any unit except the item base unit',
        `factor_to_base` decimal(20, 6) NOT NULL COMMENT 'Base units in one of this unit, e.g. 25 when 1 box = 25 kg',
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_item_unit_conversions_item_id_unit_id` (
            `item_id`,
            `unit_of_measurement_id`,
            (nullif(`is_deleted`, 1))
        ),
        KEY `ix_item_unit_conversions_unit_of_measurement_id` (`unit_of_measurement_id`),
        CONSTRAINT `fk_item_unit_conversions_item_id` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_item_unit_conversions_unit_of_measurement_id` FOREIGN KEY (`unit_of_measurement_id`) REFERENCES `unit_of_measurements` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_item_unit_conversions_factor_positive` CHECK ((`factor_to_base` > 0))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Conversion of other units into the item base unit; to change a factor, delete the row and add a new one';

CREATE TABLE
    IF NOT EXISTS `item_attachments` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `item_id` bigint unsigned NOT NULL,
        `attachment_id` bigint unsigned NOT NULL,
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_item_attachments_attachment_id` (`attachment_id`, (nullif(`is_deleted`, 1))),
        KEY `ix_item_attachments_item_id` (`item_id`),
        CONSTRAINT `fk_item_attachments_attachment_id` FOREIGN KEY (`attachment_id`) REFERENCES `attachments` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT,
        CONSTRAINT `fk_item_attachments_item_id` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Files attached to items';

CREATE TABLE
    IF NOT EXISTS `batches` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `item_id` bigint unsigned NOT NULL,
        `origin_organization_id` bigint unsigned NOT NULL COMMENT 'Vendor or sender; our own location for in-house batches',
        `batch_code` varchar(100) NOT NULL COMMENT 'As printed on the label',
        `production_date` date DEFAULT NULL COMMENT 'NULL = unknown',
        `expiry_date` date DEFAULT NULL COMMENT 'NULL = no expiry; used for FEFO',
        `quality_status` enum ('released', 'on_hold', 'rejected') NOT NULL DEFAULT 'released' COMMENT 'released = may be allocated; on_hold = blocked in every bin; rejected = never usable',
        `administered_by` bigint unsigned NOT NULL,
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_batches_id_item_id` (`id`, `item_id`) COMMENT 'Target of (batch_id, item_id) FKs',
        UNIQUE KEY `uq_batches_item_id_origin_organization_id_batch_code` (
            `item_id`,
            `origin_organization_id`,
            `batch_code`,
            (nullif(`is_deleted`, 1))
        ),
        KEY `ix_batches_item_id_expiry_date` (`item_id`, `expiry_date`) COMMENT 'FEFO',
        KEY `ix_batches_origin_organization_id` (`origin_organization_id`),
        KEY `ix_batches_administered_by` (`administered_by`),
        CONSTRAINT `fk_batches_item_id` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_batches_origin_organization_id` FOREIGN KEY (`origin_organization_id`) REFERENCES `organizations` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_batches_administered_by` FOREIGN KEY (`administered_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_batches_expiry_after_production` CHECK (
            (
                (`expiry_date` is null)
                or (`production_date` is null)
                or (`expiry_date` >= `production_date`)
            )
        )
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Batches of an item, with origin and quality status';

CREATE TABLE
    IF NOT EXISTS `location_brands` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `location_id` bigint unsigned NOT NULL,
        `brand_id` bigint unsigned NOT NULL,
        `valid_from` date NOT NULL COMMENT 'Inclusive, location local date',
        `valid_until` date DEFAULT NULL COMMENT 'Inclusive; NULL = open-ended',
        `administered_by` bigint unsigned NOT NULL,
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_location_brands_location_brand_valid_from` (
            `location_id`,
            `brand_id`,
            `valid_from`,
            (nullif(`is_deleted`, 1))
        ),
        KEY `ix_location_brands_location_valid_from_valid_until` (`location_id`, `valid_from`, `valid_until`),
        KEY `ix_location_brands_brand_id_valid_from` (`brand_id`, `valid_from`),
        KEY `ix_location_brands_administered_by` (`administered_by`),
        CONSTRAINT `fk_location_brands_location_id` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_location_brands_brand_id` FOREIGN KEY (`brand_id`) REFERENCES `brands` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_location_brands_administered_by` FOREIGN KEY (`administered_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_location_brands_validity_period` CHECK (
            (
                (`valid_until` is null)
                or (`valid_until` >= `valid_from`)
            )
        )
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Brands each location handles, per date range';
