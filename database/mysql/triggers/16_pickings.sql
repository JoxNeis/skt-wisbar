DROP TRIGGER IF EXISTS `trg_picking_details_before_insert`;
DELIMITER $$
CREATE TRIGGER `trg_picking_details_before_insert`
BEFORE INSERT ON `picking_details`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128) DEFAULT `fn_validate_picking_detail`(NEW.`id`, NEW.`picking_id`, NEW.`allocation_id`);
    IF v_error IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_picking_details_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_picking_details_before_update`
BEFORE UPDATE ON `picking_details`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128) DEFAULT `fn_validate_picking_detail`(NEW.`id`, NEW.`picking_id`, NEW.`allocation_id`);
    IF v_error IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
END$$
DELIMITER ;

