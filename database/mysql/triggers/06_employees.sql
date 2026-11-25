DROP TRIGGER IF EXISTS `trg_employees_before_insert`;
DELIMITER $$
CREATE TRIGGER `trg_employees_before_insert`
BEFORE INSERT ON `employees`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128) DEFAULT `fn_validate_employee`(NEW.`id`, NEW.`supervisor_id`);
    IF v_error IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_employees_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_employees_before_update`
BEFORE UPDATE ON `employees`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128) DEFAULT `fn_validate_employee`(NEW.`id`, NEW.`supervisor_id`);
    IF v_error IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
END$$
DELIMITER ;
