DROP TRIGGER IF EXISTS `trg_item_unit_conversions_before_insert`;
DELIMITER $$
CREATE TRIGGER `trg_item_unit_conversions_before_insert`
BEFORE INSERT ON `item_unit_conversions`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128) DEFAULT `fn_validate_item_unit_conversion`(NEW.`item_id`, NEW.`unit_of_measurement_id`);
    IF v_error IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_item_unit_conversions_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_item_unit_conversions_before_update`
BEFORE UPDATE ON `item_unit_conversions`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128) DEFAULT `fn_validate_item_unit_conversion`(NEW.`item_id`, NEW.`unit_of_measurement_id`);
    IF v_error IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
END$$
DELIMITER ;
