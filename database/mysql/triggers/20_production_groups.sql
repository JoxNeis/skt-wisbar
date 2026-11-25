DROP TRIGGER IF EXISTS `trg_production_group_usage_details_before_insert`;
DELIMITER $$
CREATE TRIGGER `trg_production_group_usage_details_before_insert`
BEFORE INSERT ON `production_group_usage_details`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128) DEFAULT `fn_validate_production_group_usage_detail`(NEW.`production_group_usage_id`, NEW.`production_group_id`, NEW.`taken_by`);
    IF v_error IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_production_group_usage_details_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_production_group_usage_details_before_update`
BEFORE UPDATE ON `production_group_usage_details`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128) DEFAULT `fn_validate_production_group_usage_detail`(NEW.`production_group_usage_id`, NEW.`production_group_id`, NEW.`taken_by`);
    IF v_error IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
END$$
DELIMITER ;

