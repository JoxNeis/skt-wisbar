-- Stock reversal rules. Each returns NULL when valid, else the error message.

DROP FUNCTION IF EXISTS `fn_validate_stock_reversal`;
DELIMITER $$
CREATE FUNCTION `fn_validate_stock_reversal`(
    `p_reversed_transaction_header_id` BIGINT UNSIGNED
)
RETURNS VARCHAR(128)
READS SQL DATA
COMMENT 'Only a signed stock document can be reversed'
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM `transaction_headers` AS `thd`
        WHERE `thd`.`id` = `p_reversed_transaction_header_id`
          AND `thd`.`status` = 'signed'
    ) THEN
        RETURN 'stock_reversals: only a signed stock document can be reversed';
    END IF;

    RETURN NULL;
END$$
DELIMITER ;

DROP FUNCTION IF EXISTS `fn_validate_stock_reversal_line`;
DELIMITER $$
CREATE FUNCTION `fn_validate_stock_reversal_line`(
    `p_reverses_stock_movement_detail_id` BIGINT UNSIGNED,
    `p_warehouse_bin_inventory_id` BIGINT UNSIGNED,
    `p_type` VARCHAR(3),
    `p_amount` DECIMAL(20, 3),
    `p_pallet_count` INT UNSIGNED
)
RETURNS VARCHAR(128)
READS SQL DATA
COMMENT 'Same bin inventory, amount and pallets as the original line, opposite direction'
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM `stock_movement_details` AS `smd`
        INNER JOIN `transactions` AS `trx`
            ON `trx`.`id` = `smd`.`id`
        WHERE `smd`.`id` = `p_reverses_stock_movement_detail_id`
          AND `trx`.`deleted_at` IS NULL
          AND `smd`.`warehouse_bin_inventory_id` = `p_warehouse_bin_inventory_id`
          AND `smd`.`amount` = `p_amount`
          AND `smd`.`pallet_count` <=> `p_pallet_count`
          AND `smd`.`type` <> `p_type`
    ) THEN
        RETURN 'stock_reversal_details: the line must be the exact opposite of the original line';
    END IF;

    RETURN NULL;
END$$
DELIMITER ;

DROP FUNCTION IF EXISTS `fn_validate_stock_reversal_complete`;
DELIMITER $$
CREATE FUNCTION `fn_validate_stock_reversal_complete`(
    `p_stock_reversal_id` BIGINT UNSIGNED
)
RETURNS VARCHAR(128)
READS SQL DATA
COMMENT 'Before signing: one opposite line for every original line, and nothing else'
BEGIN
    DECLARE v_reversed_transaction_header_id BIGINT UNSIGNED;

    SET v_reversed_transaction_header_id = (
        SELECT `srv`.`reversed_transaction_header_id`
        FROM `stock_reversals` AS `srv`
        WHERE `srv`.`id` = `p_stock_reversal_id`
          AND `srv`.`active_key` = 1
    );

    IF v_reversed_transaction_header_id IS NULL THEN
        RETURN 'stock_reversals: the reversal has no reversed document';
    END IF;

    IF `fn_validate_stock_reversal`(v_reversed_transaction_header_id) IS NOT NULL THEN
        RETURN 'stock_reversals: the reversed document is no longer signed';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM `transactions` AS `org`
        WHERE `org`.`transaction_header_id` = v_reversed_transaction_header_id
          AND `org`.`deleted_at` IS NULL
          AND NOT EXISTS (
              SELECT 1
              FROM `stock_reversal_details` AS `srd`
              INNER JOIN `transactions` AS `rev`
                  ON `rev`.`id` = `srd`.`id`
              WHERE `srd`.`stock_reversal_id` = `p_stock_reversal_id`
                AND `srd`.`reverses_stock_movement_detail_id` = `org`.`id`
                AND `rev`.`deleted_at` IS NULL
          )
    ) THEN
        RETURN 'stock_reversals: every line of the reversed document needs its opposite line';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM `transactions` AS `rev`
        WHERE `rev`.`transaction_header_id` = `p_stock_reversal_id`
          AND `rev`.`deleted_at` IS NULL
          AND NOT EXISTS (
              SELECT 1
              FROM `stock_reversal_details` AS `srd`
              WHERE `srd`.`id` = `rev`.`id`
          )
    ) THEN
        RETURN 'stock_reversals: every line must reverse a line of the reversed document';
    END IF;

    RETURN NULL;
END$$
DELIMITER ;
