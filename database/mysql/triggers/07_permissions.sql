DROP TRIGGER IF EXISTS `trg_user_admin_sites_before_insert`;
DELIMITER $$
CREATE TRIGGER `trg_user_admin_sites_before_insert`
BEFORE INSERT ON `user_admin_sites`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128) DEFAULT `fn_validate_user_admin_site`(NEW.`user_id`);
    IF v_error IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_user_admin_sites_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_user_admin_sites_before_update`
BEFORE UPDATE ON `user_admin_sites`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128);
    IF NEW.`deleted_at` IS NULL THEN
        SET v_error = `fn_validate_user_admin_site`(NEW.`user_id`);
        IF v_error IS NOT NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
        END IF;
    END IF;
END$$
DELIMITER ;
