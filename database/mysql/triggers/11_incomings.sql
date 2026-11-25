-- base_amount = amount in the item base unit, fixed when the line is entered

DROP TRIGGER IF EXISTS `trg_incoming_details_before_insert`;
DELIMITER $$
CREATE TRIGGER `trg_incoming_details_before_insert`
BEFORE INSERT ON `incoming_details`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128);

    SET NEW.`base_amount` = `fn_item_base_amount`((SELECT `bat`.`item_id` FROM `batches` AS `bat` WHERE `bat`.`id` = NEW.`batch_id`), NEW.`amount`, NEW.`unit_of_measurement_id`);
    IF NEW.`base_amount` IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'incoming_details: no conversion from the unit to the item base unit';
    END IF;

    SET v_error = `fn_validate_incoming_detail`(NEW.`acceptance`, NEW.`reject_reason`);
    IF v_error IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_incoming_details_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_incoming_details_before_update`
BEFORE UPDATE ON `incoming_details`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128);

    IF (NEW.`batch_id` <=> OLD.`batch_id` AND NEW.`amount` <=> OLD.`amount` AND NEW.`unit_of_measurement_id` <=> OLD.`unit_of_measurement_id`) THEN
        SET NEW.`base_amount` = OLD.`base_amount`;
    ELSE
        SET NEW.`base_amount` = `fn_item_base_amount`((SELECT `bat`.`item_id` FROM `batches` AS `bat` WHERE `bat`.`id` = NEW.`batch_id`), NEW.`amount`, NEW.`unit_of_measurement_id`);
        IF NEW.`base_amount` IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'incoming_details: no conversion from the unit to the item base unit';
        END IF;
    END IF;

    SET v_error = `fn_validate_incoming_detail`(NEW.`acceptance`, NEW.`reject_reason`);
    IF v_error IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
END$$
DELIMITER ;

