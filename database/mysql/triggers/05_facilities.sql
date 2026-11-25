-- filled_at / depleted_at follow current_amount: set when stock goes above zero / back to zero
DROP TRIGGER IF EXISTS `trg_warehouse_bin_inventories_before_insert`;
DELIMITER $$
CREATE TRIGGER `trg_warehouse_bin_inventories_before_insert`
BEFORE INSERT ON `warehouse_bin_inventories`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128);

    IF NEW.`current_amount` > 0 AND NEW.`filled_at` IS NULL THEN
        SET NEW.`filled_at` = UTC_TIMESTAMP();
    END IF;

    SET v_error = `fn_validate_warehouse_bin_inventory`(NEW.`current_amount`, NEW.`current_pallet_amount`, NEW.`filled_at`, NEW.`depleted_at`);
    IF v_error IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_warehouse_bin_inventories_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_warehouse_bin_inventories_before_update`
BEFORE UPDATE ON `warehouse_bin_inventories`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128);

    IF OLD.`current_amount` = 0 AND NEW.`current_amount` > 0 THEN
        SET NEW.`filled_at` = UTC_TIMESTAMP();
        SET NEW.`depleted_at` = NULL;
    ELSEIF OLD.`current_amount` > 0 AND NEW.`current_amount` = 0 THEN
        SET NEW.`depleted_at` = UTC_TIMESTAMP();
    END IF;

    SET v_error = `fn_validate_warehouse_bin_inventory`(NEW.`current_amount`, NEW.`current_pallet_amount`, NEW.`filled_at`, NEW.`depleted_at`);
    IF v_error IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
END$$
DELIMITER ;
