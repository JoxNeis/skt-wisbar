DROP TRIGGER IF EXISTS `trg_stock_movement_details_before_insert`;
DELIMITER $$
CREATE TRIGGER `trg_stock_movement_details_before_insert`
BEFORE INSERT ON `stock_movement_details`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128) DEFAULT `fn_validate_stock_movement_detail`(NEW.`transaction_type`, NEW.`transaction_header_type`, NEW.`type`);
    IF v_error IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_stock_movement_details_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_stock_movement_details_before_update`
BEFORE UPDATE ON `stock_movement_details`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128) DEFAULT `fn_validate_stock_movement_detail`(NEW.`transaction_type`, NEW.`transaction_header_type`, NEW.`type`);
    DECLARE v_reverses_id BIGINT UNSIGNED;

    IF v_error IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;

    -- A reversal line stays the exact opposite of its original line
    IF NEW.`transaction_type` = 'stock_reversal_detail' THEN
        SET v_reverses_id = (
            SELECT `srd`.`reverses_stock_movement_detail_id`
            FROM `stock_reversal_details` AS `srd`
            WHERE `srd`.`id` = NEW.`id`
        );
        IF v_reverses_id IS NOT NULL THEN
            SET v_error = `fn_validate_stock_reversal_line`(v_reverses_id, NEW.`warehouse_bin_inventory_id`, NEW.`type`, NEW.`amount`, NEW.`pallet_count`);
            IF v_error IS NOT NULL THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
            END IF;
        END IF;
    END IF;
END$$
DELIMITER ;

