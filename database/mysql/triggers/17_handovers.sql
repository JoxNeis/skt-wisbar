DROP TRIGGER IF EXISTS `trg_handovers_before_insert`;
DELIMITER $$
CREATE TRIGGER `trg_handovers_before_insert`
BEFORE INSERT ON `handovers`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128) DEFAULT `fn_validate_handover`(NEW.`picking_id`, NEW.`request_type`, NEW.`from_warehouse_id`, NEW.`to_warehouse_id`, NEW.`handed_by`, NEW.`received_by`, NEW.`receiver_name`, NEW.`delivery_note_id`);
    IF v_error IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_handovers_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_handovers_before_update`
BEFORE UPDATE ON `handovers`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128) DEFAULT `fn_validate_handover`(NEW.`picking_id`, NEW.`request_type`, NEW.`from_warehouse_id`, NEW.`to_warehouse_id`, NEW.`handed_by`, NEW.`received_by`, NEW.`receiver_name`, NEW.`delivery_note_id`);
    IF v_error IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
END$$
DELIMITER ;


-- base_amount = amount in the item base unit; the item is that of the picked batch

DROP TRIGGER IF EXISTS `trg_handover_details_before_insert`;
DELIMITER $$
CREATE TRIGGER `trg_handover_details_before_insert`
BEFORE INSERT ON `handover_details`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128);

    SET NEW.`base_amount` = `fn_item_base_amount`((SELECT `bat`.`item_id` FROM `stock_movement_details` AS `smd` INNER JOIN `warehouse_bin_inventories` AS `wbi` ON `wbi`.`id` = `smd`.`warehouse_bin_inventory_id` INNER JOIN `batches` AS `bat` ON `bat`.`id` = `wbi`.`batch_id` WHERE `smd`.`id` = NEW.`picking_detail_id`), NEW.`amount`, NEW.`unit_of_measurement_id`);
    IF NEW.`base_amount` IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'handover_details: no conversion from the unit to the item base unit';
    END IF;

END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_handover_details_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_handover_details_before_update`
BEFORE UPDATE ON `handover_details`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128);

    IF (NEW.`picking_detail_id` <=> OLD.`picking_detail_id` AND NEW.`amount` <=> OLD.`amount` AND NEW.`unit_of_measurement_id` <=> OLD.`unit_of_measurement_id`) THEN
        SET NEW.`base_amount` = OLD.`base_amount`;
    ELSE
        SET NEW.`base_amount` = `fn_item_base_amount`((SELECT `bat`.`item_id` FROM `stock_movement_details` AS `smd` INNER JOIN `warehouse_bin_inventories` AS `wbi` ON `wbi`.`id` = `smd`.`warehouse_bin_inventory_id` INNER JOIN `batches` AS `bat` ON `bat`.`id` = `wbi`.`batch_id` WHERE `smd`.`id` = NEW.`picking_detail_id`), NEW.`amount`, NEW.`unit_of_measurement_id`);
        IF NEW.`base_amount` IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'handover_details: no conversion from the unit to the item base unit';
        END IF;
    END IF;

END$$
DELIMITER ;

