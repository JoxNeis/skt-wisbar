-- base_amount = amount in the item base unit, fixed when the line is entered

DROP TRIGGER IF EXISTS `trg_request_details_before_insert`;
DELIMITER $$
CREATE TRIGGER `trg_request_details_before_insert`
BEFORE INSERT ON `request_details`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128);

    SET NEW.`base_amount` = `fn_item_base_amount`(NEW.`item_id`, NEW.`amount`, NEW.`unit_of_measurement_id`);
    IF NEW.`base_amount` IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'request_details: no conversion from the unit to the item base unit';
    END IF;

    SET v_error = `fn_validate_request_detail`(NEW.`transaction_header_type`, NEW.`batch_id`);
    IF v_error IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_request_details_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_request_details_before_update`
BEFORE UPDATE ON `request_details`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128);

    IF (NEW.`item_id` <=> OLD.`item_id` AND NEW.`amount` <=> OLD.`amount` AND NEW.`unit_of_measurement_id` <=> OLD.`unit_of_measurement_id`) THEN
        SET NEW.`base_amount` = OLD.`base_amount`;
    ELSE
        SET NEW.`base_amount` = `fn_item_base_amount`(NEW.`item_id`, NEW.`amount`, NEW.`unit_of_measurement_id`);
        IF NEW.`base_amount` IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'request_details: no conversion from the unit to the item base unit';
        END IF;
    END IF;

    SET v_error = `fn_validate_request_detail`(NEW.`transaction_header_type`, NEW.`batch_id`);
    IF v_error IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_internal_transfers_before_insert`;
DELIMITER $$
CREATE TRIGGER `trg_internal_transfers_before_insert`
BEFORE INSERT ON `internal_transfers`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128) DEFAULT `fn_validate_document_warehouses`('internal_transfers', NEW.`id`, NEW.`from_warehouse_id`, NEW.`to_warehouse_id`);
    IF v_error IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_internal_transfers_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_internal_transfers_before_update`
BEFORE UPDATE ON `internal_transfers`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128) DEFAULT `fn_validate_document_warehouses`('internal_transfers', NEW.`id`, NEW.`from_warehouse_id`, NEW.`to_warehouse_id`);
    IF v_error IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_production_rejects_before_insert`;
DELIMITER $$
CREATE TRIGGER `trg_production_rejects_before_insert`
BEFORE INSERT ON `production_rejects`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128) DEFAULT `fn_validate_document_warehouses`('production_rejects', NEW.`id`, NEW.`from_warehouse_id`, NEW.`to_warehouse_id`);
    IF v_error IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_production_rejects_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_production_rejects_before_update`
BEFORE UPDATE ON `production_rejects`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128) DEFAULT `fn_validate_document_warehouses`('production_rejects', NEW.`id`, NEW.`from_warehouse_id`, NEW.`to_warehouse_id`);
    IF v_error IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
END$$
DELIMITER ;
