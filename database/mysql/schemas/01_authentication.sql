CREATE TABLE
    IF NOT EXISTS `users` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `username` varchar(127) NOT NULL,
        `password_hash` varchar(255) NOT NULL COMMENT 'One-way hash, never plain text',
        `email` varchar(255) DEFAULT NULL,
        `last_password_changed_at` datetime DEFAULT NULL COMMENT 'NULL = initial password in use',
        `must_change_password` tinyint NOT NULL DEFAULT '0' COMMENT '1 = force a password change after login',
        `status` enum ('active', 'inactive', 'suspended') NOT NULL DEFAULT 'active',
        `role` enum ('super_admin', 'admin', 'site_admin', 'normal') NOT NULL DEFAULT 'normal' COMMENT 'Sites of a site_admin are in user_admin_sites',
        `is_locked_until` datetime DEFAULT NULL COMMENT 'Login blocked until this time; NULL = not locked',
        `last_login_at` datetime DEFAULT NULL,
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `deleted_at` datetime NULL DEFAULT NULL,
        `is_deleted` tinyint GENERATED ALWAYS AS ((`deleted_at` is not null)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_users_username` (`username`, (nullif(`is_deleted`, 1))),
        UNIQUE KEY `uq_users_email` (`email`, (nullif(`is_deleted`, 1))),
        KEY `ix_users_role_status` (`role`, `status`),
        CONSTRAINT `ck_users_email_format` CHECK (
            (
                (`email` is null)
                or (`email` like _utf8mb4 '%_@_%._%')
            )
        )
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Login accounts, account status and system role';

CREATE TABLE
    IF NOT EXISTS `user_password_changes` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `user_id` bigint unsigned NOT NULL,
        `previous_password_hash` varchar(255) NOT NULL,
        `changed_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `changed_by` bigint unsigned NOT NULL,
        `change_reason` enum (
            'self_service',
            'administrative_reset',
            'forced_rotation',
            'recovery'
        ) NOT NULL DEFAULT 'self_service',
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        KEY `ix_user_password_changes_user_id_changed_at` (`user_id`, `changed_at`),
        KEY `ix_user_password_changes_changed_by` (`changed_by`),
        CONSTRAINT `fk_user_password_changes_changed_by` FOREIGN KEY (`changed_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
        CONSTRAINT `fk_user_password_changes_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Append-only password history';

CREATE TABLE
    IF NOT EXISTS `user_sessions` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `user_id` bigint unsigned NOT NULL,
        `session_id` varchar(127) NOT NULL COMMENT 'Opaque ID; matches activity_logs.session_id',
        `refresh_token_hash` char(64) CHARACTER SET ascii COLLATE ascii_bin DEFAULT NULL COMMENT 'SHA-256 of the refresh token',
        `ip_address` varchar(45) DEFAULT NULL,
        `user_agent` varchar(511) DEFAULT NULL,
        `device_identifier` varchar(127) DEFAULT NULL COMMENT 'Scanner, terminal or workstation ID',
        `issued_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `expires_at` datetime NOT NULL,
        `last_seen_at` datetime DEFAULT NULL,
        `revoked_at` datetime DEFAULT NULL COMMENT 'NULL = not revoked',
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_user_sessions_session_id` (`session_id`),
        UNIQUE KEY `uq_user_sessions_refresh_token_hash` (`refresh_token_hash`),
        KEY `ix_user_sessions_user_id_expires_at` (`user_id`, `expires_at`),
        KEY `ix_user_sessions_expires_at` (`expires_at`),
        KEY `ix_user_sessions_revoked_at` (`revoked_at`),
        CONSTRAINT `fk_user_sessions_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT,
        CONSTRAINT `ck_user_sessions_expiry_after_issue` CHECK ((`expires_at` > `issued_at`)),
        CONSTRAINT `ck_user_sessions_revocation_after_issue` CHECK (
            (
                (`revoked_at` is null)
                or (`revoked_at` >= `issued_at`)
            )
        )
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Issued sessions and their expiry or revocation';

CREATE TABLE
    IF NOT EXISTS `user_login_attempts` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `attempted_username` varchar(127) NOT NULL COMMENT 'As typed, even if no account matches',
        `user_id` bigint unsigned DEFAULT NULL COMMENT 'NULL = no matching account',
        `outcome` enum (
            'success',
            'invalid_credentials',
            'wrong_password',
            'account_locked',
            'account_inactive'
        ) NOT NULL,
        `ip_address` varchar(45) DEFAULT NULL,
        `user_agent` varchar(511) DEFAULT NULL,
        `attempted_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        KEY `ix_user_login_attempts_username_attempted_at` (`attempted_username`, `attempted_at`),
        KEY `ix_user_login_attempts_ip_address_attempted_at` (`ip_address`, `attempted_at`),
        KEY `ix_user_login_attempts_user_id_attempted_at` (`user_id`, `attempted_at`),
        KEY `ix_user_login_attempts_outcome_attempted_at` (`outcome`, `attempted_at`),
        CONSTRAINT `fk_user_login_attempts_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE RESTRICT
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Append-only login attempts, for rate limiting and lockout';
