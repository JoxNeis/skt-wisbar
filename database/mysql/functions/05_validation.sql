-- Row rules used by the triggers. Each returns NULL when the row is valid, else the error message.

DROP FUNCTION IF EXISTS `fn_validate_employee`;
DELIMITER $$
CREATE FUNCTION `fn_validate_employee`(
    `p_employee_id` BIGINT UNSIGNED,
    `p_supervisor_id` BIGINT UNSIGNED
)
RETURNS VARCHAR(128)
READS SQL DATA
COMMENT 'The reporting line has no loop'
BEGIN
    DECLARE v_current_id BIGINT UNSIGNED DEFAULT `p_supervisor_id`;
    DECLARE v_depth INT DEFAULT 0;

    WHILE v_current_id IS NOT NULL AND v_depth < 100 DO
        IF v_current_id = `p_employee_id` THEN
            RETURN 'employees: an employee cannot be their own (indirect) supervisor';
        END IF;

        SET v_current_id = (
            SELECT `emp`.`supervisor_id`
            FROM `employees` AS `emp`
            WHERE `emp`.`id` = v_current_id
        );
        SET v_depth = v_depth + 1;
    END WHILE;

    RETURN NULL;
END$$
DELIMITER ;

DROP FUNCTION IF EXISTS `fn_validate_user_admin_site`;
DELIMITER $$
CREATE FUNCTION `fn_validate_user_admin_site`(
    `p_user_id` BIGINT UNSIGNED
)
RETURNS VARCHAR(128)
READS SQL DATA
COMMENT 'Only a site_admin administers sites'
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM `users` AS `usr`
        WHERE `usr`.`id` = `p_user_id`
          AND `usr`.`role` = 'site_admin'
    ) THEN
        RETURN 'user_admin_sites: the user must have role site_admin';
    END IF;

    RETURN NULL;
END$$
DELIMITER ;

DROP FUNCTION IF EXISTS `fn_validate_item_unit_conversion`;
DELIMITER $$
CREATE FUNCTION `fn_validate_item_unit_conversion`(
    `p_item_id` BIGINT UNSIGNED,
    `p_unit_of_measurement_id` BIGINT UNSIGNED
)
RETURNS VARCHAR(128)
READS SQL DATA
COMMENT 'The base unit needs no conversion'
BEGIN
    IF EXISTS (
        SELECT 1
        FROM `items` AS `itm`
        WHERE `itm`.`id` = `p_item_id`
          AND `itm`.`unit_of_measurement_id` = `p_unit_of_measurement_id`
    ) THEN
        RETURN 'item_unit_conversions: the unit is the item base unit';
    END IF;

    RETURN NULL;
END$$
DELIMITER ;

DROP FUNCTION IF EXISTS `fn_validate_warehouse_bin_inventory`;
DELIMITER $$
CREATE FUNCTION `fn_validate_warehouse_bin_inventory`(
    `p_current_amount` DECIMAL(20, 3),
    `p_current_pallet_amount` INT UNSIGNED,
    `p_filled_at` DATETIME,
    `p_depleted_at` DATETIME
)
RETURNS VARCHAR(128)
DETERMINISTIC
NO SQL
COMMENT 'Pallets need stock; filled_at and depleted_at match the amount'
BEGIN
    IF `p_current_amount` = 0 AND `p_current_pallet_amount` > 0 THEN
        RETURN 'warehouse_bin_inventories: pallets without stock';
    END IF;

    IF `p_depleted_at` IS NOT NULL AND `p_current_amount` <> 0 THEN
        RETURN 'warehouse_bin_inventories: depleted_at is set while stock remains';
    END IF;

    IF `p_filled_at` IS NULL AND (`p_current_amount` <> 0 OR `p_depleted_at` IS NOT NULL) THEN
        RETURN 'warehouse_bin_inventories: filled_at is missing';
    END IF;

    IF `p_depleted_at` < `p_filled_at` THEN
        RETURN 'warehouse_bin_inventories: depleted_at is before filled_at';
    END IF;

    RETURN NULL;
END$$
DELIMITER ;

DROP FUNCTION IF EXISTS `fn_validate_stock_movement_detail`;
DELIMITER $$
CREATE FUNCTION `fn_validate_stock_movement_detail`(
    `p_transaction_type` VARCHAR(63),
    `p_transaction_header_type` VARCHAR(63),
    `p_type` VARCHAR(3)
)
RETURNS VARCHAR(128)
DETERMINISTIC
NO SQL
COMMENT 'Line type matches the document; picking lines are out, put-away lines are in'
BEGIN
    IF `p_transaction_type` = 'stock_movement_detail'
       AND `p_transaction_header_type` IN ('stock_movement', 'item_reclassification') THEN
        RETURN NULL;
    END IF;

    IF `p_transaction_type` = 'picking_detail' AND `p_transaction_header_type` = 'picking' THEN
        RETURN IF(`p_type` = 'out', NULL, 'stock_movement_details: a picking line must be out');
    END IF;

    IF `p_transaction_type` = 'stock_reversal_detail' AND `p_transaction_header_type` = 'stock_reversal' THEN
        RETURN NULL;
    END IF;

    IF `p_transaction_type` = 'put_away_detail' AND `p_transaction_header_type` = 'put_away' THEN
        RETURN IF(`p_type` = 'in', NULL, 'stock_movement_details: a put-away line must be in');
    END IF;

    RETURN 'stock_movement_details: transaction_type does not belong to transaction_header_type';
END$$
DELIMITER ;

DROP FUNCTION IF EXISTS `fn_validate_incoming_detail`;
DELIMITER $$
CREATE FUNCTION `fn_validate_incoming_detail`(
    `p_acceptance` VARCHAR(15),
    `p_reject_reason` VARCHAR(255)
)
RETURNS VARCHAR(128)
DETERMINISTIC
NO SQL
COMMENT 'reject_reason is set exactly when rejected'
BEGIN
    IF `p_acceptance` = 'rejected' AND `p_reject_reason` IS NULL THEN
        RETURN 'incoming_details: a rejected line needs reject_reason';
    END IF;

    IF `p_acceptance` <> 'rejected' AND `p_reject_reason` IS NOT NULL THEN
        RETURN 'incoming_details: only a rejected line has reject_reason';
    END IF;

    RETURN NULL;
END$$
DELIMITER ;

DROP FUNCTION IF EXISTS `fn_validate_production_group_usage_detail`;
DELIMITER $$
CREATE FUNCTION `fn_validate_production_group_usage_detail`(
    `p_production_group_usage_id` BIGINT UNSIGNED,
    `p_production_group_id` BIGINT UNSIGNED,
    `p_taken_by` BIGINT UNSIGNED
)
RETURNS VARCHAR(128)
READS SQL DATA
COMMENT 'taken_by is a member of the group on the usage date'
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM `production_group_usages` AS `pgu`
        INNER JOIN `production_group_members` AS `pgm`
            ON `pgm`.`production_group_id` = `p_production_group_id`
           AND `pgm`.`employee_id` = `p_taken_by`
           AND `pgm`.`deleted_at` IS NULL
           AND `pgm`.`valid_from` <= `pgu`.`usage_date`
           AND (`pgm`.`valid_until` IS NULL OR `pgm`.`valid_until` >= `pgu`.`usage_date`)
        WHERE `pgu`.`id` = `p_production_group_usage_id`
    ) THEN
        RETURN 'production_group_usage_details: taken_by is not a group member on the usage date';
    END IF;

    RETURN NULL;
END$$
DELIMITER ;

DROP FUNCTION IF EXISTS `fn_validate_stock_count`;

DROP FUNCTION IF EXISTS `fn_validate_request_detail`;
DELIMITER $$
CREATE FUNCTION `fn_validate_request_detail`(
    `p_transaction_header_type` VARCHAR(63),
    `p_batch_id` BIGINT UNSIGNED
)
RETURNS VARCHAR(128)
DETERMINISTIC
NO SQL
COMMENT 'A production order asks for an item, every other request for a batch'
BEGIN
    IF `p_transaction_header_type` = 'production_order' AND `p_batch_id` IS NOT NULL THEN
        RETURN 'request_details: a production order line has no batch_id';
    END IF;

    IF `p_transaction_header_type` <> 'production_order' AND `p_batch_id` IS NULL THEN
        RETURN 'request_details: batch_id is required';
    END IF;

    RETURN NULL;
END$$
DELIMITER ;

DROP FUNCTION IF EXISTS `fn_validate_internal_transfer`;

DROP FUNCTION IF EXISTS `fn_validate_document_warehouses`;
DELIMITER $$
CREATE FUNCTION `fn_validate_document_warehouses`(
    `p_table_name` VARCHAR(64),
    `p_transaction_header_id` BIGINT UNSIGNED,
    `p_from_warehouse_id` BIGINT UNSIGNED,
    `p_to_warehouse_id` BIGINT UNSIGNED
)
RETURNS VARCHAR(128)
READS SQL DATA
COMMENT 'Both warehouses are at the location of the document'
BEGIN
    DECLARE v_location_id BIGINT UNSIGNED;

    SET v_location_id = (
        SELECT `thd`.`location_id`
        FROM `transaction_headers` AS `thd`
        WHERE `thd`.`id` = `p_transaction_header_id`
    );

    IF NOT EXISTS (
        SELECT 1
        FROM `facilities` AS `fac`
        WHERE `fac`.`id` = `p_from_warehouse_id`
          AND `fac`.`location_id` = v_location_id
    ) OR NOT EXISTS (
        SELECT 1
        FROM `facilities` AS `fac`
        WHERE `fac`.`id` = `p_to_warehouse_id`
          AND `fac`.`location_id` = v_location_id
    ) THEN
        RETURN CONCAT(`p_table_name`, ': both warehouses must be at the document location');
    END IF;

    RETURN NULL;
END$$
DELIMITER ;

DROP FUNCTION IF EXISTS `fn_validate_picking_detail`;
DELIMITER $$
CREATE FUNCTION `fn_validate_picking_detail`(
    `p_picking_detail_id` BIGINT UNSIGNED,
    `p_picking_id` BIGINT UNSIGNED,
    `p_allocation_id` BIGINT UNSIGNED
)
RETURNS VARCHAR(128)
READS SQL DATA
COMMENT 'The line moves the bin inventory of its allocation, from the picking warehouse'
BEGIN
    DECLARE v_line_inventory_id BIGINT UNSIGNED;

    SET v_line_inventory_id = (
        SELECT `smd`.`warehouse_bin_inventory_id`
        FROM `stock_movement_details` AS `smd`
        WHERE `smd`.`id` = `p_picking_detail_id`
    );

    IF NOT EXISTS (
        SELECT 1
        FROM `inventory_reservations` AS `ire`
        WHERE `ire`.`id` = `p_allocation_id`
          AND `ire`.`warehouse_bin_inventory_id` = v_line_inventory_id
    ) THEN
        RETURN 'picking_details: the line must move the bin inventory of its allocation';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM `warehouse_bin_inventories` AS `wbi`
        INNER JOIN `warehouse_bins` AS `wbn`
            ON `wbn`.`id` = `wbi`.`warehouse_bin_id`
        INNER JOIN `pickings` AS `pck`
            ON `pck`.`id` = `p_picking_id`
           AND `pck`.`from_warehouse_id` = `wbn`.`warehouse_id`
        WHERE `wbi`.`id` = v_line_inventory_id
    ) THEN
        RETURN 'picking_details: the bin is not in the picking warehouse';
    END IF;

    RETURN NULL;
END$$
DELIMITER ;

DROP FUNCTION IF EXISTS `fn_validate_handover`;
DELIMITER $$
CREATE FUNCTION `fn_validate_handover`(
    `p_picking_id` BIGINT UNSIGNED,
    `p_request_type` VARCHAR(63),
    `p_from_warehouse_id` BIGINT UNSIGNED,
    `p_to_warehouse_id` BIGINT UNSIGNED,
    `p_handed_by` BIGINT UNSIGNED,
    `p_received_by` BIGINT UNSIGNED,
    `p_receiver_name` VARCHAR(127),
    `p_delivery_note_id` BIGINT UNSIGNED
)
RETURNS VARCHAR(128)
READS SQL DATA
COMMENT 'An outbound goes to a driver with a delivery note; the rest go to a user'
BEGIN
    IF `p_request_type` = 'outbound' THEN
        IF `p_received_by` IS NOT NULL OR `p_to_warehouse_id` IS NOT NULL THEN
            RETURN 'handovers: an outbound has no received_by or to_warehouse_id';
        END IF;
        IF `p_receiver_name` IS NULL OR `p_delivery_note_id` IS NULL THEN
            RETURN 'handovers: an outbound needs receiver_name and delivery_note_id';
        END IF;
    ELSE
        IF `p_received_by` IS NULL THEN
            RETURN 'handovers: received_by is required';
        END IF;
        IF `p_receiver_name` IS NOT NULL OR `p_delivery_note_id` IS NOT NULL THEN
            RETURN 'handovers: only an outbound has receiver_name and delivery_note_id';
        END IF;
    END IF;

    IF `p_received_by` = `p_handed_by` THEN
        RETURN 'handovers: handed_by and received_by must differ';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM `pickings` AS `pck`
        WHERE `pck`.`id` = `p_picking_id`
          AND `pck`.`from_warehouse_id` = `p_from_warehouse_id`
    ) THEN
        RETURN 'handovers: from_warehouse_id must be the picking warehouse';
    END IF;

    RETURN NULL;
END$$
DELIMITER ;

DROP FUNCTION IF EXISTS `fn_validate_plotting`;
DELIMITER $$
CREATE FUNCTION `fn_validate_plotting`(
    `p_source_transaction_type` VARCHAR(63),
    `p_source_header_type` VARCHAR(63),
    `p_status` VARCHAR(15),
    `p_cancel_reason` VARCHAR(255)
)
RETURNS VARCHAR(128)
DETERMINISTIC
NO SQL
COMMENT 'Source is a plottable line; cancel_reason is set exactly when cancelled'
BEGIN
    IF NOT (
        (`p_source_transaction_type` = 'handover_detail' AND `p_source_header_type` = 'handover')
        OR (`p_source_transaction_type` = 'incoming_detail' AND `p_source_header_type` = 'incoming')
        OR (`p_source_transaction_type` = 'production_group_return' AND `p_source_header_type` = 'production_group_usage')
    ) THEN
        RETURN 'plottings: the source must be a handover, incoming or production group return line';
    END IF;

    IF (`p_status` = 'cancelled') <> (`p_cancel_reason` IS NOT NULL) THEN
        RETURN 'plottings: cancel_reason is required exactly when cancelled';
    END IF;

    RETURN NULL;
END$$
DELIMITER ;

DROP FUNCTION IF EXISTS `fn_validate_put_away_detail`;
DELIMITER $$
CREATE FUNCTION `fn_validate_put_away_detail`(
    `p_put_away_detail_id` BIGINT UNSIGNED,
    `p_plotting_id` BIGINT UNSIGNED
)
RETURNS VARCHAR(128)
READS SQL DATA
COMMENT 'The line moves the bin inventory of its plotting'
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM `stock_movement_details` AS `smd`
        INNER JOIN `inventory_reservations` AS `ire`
            ON `ire`.`id` = `p_plotting_id`
           AND `ire`.`warehouse_bin_inventory_id` = `smd`.`warehouse_bin_inventory_id`
        WHERE `smd`.`id` = `p_put_away_detail_id`
    ) THEN
        RETURN 'put_away_details: the line must move the bin inventory of its plotting';
    END IF;

    RETURN NULL;
END$$
DELIMITER ;

DROP FUNCTION IF EXISTS `fn_validate_item_reclassification`;
DELIMITER $$
CREATE FUNCTION `fn_validate_item_reclassification`(
    `p_out_stock_movement_detail_id` BIGINT UNSIGNED,
    `p_in_stock_movement_detail_id` BIGINT UNSIGNED
)
RETURNS VARCHAR(128)
READS SQL DATA
COMMENT 'The out and in lines are in the same bin'
BEGIN
    IF (
        SELECT COUNT(DISTINCT `wbi`.`warehouse_bin_id`)
        FROM `stock_movement_details` AS `smd`
        INNER JOIN `warehouse_bin_inventories` AS `wbi`
            ON `wbi`.`id` = `smd`.`warehouse_bin_inventory_id`
        WHERE `smd`.`id` IN (`p_out_stock_movement_detail_id`, `p_in_stock_movement_detail_id`)
    ) <> 1 THEN
        RETURN 'item_reclassifications: both lines must be in the same bin';
    END IF;

    RETURN NULL;
END$$
DELIMITER ;
