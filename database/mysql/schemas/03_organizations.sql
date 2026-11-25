CREATE TABLE
    IF NOT EXISTS `organizations` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `organization_type` enum ('location', 'vendor') NOT NULL COMMENT 'CTI discriminator; partner has no subtype table',
        `name` varchar(255) NOT NULL,
        `code` varchar(15) NOT NULL,
        `display` varchar(273) GENERATED ALWAYS AS (concat(`code`, _utf8mb4 ' - ', `name`)) VIRTUAL,
        `address` varchar(511) DEFAULT NULL,
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_organizations_id_organization_type` (`id`, `organization_type`) COMMENT 'Target of the subtype FKs',
        UNIQUE KEY `uq_organizations_code` (`code`, (nullif(`is_deleted`, 1))),
        KEY `ix_organizations_organization_type` (`organization_type`),
        KEY `ix_organizations_name` (`name`)
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI parent of every company: our locations, vendors and partners';

CREATE TABLE
    IF NOT EXISTS `vendors` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with organizations.id (CTI)',
        `organization_type` enum ('location', 'vendor', 'partner') NOT NULL DEFAULT 'vendor' COMMENT 'CTI discriminator, always vendor',
        `type` enum ('supplier', 'contractor', 'logistics') DEFAULT NULL COMMENT 'NULL = unspecified',
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        KEY `ix_vendors_type` (`type`),
        CONSTRAINT `fk_vendors_parent` FOREIGN KEY (`id`, `organization_type`) REFERENCES `organizations` (`id`, `organization_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_vendors_organization_type` CHECK ((`organization_type` = _utf8mb4 'vendor'))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of organizations: suppliers, contractors and logistics companies';

CREATE TABLE
    IF NOT EXISTS `locations` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with organizations.id (CTI)',
        `organization_type` enum ('location', 'vendor', 'partner') NOT NULL DEFAULT 'location' COMMENT 'CTI discriminator, always location',
        `type` enum ('inhouse', 'tpo') NOT NULL COMMENT 'inhouse = run by us, tpo = run by a third party',
        `time_zone` enum ('wib', 'wita', 'wit') NOT NULL DEFAULT 'wib' COMMENT 'Business dates of the location are local dates in this zone',
        `utc_offset` char(6) GENERATED ALWAYS AS (
            (
                case `time_zone`
                    when _utf8mb4 'wib' then _utf8mb4 '+07:00'
                    when _utf8mb4 'wita' then _utf8mb4 '+08:00'
                    when _utf8mb4 'wit' then _utf8mb4 '+09:00'
                end
            )
        ) VIRTUAL COMMENT 'For CONVERT_TZ; Indonesia has no daylight saving',
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        KEY `ix_locations_type` (`type`),
        CONSTRAINT `fk_locations_parent` FOREIGN KEY (`id`, `organization_type`) REFERENCES `organizations` (`id`, `organization_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_locations_organization_type` CHECK ((`organization_type` = _utf8mb4 'location'))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'CTI subtype of organizations: our sites (manufacturing plants)';

CREATE TABLE
    IF NOT EXISTS `location_areas` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `location_id` bigint unsigned NOT NULL,
        `name` varchar(255) NOT NULL,
        `code` varchar(15) NOT NULL COMMENT 'Unique within the location',
        `display` varchar(273) GENERATED ALWAYS AS (concat(`code`, _utf8mb4 ' - ', `name`)) VIRTUAL,
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_location_areas_id_location_id` (`id`, `location_id`) COMMENT 'Target of fk_facilities_area_location',
        UNIQUE KEY `uq_location_areas_location_id_code` (`location_id`, `code`, (nullif(`is_deleted`, 1))),
        CONSTRAINT `fk_location_areas_location_id` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Areas within a location that group warehouses and production facilities';
