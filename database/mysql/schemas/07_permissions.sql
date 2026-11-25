CREATE TABLE
    IF NOT EXISTS `permissions` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `name` varchar(255) NOT NULL,
        `permission_code` varchar(255) NOT NULL,
        `description` text DEFAULT NULL,
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_permissions_permission_code` (`permission_code`, (nullif(`is_deleted`, 1)))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Application permissions';

CREATE TABLE
    IF NOT EXISTS `jobdesk_permissions` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `permission_id` bigint unsigned NOT NULL,
        `jobdesk_id` bigint unsigned NOT NULL,
        `valid_from` datetime NOT NULL,
        `valid_until` datetime DEFAULT NULL COMMENT 'NULL = never expires',
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_jobdesk_permissions_permission_id_jobdesk_id_valid_from` (
            `permission_id`,
            `jobdesk_id`,
            `valid_from`,
            (nullif(`is_deleted`, 1))
        ),
        KEY `ix_jobdesk_permissions_jobdesk_id_valid_from_valid_until` (`jobdesk_id`, `valid_from`, `valid_until`),
        CONSTRAINT `fk_jobdesk_permissions_permission_id` FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_jobdesk_permissions_jobdesk_id` FOREIGN KEY (`jobdesk_id`) REFERENCES `jobdesks` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_jobdesk_permissions_validity_period` CHECK (
            (
                (`valid_until` is null)
                or (`valid_until` >= `valid_from`)
            )
        )
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Permissions granted to a jobdesk, valid at every location where it is held';

CREATE TABLE
    IF NOT EXISTS `employee_permissions` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `permission_id` bigint unsigned NOT NULL,
        `employee_id` bigint unsigned NOT NULL,
        `location_id` bigint unsigned NOT NULL,
        `valid_from` datetime NOT NULL,
        `valid_until` datetime DEFAULT NULL COMMENT 'NULL = never expires',
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_employee_permissions_permission_employee_location_valid_from` (
            `permission_id`,
            `employee_id`,
            `location_id`,
            `valid_from`,
            (nullif(`is_deleted`, 1))
        ),
        KEY `ix_employee_permissions_employee_id_valid_from_valid_until` (`employee_id`, `valid_from`, `valid_until`),
        KEY `ix_employee_permissions_location_id` (`location_id`),
        CONSTRAINT `fk_employee_permissions_employee_id` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_employee_permissions_permission_id` FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_employee_permissions_location_id` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_employee_permissions_validity_period` CHECK (
            (
                (`valid_until` is null)
                or (`valid_until` >= `valid_from`)
            )
        )
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Permissions granted directly to an employee at one location, e.g. covering for a colleague';

CREATE TABLE
    IF NOT EXISTS `jobdesk_orderable_items` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `jobdesk_id` bigint unsigned NOT NULL,
        `item_id` bigint unsigned NOT NULL,
        `valid_from` datetime NOT NULL,
        `valid_until` datetime DEFAULT NULL COMMENT 'NULL = never expires',
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_jobdesk_orderable_items_jobdesk_item_valid_from` (
            `jobdesk_id`,
            `item_id`,
            `valid_from`,
            (nullif(`is_deleted`, 1))
        ),
        KEY `ix_jobdesk_orderable_items_item_id` (`item_id`),
        CONSTRAINT `fk_jobdesk_orderable_items_jobdesk_id` FOREIGN KEY (`jobdesk_id`) REFERENCES `jobdesks` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_jobdesk_orderable_items_item_id` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_jobdesk_orderable_items_validity_period` CHECK (
            (
                (`valid_until` is null)
                or (`valid_until` >= `valid_from`)
            )
        )
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Items each jobdesk may put on a production order';

CREATE TABLE
    IF NOT EXISTS `user_admin_sites` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `user_id` bigint unsigned NOT NULL COMMENT 'Must have role site_admin',
        `location_id` bigint unsigned NOT NULL,
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_user_admin_sites_user_id_location_id` (`user_id`, `location_id`, (nullif(`is_deleted`, 1))),
        KEY `ix_user_admin_sites_location_id` (`location_id`),
        CONSTRAINT `fk_user_admin_sites_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_user_admin_sites_location_id` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Locations each site admin administers';
