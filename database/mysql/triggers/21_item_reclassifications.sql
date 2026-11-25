DROP TRIGGER IF EXISTS `trg_item_reclassifications_before_insert`;
DELIMITER $$
CREATE TRIGGER `trg_item_reclassifications_before_insert`
BEFORE INSERT ON `item_reclassifications`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128) DEFAULT `fn_validate_item_reclassification`(NEW.`out_stock_movement_detail_id`, NEW.`in_stock_movement_detail_id`);
    IF v_error IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_item_reclassifications_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_item_reclassifications_before_update`
BEFORE UPDATE ON `item_reclassifications`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128) DEFAULT `fn_validate_item_reclassification`(NEW.`out_stock_movement_detail_id`, NEW.`in_stock_movement_detail_id`);
    IF v_error IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
END$$
DELIMITER ;

