DROP TRIGGER IF EXISTS `trg_put_away_details_before_insert`;
DELIMITER $$
CREATE TRIGGER `trg_put_away_details_before_insert`
BEFORE INSERT ON `put_away_details`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128) DEFAULT `fn_validate_put_away_detail`(NEW.`id`, NEW.`plotting_id`);
    IF v_error IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_put_away_details_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_put_away_details_before_update`
BEFORE UPDATE ON `put_away_details`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128) DEFAULT `fn_validate_put_away_detail`(NEW.`id`, NEW.`plotting_id`);
    IF v_error IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
END$$
DELIMITER ;

