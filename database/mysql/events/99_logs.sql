-- Keeps a partition for the current month and the next 3 in activity_logs and system_logs.
-- Each missing month is split off p_max, so p_max stays empty and the split is cheap.
-- Runs once right after creation, then daily; safe to run any number of times.
DROP EVENT IF EXISTS `ev_log_partition_roll`;

DROP EVENT IF EXISTS `ev_log_partition_create`;

DELIMITER $$
CREATE EVENT `ev_log_partition_create`
    ON SCHEDULE EVERY 1 DAY
    STARTS CURRENT_TIMESTAMP
    ON COMPLETION PRESERVE
    ENABLE
    COMMENT 'Creates the monthly partitions of activity_logs and system_logs up to 3 months ahead'
DO
BEGIN
    DECLARE v_months_ahead TINYINT DEFAULT 3;
    DECLARE v_table_index TINYINT DEFAULT 1;
    DECLARE v_month_offset TINYINT;
    DECLARE v_table_name VARCHAR(64);
    DECLARE v_month_start DATE;
    DECLARE v_partition_name VARCHAR(64);

    WHILE v_table_index <= 2 DO
        SET v_table_name = ELT(v_table_index, 'activity_logs', 'system_logs');
        SET v_month_offset = 0;

        WHILE v_month_offset <= v_months_ahead DO
            SET v_month_start = DATE_FORMAT(UTC_DATE(), '%Y-%m-01') + INTERVAL v_month_offset MONTH;
            SET v_partition_name = CONCAT('p', DATE_FORMAT(v_month_start, '%Y_%m'));

            IF NOT EXISTS (
                SELECT 1
                FROM `information_schema`.`PARTITIONS` AS `prt`
                WHERE `prt`.`TABLE_SCHEMA` = DATABASE()
                  AND `prt`.`TABLE_NAME` = v_table_name
                  AND `prt`.`PARTITION_NAME` = v_partition_name
            ) THEN
                SET @ev_log_partition_sql = CONCAT(
                    'ALTER TABLE `', v_table_name, '` REORGANIZE PARTITION `p_max` INTO (',
                    'PARTITION `', v_partition_name, '` VALUES LESS THAN (''',
                    DATE_FORMAT(v_month_start + INTERVAL 1 MONTH, '%Y-%m-%d 00:00:00'), '''), ',
                    'PARTITION `p_max` VALUES LESS THAN (MAXVALUE))'
                );
                PREPARE `stmt_log_partition` FROM @ev_log_partition_sql;
                EXECUTE `stmt_log_partition`;
                DEALLOCATE PREPARE `stmt_log_partition`;
            END IF;

            SET v_month_offset = v_month_offset + 1;
        END WHILE;

        SET v_table_index = v_table_index + 1;
    END WHILE;
END$$
DELIMITER ;
