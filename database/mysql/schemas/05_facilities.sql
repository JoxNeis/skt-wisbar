CREATE TABLE
    IF NOT EXISTS `facilities` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `location_area_id` bigint unsigned NOT NULL,
        `location_id` bigint unsigned NOT NULL COMMENT 'Denormalized from the area, for filtering by location',
        `facility_type` enum ('warehouse', 'production') NOT NULL COMMENT 'CTI discriminator',
        `name` varchar(255) NOT NULL,
        `code` varchar(15) NOT NULL COMMENT 'Unique within the area',
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_facilities_id_facility_type` (`id`, `facility_type`) COMMENT 'Target of the subtype FKs',
        UNIQUE KEY `uq_facilities_area_id_code` (`location_area_id`, `code`, (nullif(`is_deleted`, 1))),
        KEY `ix_facilities_location_id_facility_type` (`location_id`, `facility_type`),
        CONSTRAINT `fk_facilities_area_location` FOREIGN KEY (`location_area_id`, `location_id`) REFERENCES `location_areas` (`id`, `location_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI parent of warehouses and productions';

CREATE TABLE
    IF NOT EXISTS `warehouses` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with facilities.id (CTI)',
        `facility_type` enum ('warehouse', 'production') NOT NULL DEFAULT 'warehouse' COMMENT 'CTI discriminator, always warehouse',
        `warehouse_type` enum ('main', 'production', 'quarantine') NOT NULL COMMENT 'production = serves a production facility; quarantine = rejected stock only',
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_warehouses_id_warehouse_type` (`id`, `warehouse_type`) COMMENT 'Target of the subtype FKs',
        KEY `ix_warehouses_warehouse_type` (`warehouse_type`),
        CONSTRAINT `fk_warehouses_parent` FOREIGN KEY (`id`, `facility_type`) REFERENCES `facilities` (`id`, `facility_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_warehouses_facility_type` CHECK ((`facility_type` = _utf8mb4 'warehouse'))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of facilities, CTI parent of production_warehouses';

CREATE TABLE
    IF NOT EXISTS `warehouse_bins` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `warehouse_id` bigint unsigned NOT NULL,
        `name` varchar(255) NOT NULL,
        `code` varchar(15) NOT NULL COMMENT 'Unique within the warehouse; what staff scan',
        `hall` varchar(15) DEFAULT NULL,
        `column` varchar(15) DEFAULT NULL,
        `position` varchar(15) DEFAULT NULL,
        `sort_sequence` int unsigned NOT NULL DEFAULT '0' COMMENT 'Fill order for automatic plotting, ascending',
        `maximum_pallet_amount` int unsigned NOT NULL COMMENT 'Physical size in pallets',
        `type` enum ('buffer', 'storage', 'staging', 'quarantine') NOT NULL COMMENT 'buffer = receiving, staging = picked stock awaiting handover',
        `is_active` tinyint NOT NULL DEFAULT '1' COMMENT '1 = accepts new plottings and put-aways',
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_warehouse_bins_id_warehouse_id` (`id`, `warehouse_id`) COMMENT 'Target of (warehouse_bin_id, warehouse_id) FKs',
        UNIQUE KEY `uq_warehouse_bins_warehouse_id_code` (`warehouse_id`, `code`, (nullif(`is_deleted`, 1))),
        KEY `ix_warehouse_bins_warehouse_id_type_is_active` (`warehouse_id`, `type`, `is_active`),
        KEY `ix_warehouse_bins_warehouse_id_sort_sequence` (`warehouse_id`, `sort_sequence`),
        CONSTRAINT `fk_warehouse_bins_warehouse_id` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_warehouse_bins_maximum_pallet_amount_positive` CHECK ((`maximum_pallet_amount` > 0))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Bins within warehouses; every stock location is a bin';

CREATE TABLE
    IF NOT EXISTS `warehouse_bin_designations` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `warehouse_bin_id` bigint unsigned NOT NULL,
        `item_id` bigint unsigned NOT NULL,
        `valid_from` datetime NOT NULL,
        `valid_until` datetime DEFAULT NULL COMMENT 'NULL = open-ended',
        `maximum_amount` decimal(20, 3) NOT NULL COMMENT 'Most of the item the bin may hold, in the item base unit',
        `designated_by` bigint unsigned NOT NULL,
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_warehouse_bin_designations_bin_item_valid_from` (
            `warehouse_bin_id`,
            `item_id`,
            `valid_from`,
            (nullif(`is_deleted`, 1))
        ),
        KEY `ix_warehouse_bin_designations_bin_valid_from_valid_until` (`warehouse_bin_id`, `valid_from`, `valid_until`),
        KEY `ix_warehouse_bin_designations_item_id_valid_from` (`item_id`, `valid_from`),
        KEY `ix_warehouse_bin_designations_designated_by` (`designated_by`),
        CONSTRAINT `fk_warehouse_bin_designations_warehouse_bin_id` FOREIGN KEY (`warehouse_bin_id`) REFERENCES `warehouse_bins` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_warehouse_bin_designations_item_id` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_warehouse_bin_designations_designated_by` FOREIGN KEY (`designated_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_warehouse_bin_designations_maximum_amount_positive` CHECK ((`maximum_amount` > 0)),
        CONSTRAINT `ck_warehouse_bin_designations_validity_period` CHECK (
            (
                (`valid_until` is null)
                or (`valid_until` >= `valid_from`)
            )
        )
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Item each bin is designated to and its capacity, per time range';

CREATE TABLE
    IF NOT EXISTS `warehouse_bin_inventories` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `warehouse_bin_id` bigint unsigned NOT NULL,
        `batch_id` bigint unsigned NOT NULL,
        `current_amount` decimal(20, 3) NOT NULL DEFAULT '0.000' COMMENT 'In the item base unit',
        `current_pallet_amount` int unsigned NOT NULL DEFAULT '0' COMMENT '0 when the item type does not use pallets',
        `filled_at` datetime DEFAULT NULL COMMENT 'Last time stock went above zero (FIFO); set by trigger',
        `depleted_at` datetime DEFAULT NULL COMMENT 'Last time stock hit zero; set by trigger',
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_warehouse_bin_inventories_bin_batch` (`warehouse_bin_id`, `batch_id`),
        UNIQUE KEY `uq_warehouse_bin_inventories_id_batch_id` (`id`, `batch_id`) COMMENT 'Target of fk_inventory_reservations_bin_inventory_batch',
        KEY `ix_warehouse_bin_inventories_batch_id_filled_at` (`batch_id`, `filled_at`) COMMENT 'FIFO',
        KEY `ix_warehouse_bin_inventories_depleted_at` (`depleted_at`),
        CONSTRAINT `fk_warehouse_bin_inventories_warehouse_bin_id` FOREIGN KEY (`warehouse_bin_id`) REFERENCES `warehouse_bins` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_warehouse_bin_inventories_batch_id` FOREIGN KEY (`batch_id`) REFERENCES `batches` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_warehouse_bin_inventories_current_amount_non_negative` CHECK ((`current_amount` >= 0))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Stock of each batch in each bin (cache of the signed stock_movement_details); rows are never deleted';

CREATE TABLE
    IF NOT EXISTS `productions` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with facilities.id (CTI)',
        `facility_type` enum ('warehouse', 'production') NOT NULL DEFAULT 'production' COMMENT 'CTI discriminator, always production',
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        CONSTRAINT `fk_productions_parent` FOREIGN KEY (`id`, `facility_type`) REFERENCES `facilities` (`id`, `facility_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_productions_facility_type` CHECK ((`facility_type` = _utf8mb4 'production'))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of facilities: production facilities';

CREATE TABLE
    IF NOT EXISTS `production_warehouses` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with warehouses.id (CTI)',
        `warehouse_type` enum ('main', 'production', 'quarantine') NOT NULL DEFAULT 'production' COMMENT 'CTI discriminator, always production',
        `storage_type` enum ('staging', 'return') NOT NULL DEFAULT 'staging' COMMENT 'staging = handed over to production; return = leftover kept for the next day',
        `production_id` bigint unsigned NOT NULL,
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_production_warehouses_id_production_id_storage_type` (`id`, `production_id`, `storage_type`) COMMENT 'Target of FKs that need a staging or return warehouse of one production',
        KEY `ix_production_warehouses_id_warehouse_type` (`id`, `warehouse_type`),
        KEY `ix_production_warehouses_production_id_storage_type` (`production_id`, `storage_type`),
        CONSTRAINT `fk_production_warehouses_parent` FOREIGN KEY (`id`, `warehouse_type`) REFERENCES `warehouses` (`id`, `warehouse_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_warehouses_production_id` FOREIGN KEY (`production_id`) REFERENCES `productions` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_production_warehouses_warehouse_type` CHECK ((`warehouse_type` = _utf8mb4 'production'))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of warehouses: staging and return warehouses of a production facility';

CREATE TABLE
    IF NOT EXISTS `production_groups` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `production_id` bigint unsigned NOT NULL,
        `name` varchar(255) NOT NULL,
        `code` varchar(15) NOT NULL,
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_production_groups_code` (`code`, (nullif(`is_deleted`, 1))),
        UNIQUE KEY `uq_production_groups_id_production_id` (`id`, `production_id`) COMMENT 'Target of (production_group_id, production_id) FKs',
        KEY `ix_production_groups_production_id` (`production_id`),
        CONSTRAINT `fk_production_groups_production_id` FOREIGN KEY (`production_id`) REFERENCES `productions` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Production groups of a production facility';

CREATE TABLE
    IF NOT EXISTS `production_group_brands` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `production_group_id` bigint unsigned NOT NULL,
        `brand_id` bigint unsigned NOT NULL,
        `valid_from` date NOT NULL COMMENT 'Inclusive, location local date',
        `valid_until` date DEFAULT NULL COMMENT 'Inclusive; NULL = open-ended',
        `administered_by` bigint unsigned NOT NULL,
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_production_group_brands_group_brand_valid_from` (
            `production_group_id`,
            `brand_id`,
            `valid_from`,
            (nullif(`is_deleted`, 1))
        ),
        KEY `ix_production_group_brands_brand_id_valid_from` (`brand_id`, `valid_from`),
        KEY `ix_production_group_brands_administered_by` (`administered_by`),
        CONSTRAINT `fk_production_group_brands_production_group_id` FOREIGN KEY (`production_group_id`) REFERENCES `production_groups` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_group_brands_brand_id` FOREIGN KEY (`brand_id`) REFERENCES `brands` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_group_brands_administered_by` FOREIGN KEY (`administered_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_production_group_brands_validity_period` CHECK (
            (
                (`valid_until` is null)
                or (`valid_until` >= `valid_from`)
            )
        )
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Brands each production group handles, per date range';

CREATE TABLE
    IF NOT EXISTS `production_return_bins` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `production_id` bigint unsigned NOT NULL,
        `warehouse_id` bigint unsigned NOT NULL COMMENT 'Denormalized from the bin; must be a return storage of the production',
        `storage_type` enum ('staging', 'return') NOT NULL DEFAULT 'return' COMMENT 'Always return',
        `warehouse_bin_id` bigint unsigned NOT NULL,
        `valid_from` datetime NOT NULL,
        `valid_until` datetime DEFAULT NULL COMMENT 'NULL = open-ended',
        `assigned_by` bigint unsigned NOT NULL,
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_production_return_bins_production_bin_valid_from` (
            `production_id`,
            `warehouse_bin_id`,
            `valid_from`,
            (nullif(`is_deleted`, 1))
        ),
        KEY `ix_production_return_bins_assigned_by` (`assigned_by`),
        CONSTRAINT `fk_production_return_bins_bin` FOREIGN KEY (`warehouse_bin_id`, `warehouse_id`) REFERENCES `warehouse_bins` (`id`, `warehouse_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_return_bins_production_warehouse` FOREIGN KEY (`warehouse_id`, `production_id`, `storage_type`) REFERENCES `production_warehouses` (`id`, `production_id`, `storage_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_return_bins_assigned_by` FOREIGN KEY (`assigned_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_production_return_bins_storage_type` CHECK ((`storage_type` = _utf8mb4 'return')),
        CONSTRAINT `ck_production_return_bins_validity_period` CHECK (
            (
                (`valid_until` is null)
                or (`valid_until` >= `valid_from`)
            )
        )
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Bins that receive the end-of-day leftover of a production';
