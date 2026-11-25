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
    IF v_error IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
END$$
DELIMITER ;

