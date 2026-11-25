-- Partitioned by month: ev_log_partition_create splits p_max into the coming months
CREATE TABLE
    IF NOT EXISTS `activity_logs` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `actor_user_id` bigint unsigned DEFAULT NULL COMMENT 'NULL = system or unauthenticated',
        `location_id` bigint unsigned DEFAULT NULL COMMENT 'NULL = not location specific; no FK on partitioned tables',
        `action` varchar(127) NOT NULL COMMENT 'e.g. delivery.created',
        `entity_type` varchar(127) DEFAULT NULL COMMENT 'e.g. delivery or item',
        `entity_id` bigint unsigned DEFAULT NULL,
        `description` longtext NOT NULL,
        `old_values` json DEFAULT NULL,
        `new_values` json DEFAULT NULL,
        `request_id` varchar(36) CHARACTER SET ascii COLLATE ascii_bin DEFAULT NULL COMMENT 'Request correlation ID',
        `session_id` varchar(127) DEFAULT NULL COMMENT 'Matches user_sessions.session_id',
        `ip_address` varchar(45) DEFAULT NULL,
        `user_agent` varchar(511) DEFAULT NULL,
        `source` varchar(47) NOT NULL DEFAULT 'application' COMMENT 'e.g. application, api, background_job',
        `outcome` enum ('success', 'failure', 'denied') NOT NULL,
        `error_code` varchar(127) DEFAULT NULL,
        `remarks` varchar(1023) DEFAULT NULL,
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Partition key',
        PRIMARY KEY (`id`, `created_at`),
        KEY `ix_activity_logs_actor_user_id_created_at` (`actor_user_id`, `created_at`),
        KEY `ix_activity_logs_location_id_created_at` (`location_id`, `created_at`),
        KEY `ix_activity_logs_action_created_at` (`action`, `created_at`),
        KEY `ix_activity_logs_entity` (`entity_type`, `entity_id`),
        KEY `ix_activity_logs_request_id` (`request_id`),
        KEY `ix_activity_logs_session_id` (`session_id`),
        KEY `ix_activity_logs_outcome_created_at` (`outcome`, `created_at`),
        KEY `ix_activity_logs_created_at` (`created_at`)
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Append-only audit log of business and account activity'
PARTITION BY
    RANGE COLUMNS (`created_at`) (
        PARTITION `p_max`
        VALUES
            LESS THAN (MAXVALUE)
    );

CREATE TABLE
    IF NOT EXISTS `system_logs` (
        `id` bigint unsigned NOT NULL AUTO_INCREMENT,
        `request_id` varchar(36) CHARACTER SET ascii COLLATE ascii_bin DEFAULT NULL COMMENT 'Request correlation ID',
        `trace_id` varchar(127) DEFAULT NULL COMMENT 'Distributed trace ID',
        `parent_log_id` bigint unsigned DEFAULT NULL COMMENT 'NULL = root event',
        `actor_user_id` bigint unsigned DEFAULT NULL,
        `event_name` varchar(127) NOT NULL COMMENT 'e.g. api.request.failed',
        `severity` enum ('debug', 'info', 'warning', 'error', 'critical') NOT NULL DEFAULT 'info',
        `environment` enum ('development', 'testing', 'staging', 'production') NOT NULL,
        `source` varchar(63) NOT NULL COMMENT 'e.g. api, worker, scheduler',
        `component` varchar(127) DEFAULT NULL,
        `operation` varchar(127) DEFAULT NULL,
        `message` longtext NOT NULL,
        `outcome` enum (
            'started',
            'success',
            'failure',
            'timeout',
            'cancelled'
        ) DEFAULT NULL,
        `http_method` varchar(15) DEFAULT NULL,
        `request_path` varchar(511) DEFAULT NULL,
        `http_status_code` smallint unsigned DEFAULT NULL,
        `ip_address` varchar(45) DEFAULT NULL,
        `duration_ms` decimal(15, 3) DEFAULT NULL,
        `memory_usage_bytes` bigint unsigned DEFAULT NULL,
        `error_code` varchar(127) DEFAULT NULL,
        `exception_type` varchar(255) DEFAULT NULL,
        `error_stack_trace` longtext,
        `context` json DEFAULT NULL,
        `metrics` json DEFAULT NULL COMMENT 'e.g. row or retry counts',
        `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `occurred_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Partition key',
        PRIMARY KEY (`id`, `occurred_at`),
        KEY `ix_system_logs_request_id` (`request_id`),
        KEY `ix_system_logs_trace_id` (`trace_id`),
        KEY `ix_system_logs_parent_log_id` (`parent_log_id`),
        KEY `ix_system_logs_actor_user_id_occurred_at` (`actor_user_id`, `occurred_at`),
        KEY `ix_system_logs_event_name_occurred_at` (`event_name`, `occurred_at`),
        KEY `ix_system_logs_severity_occurred_at` (`severity`, `occurred_at`),
        KEY `ix_system_logs_component_occurred_at` (`component`, `occurred_at`),
        KEY `ix_system_logs_outcome_occurred_at` (`outcome`, `occurred_at`),
        KEY `ix_system_logs_environment_occurred_at` (`environment`, `occurred_at`),
        KEY `ix_system_logs_occurred_at` (`occurred_at`),
        CONSTRAINT `ck_system_logs_duration_ms_not_negative` CHECK (
            (
                (`duration_ms` is null)
                or (`duration_ms` >= 0)
            )
        ),
        CONSTRAINT `ck_system_logs_http_status_code_range` CHECK (
            (
                (`http_status_code` is null)
                or (`http_status_code` between 100 and 599)
            )
        )
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Application diagnostics, errors and performance events'
PARTITION BY
    RANGE COLUMNS (`occurred_at`) (
        PARTITION `p_max`
        VALUES
            LESS THAN (MAXVALUE)
    );
