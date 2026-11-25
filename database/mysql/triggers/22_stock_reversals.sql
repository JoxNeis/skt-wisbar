-- A stock reversal cancels one signed stock document; each of its lines is the exact
-- opposite (same bin inventory, amount and pallets; other direction) of one original line.
-- Completeness is checked when the reversal is signed (trg_transaction_headers_before_update).

DROP TRIGGER IF EXISTS `trg_stock_reversals_before_insert`;
DELIMITER $$
CREATE TRIGGER `trg_stock_reversals_before_insert`
BEFORE INSERT ON `stock_reversals`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128) DEFAULT `fn_validate_stock_reversal`(NEW.`reversed_transaction_header_id`);
    IF v_error IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_stock_reversals_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_stock_reversals_before_update`
BEFORE UPDATE ON `stock_reversals`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128);
    IF NOT (NEW.`reversed_transaction_header_id` <=> OLD.`reversed_transaction_header_id`) THEN
        SET v_error = `fn_validate_stock_reversal`(NEW.`reversed_transaction_header_id`);
        IF v_error IS NOT NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
        END IF;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_stock_reversal_details_before_insert`;
DELIMITER $$
CREATE TRIGGER `trg_stock_reversal_details_before_insert`
BEFORE INSERT ON `stock_reversal_details`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128);

    SET v_error = (
        SELECT `fn_validate_stock_reversal_line`(NEW.`reverses_stock_movement_detail_id`, `smd`.`warehouse_bin_inventory_id`, `smd`.`type`, `smd`.`amount`, `smd`.`pallet_count`)
        FROM `stock_movement_details` AS `smd`
        WHERE `smd`.`id` = NEW.`id`
    );
    IF v_error IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_stock_reversal_details_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_stock_reversal_details_before_update`
BEFORE UPDATE ON `stock_reversal_details`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128);

    IF NOT (NEW.`reverses_stock_movement_detail_id` <=> OLD.`reverses_stock_movement_detail_id`) THEN
        SET v_error = (
            SELECT `fn_validate_stock_reversal_line`(NEW.`reverses_stock_movement_detail_id`, `smd`.`warehouse_bin_inventory_id`, `smd`.`type`, `smd`.`amount`, `smd`.`pallet_count`)
            FROM `stock_movement_details` AS `smd`
            WHERE `smd`.`id` = NEW.`id`
        );
        IF v_error IS NOT NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
        END IF;
    END IF;
END$$
DELIMITER ;
