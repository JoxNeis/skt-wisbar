CREATE TABLE
    IF NOT EXISTS `employees` (
        `id` bigint unsigned NOT NULL COMMENT 'PK shared with users.id',
        `employee_number` varchar(31) NOT NULL,
        `first_name` varchar(127) NOT NULL,
        `middle_name` varchar(127) DEFAULT NULL,
        `last_name` varchar(127) DEFAULT NULL,
        `phone_number` varchar(31) DEFAULT NULL,
        `address` varchar(255) DEFAULT NULL,
        `supervisor_id` bigint unsigned DEFAULT NULL COMMENT 'Signs the documents this employee creates',
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_employees_employee_number` (`employee_number`, (nullif(`is_deleted`, 1))),
        KEY `ix_employees_supervisor_id` (`supervisor_id`),
        KEY `ix_employees_last_name_first_name` (`last_name`, `first_name`),
        CONSTRAINT `fk_employees_supervisor_id` FOREIGN KEY (`supervisor_id`) REFERENCES `employees` (`id`) ON DELETE SET NULL ON UPDATE RESTRICT,
        CONSTRAINT `fk_employees_id` FOREIGN KEY (`id`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Employee profile and reporting line';

CREATE TABLE
    IF NOT EXISTS `jobdesks` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `name` varchar(255) NOT NULL,
        `code` varchar(15) NOT NULL,
        `display` varchar(273) GENERATED ALWAYS AS (concat(`code`, _utf8mb4 ' - ', `name`)) VIRTUAL,
        `description` varchar(1023) DEFAULT NULL,
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_jobdesks_code` (`code`, (nullif(`is_deleted`, 1)))
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Jobdesks (roles), the same at every location';

CREATE TABLE
    IF NOT EXISTS `employee_jobdesks` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `employee_id` bigint unsigned NOT NULL,
        `jobdesk_id` bigint unsigned NOT NULL,
        `location_id` bigint unsigned NOT NULL,
        `valid_from` date NOT NULL COMMENT 'Location local date',
        `valid_until` date DEFAULT NULL COMMENT 'NULL = never expires',
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_employee_jobdesks_employee_jobdesk_location_valid_from` (
            `employee_id`,
            `jobdesk_id`,
            `location_id`,
            `valid_from`,
            (nullif(`is_deleted`, 1))
        ),
        KEY `ix_employee_jobdesks_jobdesk_id` (`jobdesk_id`),
        KEY `ix_employee_jobdesks_location_id` (`location_id`),
        KEY `ix_employee_jobdesks_employee_id_valid_from_valid_until` (`employee_id`, `valid_from`, `valid_until`),
        CONSTRAINT `fk_employee_jobdesks_employee_id` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_employee_jobdesks_location_id` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_employee_jobdesks_jobdesk_id` FOREIGN KEY (`jobdesk_id`) REFERENCES `jobdesks` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_employee_jobdesks_validity_period` CHECK (
            (
                (`valid_until` is null)
                or (`valid_until` >= `valid_from`)
            )
        )
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Jobdesk an employee holds at a location, per date range';

CREATE TABLE
    IF NOT EXISTS `production_group_members` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `production_group_id` bigint unsigned NOT NULL,
        `employee_id` bigint unsigned NOT NULL,
        `valid_from` date NOT NULL COMMENT 'Location local date',
        `valid_until` date DEFAULT NULL COMMENT 'NULL = open-ended',
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_production_group_members_group_employee_valid_from` (
            `production_group_id`,
            `employee_id`,
            `valid_from`,
            (nullif(`is_deleted`, 1))
        ),
        KEY `ix_production_group_members_employee_id` (`employee_id`),
        CONSTRAINT `fk_production_group_members_production_group_id` FOREIGN KEY (`production_group_id`) REFERENCES `production_groups` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_production_group_members_employee_id` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `ck_production_group_members_validity_period` CHECK (
            (
                (`valid_until` is null)
                or (`valid_until` >= `valid_from`)
            )
        )
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Members of each production group, per date range';
