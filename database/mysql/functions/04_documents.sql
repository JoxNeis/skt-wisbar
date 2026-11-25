-- Document lifecycle helpers used by the triggers

DROP FUNCTION IF EXISTS `fn_transaction_header_is_locked`;
DELIMITER $$
CREATE FUNCTION `fn_transaction_header_is_locked`(
    `p_transaction_header_id` BIGINT UNSIGNED
)
RETURNS TINYINT
READS SQL DATA
COMMENT '1 when the document is signed or reversed'
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM `transaction_headers` AS `thd`
        WHERE `thd`.`id` = `p_transaction_header_id`
          AND `thd`.`status` <> 'unsigned'
    );
END$$
DELIMITER ;

DROP FUNCTION IF EXISTS `fn_transaction_is_locked`;
DELIMITER $$
CREATE FUNCTION `fn_transaction_is_locked`(
    `p_transaction_id` BIGINT UNSIGNED
)
RETURNS TINYINT
READS SQL DATA
COMMENT '1 when the document of the line is signed or reversed'
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM `transactions` AS `trx`
        INNER JOIN `transaction_headers` AS `thd`
            ON `thd`.`id` = `trx`.`transaction_header_id`
        WHERE `trx`.`id` = `p_transaction_id`
          AND `thd`.`status` <> 'unsigned'
    );
END$$
DELIMITER ;

DROP FUNCTION IF EXISTS `fn_transaction_type_allowed`;
DELIMITER $$
CREATE FUNCTION `fn_transaction_type_allowed`(
    `p_transaction_type` VARCHAR(63),
    `p_transaction_header_type` VARCHAR(63)
)
RETURNS TINYINT
DETERMINISTIC
NO SQL
COMMENT '1 when a line type may belong to a document type'
BEGIN
    RETURN COALESCE(
        CASE `p_transaction_type`
            WHEN 'request_detail' THEN `p_transaction_header_type` IN ('production_order', 'production_return', 'internal_transfer', 'outbound', 'production_reject')
            WHEN 'stock_movement_detail' THEN `p_transaction_header_type` IN ('stock_movement', 'item_reclassification')
            WHEN 'picking_detail' THEN `p_transaction_header_type` = 'picking'
            WHEN 'put_away_detail' THEN `p_transaction_header_type` = 'put_away'
            WHEN 'stock_reversal_detail' THEN `p_transaction_header_type` = 'stock_reversal'
            WHEN 'handover_detail' THEN `p_transaction_header_type` = 'handover'
            WHEN 'incoming_detail' THEN `p_transaction_header_type` = 'incoming'
            WHEN 'weighing' THEN `p_transaction_header_type` = 'incoming'
            WHEN 'production_group_usage_detail' THEN `p_transaction_header_type` = 'production_group_usage'
            WHEN 'production_group_reject' THEN `p_transaction_header_type` = 'production_group_usage'
            WHEN 'production_group_waste' THEN `p_transaction_header_type` = 'production_group_usage'
            WHEN 'production_group_return' THEN `p_transaction_header_type` = 'production_group_usage'
            WHEN 'delivery_note_detail' THEN `p_transaction_header_type` = 'delivery_note'
        END,
        0
    );
END$$
DELIMITER ;

DROP FUNCTION IF EXISTS `fn_validate_transaction`;
DELIMITER $$
CREATE FUNCTION `fn_validate_transaction`(
    `p_transaction_header_id` BIGINT UNSIGNED,
    `p_transaction_type` VARCHAR(63),
    `p_transaction_header_type` VARCHAR(63)
)
RETURNS VARCHAR(128)
READS SQL DATA
COMMENT 'NULL when a new line is valid, else the error'
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM `transaction_headers` AS `thd`
        WHERE `thd`.`id` = `p_transaction_header_id`
          AND `thd`.`status` = 'unsigned'
          AND `thd`.`deleted_at` IS NULL
    ) THEN
        RETURN 'transactions: lines can only be added to an active draft';
    END IF;

    IF NOT `fn_transaction_type_allowed`(`p_transaction_type`, `p_transaction_header_type`) THEN
        RETURN 'transactions: transaction_type does not belong to transaction_header_type';
    END IF;

    RETURN NULL;
END$$
DELIMITER ;

DROP FUNCTION IF EXISTS `fn_validate_transaction_header_sign_off`;
DELIMITER $$
CREATE FUNCTION `fn_validate_transaction_header_sign_off`(
    `p_transaction_header_id` BIGINT UNSIGNED,
    `p_decision` VARCHAR(15),
    `p_remarks` TEXT,
    `p_signed_by` BIGINT UNSIGNED
)
RETURNS VARCHAR(128)
READS SQL DATA
COMMENT 'NULL when a sign-off is valid, else the error'
BEGIN
    DECLARE v_status VARCHAR(15);
    DECLARE v_deleted_at DATETIME;
    DECLARE v_created_by BIGINT UNSIGNED;

    SELECT `thd`.`status`, `thd`.`deleted_at`, `thd`.`created_by`
    INTO v_status, v_deleted_at, v_created_by
    FROM `transaction_headers` AS `thd`
    WHERE `thd`.`id` = `p_transaction_header_id`;

    IF v_status IS NULL OR v_status <> 'unsigned' OR v_deleted_at IS NOT NULL THEN
        RETURN 'transaction_header_sign_offs: only an active draft can be signed off';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM `employees` AS `emp`
        WHERE `emp`.`id` = v_created_by
          AND `emp`.`supervisor_id` = `p_signed_by`
    ) THEN
        RETURN 'transaction_header_sign_offs: signed_by must be the supervisor of the document creator';
    END IF;

    IF `p_decision` = 'rejected' AND (`p_remarks` IS NULL OR TRIM(`p_remarks`) = '') THEN
        RETURN 'transaction_header_sign_offs: a rejection needs remarks';
    END IF;

    RETURN NULL;
END$$
DELIMITER ;
