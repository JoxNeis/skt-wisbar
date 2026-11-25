-- Rows of a signed or reversed document are read-only, except active_key (and requests.status).
-- Keep the column lists in sync when a column is added to one of these tables.

-- Document subtypes (id = transaction_headers.id)

DROP TRIGGER IF EXISTS `trg_stock_movements_lock_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_stock_movements_lock_before_update`
BEFORE UPDATE ON `stock_movements`
FOR EACH ROW
BEGIN
    IF `fn_transaction_header_is_locked`(OLD.`id`)
       AND NOT (NEW.`id` <=> OLD.`id`
               AND NEW.`transaction_header_type` <=> OLD.`transaction_header_type`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'stock_movements: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_stock_movements_lock_before_delete`;
DELIMITER $$
CREATE TRIGGER `trg_stock_movements_lock_before_delete`
BEFORE DELETE ON `stock_movements`
FOR EACH ROW
BEGIN
    IF `fn_transaction_header_is_locked`(OLD.`id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'stock_movements: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_delivery_notes_lock_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_delivery_notes_lock_before_update`
BEFORE UPDATE ON `delivery_notes`
FOR EACH ROW
BEGIN
    IF `fn_transaction_header_is_locked`(OLD.`id`)
       AND NOT (NEW.`id` <=> OLD.`id`
               AND NEW.`transaction_header_type` <=> OLD.`transaction_header_type`
               AND NEW.`delivery_number` <=> OLD.`delivery_number`
               AND NEW.`delivery_date` <=> OLD.`delivery_date`
               AND NEW.`from_organization_id` <=> OLD.`from_organization_id`
               AND NEW.`to_organization_id` <=> OLD.`to_organization_id`
               AND NEW.`vehicle_plate_number` <=> OLD.`vehicle_plate_number`
               AND NEW.`estimated_arrival_date` <=> OLD.`estimated_arrival_date`
               AND NEW.`service_name` <=> OLD.`service_name`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'delivery_notes: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_delivery_notes_lock_before_delete`;
DELIMITER $$
CREATE TRIGGER `trg_delivery_notes_lock_before_delete`
BEFORE DELETE ON `delivery_notes`
FOR EACH ROW
BEGIN
    IF `fn_transaction_header_is_locked`(OLD.`id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'delivery_notes: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_incomings_lock_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_incomings_lock_before_update`
BEFORE UPDATE ON `incomings`
FOR EACH ROW
BEGIN
    IF `fn_transaction_header_is_locked`(OLD.`id`)
       AND NOT (NEW.`id` <=> OLD.`id`
               AND NEW.`transaction_header_type` <=> OLD.`transaction_header_type`
               AND NEW.`delivery_note_id` <=> OLD.`delivery_note_id`
               AND NEW.`from_organization_id` <=> OLD.`from_organization_id`
               AND NEW.`to_organization_id` <=> OLD.`to_organization_id`
               AND NEW.`vehicle_plate_number` <=> OLD.`vehicle_plate_number`
               AND NEW.`driver_name` <=> OLD.`driver_name`
               AND NEW.`actual_arrival_date` <=> OLD.`actual_arrival_date`
               AND NEW.`service_name` <=> OLD.`service_name`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'incomings: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_incomings_lock_before_delete`;
DELIMITER $$
CREATE TRIGGER `trg_incomings_lock_before_delete`
BEFORE DELETE ON `incomings`
FOR EACH ROW
BEGIN
    IF `fn_transaction_header_is_locked`(OLD.`id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'incomings: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_production_group_usages_lock_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_production_group_usages_lock_before_update`
BEFORE UPDATE ON `production_group_usages`
FOR EACH ROW
BEGIN
    IF `fn_transaction_header_is_locked`(OLD.`id`)
       AND NOT (NEW.`id` <=> OLD.`id`
               AND NEW.`transaction_header_type` <=> OLD.`transaction_header_type`
               AND NEW.`production_id` <=> OLD.`production_id`
               AND NEW.`usage_date` <=> OLD.`usage_date`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'production_group_usages: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_production_group_usages_lock_before_delete`;
DELIMITER $$
CREATE TRIGGER `trg_production_group_usages_lock_before_delete`
BEFORE DELETE ON `production_group_usages`
FOR EACH ROW
BEGIN
    IF `fn_transaction_header_is_locked`(OLD.`id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'production_group_usages: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_requests_lock_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_requests_lock_before_update`
BEFORE UPDATE ON `requests`
FOR EACH ROW
BEGIN
    IF `fn_transaction_header_is_locked`(OLD.`id`)
       AND NOT (NEW.`id` <=> OLD.`id`
               AND NEW.`transaction_header_type` <=> OLD.`transaction_header_type`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'requests: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_requests_lock_before_delete`;
DELIMITER $$
CREATE TRIGGER `trg_requests_lock_before_delete`
BEFORE DELETE ON `requests`
FOR EACH ROW
BEGIN
    IF `fn_transaction_header_is_locked`(OLD.`id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'requests: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_production_orders_lock_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_production_orders_lock_before_update`
BEFORE UPDATE ON `production_orders`
FOR EACH ROW
BEGIN
    IF `fn_transaction_header_is_locked`(OLD.`id`)
       AND NOT (NEW.`id` <=> OLD.`id`
               AND NEW.`transaction_header_type` <=> OLD.`transaction_header_type`
               AND NEW.`production_id` <=> OLD.`production_id`
               AND NEW.`production_date` <=> OLD.`production_date`
               AND NEW.`required_at` <=> OLD.`required_at`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'production_orders: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_production_orders_lock_before_delete`;
DELIMITER $$
CREATE TRIGGER `trg_production_orders_lock_before_delete`
BEFORE DELETE ON `production_orders`
FOR EACH ROW
BEGIN
    IF `fn_transaction_header_is_locked`(OLD.`id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'production_orders: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_production_returns_lock_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_production_returns_lock_before_update`
BEFORE UPDATE ON `production_returns`
FOR EACH ROW
BEGIN
    IF `fn_transaction_header_is_locked`(OLD.`id`)
       AND NOT (NEW.`id` <=> OLD.`id`
               AND NEW.`transaction_header_type` <=> OLD.`transaction_header_type`
               AND NEW.`production_id` <=> OLD.`production_id`
               AND NEW.`production_date` <=> OLD.`production_date`
               AND NEW.`from_warehouse_id` <=> OLD.`from_warehouse_id`
               AND NEW.`from_storage_type` <=> OLD.`from_storage_type`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'production_returns: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_production_returns_lock_before_delete`;
DELIMITER $$
CREATE TRIGGER `trg_production_returns_lock_before_delete`
BEFORE DELETE ON `production_returns`
FOR EACH ROW
BEGIN
    IF `fn_transaction_header_is_locked`(OLD.`id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'production_returns: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_internal_transfers_lock_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_internal_transfers_lock_before_update`
BEFORE UPDATE ON `internal_transfers`
FOR EACH ROW
BEGIN
    IF `fn_transaction_header_is_locked`(OLD.`id`)
       AND NOT (NEW.`id` <=> OLD.`id`
               AND NEW.`transaction_header_type` <=> OLD.`transaction_header_type`
               AND NEW.`from_warehouse_id` <=> OLD.`from_warehouse_id`
               AND NEW.`to_warehouse_id` <=> OLD.`to_warehouse_id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'internal_transfers: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_internal_transfers_lock_before_delete`;
DELIMITER $$
CREATE TRIGGER `trg_internal_transfers_lock_before_delete`
BEFORE DELETE ON `internal_transfers`
FOR EACH ROW
BEGIN
    IF `fn_transaction_header_is_locked`(OLD.`id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'internal_transfers: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_outbounds_lock_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_outbounds_lock_before_update`
BEFORE UPDATE ON `outbounds`
FOR EACH ROW
BEGIN
    IF `fn_transaction_header_is_locked`(OLD.`id`)
       AND NOT (NEW.`id` <=> OLD.`id`
               AND NEW.`transaction_header_type` <=> OLD.`transaction_header_type`
               AND NEW.`from_warehouse_id` <=> OLD.`from_warehouse_id`
               AND NEW.`to_organization_id` <=> OLD.`to_organization_id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'outbounds: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_outbounds_lock_before_delete`;
DELIMITER $$
CREATE TRIGGER `trg_outbounds_lock_before_delete`
BEFORE DELETE ON `outbounds`
FOR EACH ROW
BEGIN
    IF `fn_transaction_header_is_locked`(OLD.`id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'outbounds: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_production_rejects_lock_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_production_rejects_lock_before_update`
BEFORE UPDATE ON `production_rejects`
FOR EACH ROW
BEGIN
    IF `fn_transaction_header_is_locked`(OLD.`id`)
       AND NOT (NEW.`id` <=> OLD.`id`
               AND NEW.`transaction_header_type` <=> OLD.`transaction_header_type`
               AND NEW.`production_id` <=> OLD.`production_id`
               AND NEW.`from_warehouse_id` <=> OLD.`from_warehouse_id`
               AND NEW.`from_storage_type` <=> OLD.`from_storage_type`
               AND NEW.`to_warehouse_id` <=> OLD.`to_warehouse_id`
               AND NEW.`to_warehouse_type` <=> OLD.`to_warehouse_type`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'production_rejects: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_production_rejects_lock_before_delete`;
DELIMITER $$
CREATE TRIGGER `trg_production_rejects_lock_before_delete`
BEFORE DELETE ON `production_rejects`
FOR EACH ROW
BEGIN
    IF `fn_transaction_header_is_locked`(OLD.`id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'production_rejects: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_pickings_lock_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_pickings_lock_before_update`
BEFORE UPDATE ON `pickings`
FOR EACH ROW
BEGIN
    IF `fn_transaction_header_is_locked`(OLD.`id`)
       AND NOT (NEW.`id` <=> OLD.`id`
               AND NEW.`transaction_header_type` <=> OLD.`transaction_header_type`
               AND NEW.`request_id` <=> OLD.`request_id`
               AND NEW.`from_warehouse_id` <=> OLD.`from_warehouse_id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'pickings: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_pickings_lock_before_delete`;
DELIMITER $$
CREATE TRIGGER `trg_pickings_lock_before_delete`
BEFORE DELETE ON `pickings`
FOR EACH ROW
BEGIN
    IF `fn_transaction_header_is_locked`(OLD.`id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'pickings: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_handovers_lock_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_handovers_lock_before_update`
BEFORE UPDATE ON `handovers`
FOR EACH ROW
BEGIN
    IF `fn_transaction_header_is_locked`(OLD.`id`)
       AND NOT (NEW.`id` <=> OLD.`id`
               AND NEW.`transaction_header_type` <=> OLD.`transaction_header_type`
               AND NEW.`request_id` <=> OLD.`request_id`
               AND NEW.`request_type` <=> OLD.`request_type`
               AND NEW.`picking_id` <=> OLD.`picking_id`
               AND NEW.`from_warehouse_id` <=> OLD.`from_warehouse_id`
               AND NEW.`to_warehouse_id` <=> OLD.`to_warehouse_id`
               AND NEW.`handed_by` <=> OLD.`handed_by`
               AND NEW.`received_by` <=> OLD.`received_by`
               AND NEW.`receiver_name` <=> OLD.`receiver_name`
               AND NEW.`delivery_note_id` <=> OLD.`delivery_note_id`
               AND NEW.`handed_over_at` <=> OLD.`handed_over_at`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'handovers: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_handovers_lock_before_delete`;
DELIMITER $$
CREATE TRIGGER `trg_handovers_lock_before_delete`
BEFORE DELETE ON `handovers`
FOR EACH ROW
BEGIN
    IF `fn_transaction_header_is_locked`(OLD.`id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'handovers: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_put_aways_lock_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_put_aways_lock_before_update`
BEFORE UPDATE ON `put_aways`
FOR EACH ROW
BEGIN
    IF `fn_transaction_header_is_locked`(OLD.`id`)
       AND NOT (NEW.`id` <=> OLD.`id`
               AND NEW.`transaction_header_type` <=> OLD.`transaction_header_type`
               AND NEW.`source_header_id` <=> OLD.`source_header_id`
               AND NEW.`source_header_type` <=> OLD.`source_header_type`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'put_aways: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_put_aways_lock_before_delete`;
DELIMITER $$
CREATE TRIGGER `trg_put_aways_lock_before_delete`
BEFORE DELETE ON `put_aways`
FOR EACH ROW
BEGIN
    IF `fn_transaction_header_is_locked`(OLD.`id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'put_aways: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_item_reclassifications_lock_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_item_reclassifications_lock_before_update`
BEFORE UPDATE ON `item_reclassifications`
FOR EACH ROW
BEGIN
    IF `fn_transaction_header_is_locked`(OLD.`id`)
       AND NOT (NEW.`id` <=> OLD.`id`
               AND NEW.`transaction_header_type` <=> OLD.`transaction_header_type`
               AND NEW.`out_stock_movement_detail_id` <=> OLD.`out_stock_movement_detail_id`
               AND NEW.`out_movement_type` <=> OLD.`out_movement_type`
               AND NEW.`in_stock_movement_detail_id` <=> OLD.`in_stock_movement_detail_id`
               AND NEW.`in_movement_type` <=> OLD.`in_movement_type`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'item_reclassifications: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_item_reclassifications_lock_before_delete`;
DELIMITER $$
CREATE TRIGGER `trg_item_reclassifications_lock_before_delete`
BEFORE DELETE ON `item_reclassifications`
FOR EACH ROW
BEGIN
    IF `fn_transaction_header_is_locked`(OLD.`id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'item_reclassifications: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_stock_reversals_lock_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_stock_reversals_lock_before_update`
BEFORE UPDATE ON `stock_reversals`
FOR EACH ROW
BEGIN
    IF `fn_transaction_header_is_locked`(OLD.`id`)
       AND NOT (NEW.`id` <=> OLD.`id`
               AND NEW.`transaction_header_type` <=> OLD.`transaction_header_type`
               AND NEW.`reversed_transaction_header_id` <=> OLD.`reversed_transaction_header_id`
               AND NEW.`reversed_header_type` <=> OLD.`reversed_header_type`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'stock_reversals: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_stock_reversals_lock_before_delete`;
DELIMITER $$
CREATE TRIGGER `trg_stock_reversals_lock_before_delete`
BEFORE DELETE ON `stock_reversals`
FOR EACH ROW
BEGIN
    IF `fn_transaction_header_is_locked`(OLD.`id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'stock_reversals: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

-- Line subtypes (id = transactions.id)

DROP TRIGGER IF EXISTS `trg_stock_movement_details_lock_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_stock_movement_details_lock_before_update`
BEFORE UPDATE ON `stock_movement_details`
FOR EACH ROW
BEGIN
    IF `fn_transaction_is_locked`(OLD.`id`)
       AND NOT (NEW.`id` <=> OLD.`id`
               AND NEW.`transaction_type` <=> OLD.`transaction_type`
               AND NEW.`transaction_header_type` <=> OLD.`transaction_header_type`
               AND NEW.`warehouse_bin_inventory_id` <=> OLD.`warehouse_bin_inventory_id`
               AND NEW.`type` <=> OLD.`type`
               AND NEW.`amount` <=> OLD.`amount`
               AND NEW.`pallet_count` <=> OLD.`pallet_count`
               AND NEW.`moved_by` <=> OLD.`moved_by`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'stock_movement_details: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_stock_movement_details_lock_before_delete`;
DELIMITER $$
CREATE TRIGGER `trg_stock_movement_details_lock_before_delete`
BEFORE DELETE ON `stock_movement_details`
FOR EACH ROW
BEGIN
    IF `fn_transaction_is_locked`(OLD.`id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'stock_movement_details: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_delivery_note_details_lock_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_delivery_note_details_lock_before_update`
BEFORE UPDATE ON `delivery_note_details`
FOR EACH ROW
BEGIN
    IF `fn_transaction_is_locked`(OLD.`id`)
       AND NOT (NEW.`id` <=> OLD.`id`
               AND NEW.`transaction_type` <=> OLD.`transaction_type`
               AND NEW.`transaction_header_type` <=> OLD.`transaction_header_type`
               AND NEW.`delivery_note_id` <=> OLD.`delivery_note_id`
               AND NEW.`item_id` <=> OLD.`item_id`
               AND NEW.`batch_id` <=> OLD.`batch_id`
               AND NEW.`amount` <=> OLD.`amount`
               AND NEW.`unit_of_measurement_id` <=> OLD.`unit_of_measurement_id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'delivery_note_details: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_delivery_note_details_lock_before_delete`;
DELIMITER $$
CREATE TRIGGER `trg_delivery_note_details_lock_before_delete`
BEFORE DELETE ON `delivery_note_details`
FOR EACH ROW
BEGIN
    IF `fn_transaction_is_locked`(OLD.`id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'delivery_note_details: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_incoming_details_lock_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_incoming_details_lock_before_update`
BEFORE UPDATE ON `incoming_details`
FOR EACH ROW
BEGIN
    IF `fn_transaction_is_locked`(OLD.`id`)
       AND NOT (NEW.`id` <=> OLD.`id`
               AND NEW.`transaction_type` <=> OLD.`transaction_type`
               AND NEW.`transaction_header_type` <=> OLD.`transaction_header_type`
               AND NEW.`incoming_id` <=> OLD.`incoming_id`
               AND NEW.`delivery_note_id` <=> OLD.`delivery_note_id`
               AND NEW.`delivery_note_detail_id` <=> OLD.`delivery_note_detail_id`
               AND NEW.`batch_id` <=> OLD.`batch_id`
               AND NEW.`amount` <=> OLD.`amount`
               AND NEW.`unit_of_measurement_id` <=> OLD.`unit_of_measurement_id`
               AND NEW.`base_amount` <=> OLD.`base_amount`
               AND NEW.`acceptance` <=> OLD.`acceptance`
               AND NEW.`reject_reason` <=> OLD.`reject_reason`
               AND NEW.`remarks` <=> OLD.`remarks`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'incoming_details: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_incoming_details_lock_before_delete`;
DELIMITER $$
CREATE TRIGGER `trg_incoming_details_lock_before_delete`
BEFORE DELETE ON `incoming_details`
FOR EACH ROW
BEGIN
    IF `fn_transaction_is_locked`(OLD.`id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'incoming_details: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_weighings_lock_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_weighings_lock_before_update`
BEFORE UPDATE ON `weighings`
FOR EACH ROW
BEGIN
    IF `fn_transaction_is_locked`(OLD.`id`)
       AND NOT (NEW.`id` <=> OLD.`id`
               AND NEW.`transaction_type` <=> OLD.`transaction_type`
               AND NEW.`transaction_header_type` <=> OLD.`transaction_header_type`
               AND NEW.`incoming_id` <=> OLD.`incoming_id`
               AND NEW.`incoming_detail_id` <=> OLD.`incoming_detail_id`
               AND NEW.`box_count` <=> OLD.`box_count`
               AND NEW.`written_net_weight` <=> OLD.`written_net_weight`
               AND NEW.`written_gross_weight` <=> OLD.`written_gross_weight`
               AND NEW.`actual_packaging_weight` <=> OLD.`actual_packaging_weight`
               AND NEW.`actual_gross_weight` <=> OLD.`actual_gross_weight`
               AND NEW.`weight_unit_of_measurement_id` <=> OLD.`weight_unit_of_measurement_id`
               AND NEW.`weight_unit_type` <=> OLD.`weight_unit_type`
               AND NEW.`moisture_content` <=> OLD.`moisture_content`
               AND NEW.`remarks` <=> OLD.`remarks`
               AND NEW.`weighed_by` <=> OLD.`weighed_by`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'weighings: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_weighings_lock_before_delete`;
DELIMITER $$
CREATE TRIGGER `trg_weighings_lock_before_delete`
BEFORE DELETE ON `weighings`
FOR EACH ROW
BEGIN
    IF `fn_transaction_is_locked`(OLD.`id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'weighings: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_production_group_usage_details_lock_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_production_group_usage_details_lock_before_update`
BEFORE UPDATE ON `production_group_usage_details`
FOR EACH ROW
BEGIN
    IF `fn_transaction_is_locked`(OLD.`id`)
       AND NOT (NEW.`id` <=> OLD.`id`
               AND NEW.`transaction_type` <=> OLD.`transaction_type`
               AND NEW.`transaction_header_type` <=> OLD.`transaction_header_type`
               AND NEW.`production_group_usage_id` <=> OLD.`production_group_usage_id`
               AND NEW.`production_id` <=> OLD.`production_id`
               AND NEW.`production_group_id` <=> OLD.`production_group_id`
               AND NEW.`batch_id` <=> OLD.`batch_id`
               AND NEW.`box_count` <=> OLD.`box_count`
               AND NEW.`amount` <=> OLD.`amount`
               AND NEW.`unit_of_measurement_id` <=> OLD.`unit_of_measurement_id`
               AND NEW.`taken_by` <=> OLD.`taken_by`
               AND NEW.`given_by` <=> OLD.`given_by`
               AND NEW.`remarks` <=> OLD.`remarks`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'production_group_usage_details: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_production_group_usage_details_lock_before_delete`;
DELIMITER $$
CREATE TRIGGER `trg_production_group_usage_details_lock_before_delete`
BEFORE DELETE ON `production_group_usage_details`
FOR EACH ROW
BEGIN
    IF `fn_transaction_is_locked`(OLD.`id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'production_group_usage_details: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_production_group_rejects_lock_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_production_group_rejects_lock_before_update`
BEFORE UPDATE ON `production_group_rejects`
FOR EACH ROW
BEGIN
    IF `fn_transaction_is_locked`(OLD.`id`)
       AND NOT (NEW.`id` <=> OLD.`id`
               AND NEW.`transaction_type` <=> OLD.`transaction_type`
               AND NEW.`transaction_header_type` <=> OLD.`transaction_header_type`
               AND NEW.`production_group_usage_id` <=> OLD.`production_group_usage_id`
               AND NEW.`production_group_usage_detail_id` <=> OLD.`production_group_usage_detail_id`
               AND NEW.`amount` <=> OLD.`amount`
               AND NEW.`unit_of_measurement_id` <=> OLD.`unit_of_measurement_id`
               AND NEW.`remarks` <=> OLD.`remarks`
               AND NEW.`recorded_by` <=> OLD.`recorded_by`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'production_group_rejects: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_production_group_rejects_lock_before_delete`;
DELIMITER $$
CREATE TRIGGER `trg_production_group_rejects_lock_before_delete`
BEFORE DELETE ON `production_group_rejects`
FOR EACH ROW
BEGIN
    IF `fn_transaction_is_locked`(OLD.`id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'production_group_rejects: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_production_group_wastes_lock_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_production_group_wastes_lock_before_update`
BEFORE UPDATE ON `production_group_wastes`
FOR EACH ROW
BEGIN
    IF `fn_transaction_is_locked`(OLD.`id`)
       AND NOT (NEW.`id` <=> OLD.`id`
               AND NEW.`transaction_type` <=> OLD.`transaction_type`
               AND NEW.`transaction_header_type` <=> OLD.`transaction_header_type`
               AND NEW.`production_group_usage_id` <=> OLD.`production_group_usage_id`
               AND NEW.`production_group_usage_detail_id` <=> OLD.`production_group_usage_detail_id`
               AND NEW.`amount` <=> OLD.`amount`
               AND NEW.`unit_of_measurement_id` <=> OLD.`unit_of_measurement_id`
               AND NEW.`remarks` <=> OLD.`remarks`
               AND NEW.`recorded_by` <=> OLD.`recorded_by`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'production_group_wastes: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_production_group_wastes_lock_before_delete`;
DELIMITER $$
CREATE TRIGGER `trg_production_group_wastes_lock_before_delete`
BEFORE DELETE ON `production_group_wastes`
FOR EACH ROW
BEGIN
    IF `fn_transaction_is_locked`(OLD.`id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'production_group_wastes: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_production_group_returns_lock_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_production_group_returns_lock_before_update`
BEFORE UPDATE ON `production_group_returns`
FOR EACH ROW
BEGIN
    IF `fn_transaction_is_locked`(OLD.`id`)
       AND NOT (NEW.`id` <=> OLD.`id`
               AND NEW.`transaction_type` <=> OLD.`transaction_type`
               AND NEW.`transaction_header_type` <=> OLD.`transaction_header_type`
               AND NEW.`production_group_usage_id` <=> OLD.`production_group_usage_id`
               AND NEW.`production_group_usage_detail_id` <=> OLD.`production_group_usage_detail_id`
               AND NEW.`amount` <=> OLD.`amount`
               AND NEW.`unit_of_measurement_id` <=> OLD.`unit_of_measurement_id`
               AND NEW.`returned_by` <=> OLD.`returned_by`
               AND NEW.`received_by` <=> OLD.`received_by`
               AND NEW.`remarks` <=> OLD.`remarks`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'production_group_returns: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_production_group_returns_lock_before_delete`;
DELIMITER $$
CREATE TRIGGER `trg_production_group_returns_lock_before_delete`
BEFORE DELETE ON `production_group_returns`
FOR EACH ROW
BEGIN
    IF `fn_transaction_is_locked`(OLD.`id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'production_group_returns: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_request_details_lock_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_request_details_lock_before_update`
BEFORE UPDATE ON `request_details`
FOR EACH ROW
BEGIN
    IF `fn_transaction_is_locked`(OLD.`id`)
       AND NOT (NEW.`id` <=> OLD.`id`
               AND NEW.`transaction_type` <=> OLD.`transaction_type`
               AND NEW.`transaction_header_type` <=> OLD.`transaction_header_type`
               AND NEW.`request_id` <=> OLD.`request_id`
               AND NEW.`item_id` <=> OLD.`item_id`
               AND NEW.`batch_id` <=> OLD.`batch_id`
               AND NEW.`amount` <=> OLD.`amount`
               AND NEW.`unit_of_measurement_id` <=> OLD.`unit_of_measurement_id`
               AND NEW.`base_amount` <=> OLD.`base_amount`
               AND NEW.`remarks` <=> OLD.`remarks`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'request_details: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_request_details_lock_before_delete`;
DELIMITER $$
CREATE TRIGGER `trg_request_details_lock_before_delete`
BEFORE DELETE ON `request_details`
FOR EACH ROW
BEGIN
    IF `fn_transaction_is_locked`(OLD.`id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'request_details: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_picking_details_lock_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_picking_details_lock_before_update`
BEFORE UPDATE ON `picking_details`
FOR EACH ROW
BEGIN
    IF `fn_transaction_is_locked`(OLD.`id`)
       AND NOT (NEW.`id` <=> OLD.`id`
               AND NEW.`transaction_type` <=> OLD.`transaction_type`
               AND NEW.`transaction_header_type` <=> OLD.`transaction_header_type`
               AND NEW.`picking_id` <=> OLD.`picking_id`
               AND NEW.`request_id` <=> OLD.`request_id`
               AND NEW.`allocation_id` <=> OLD.`allocation_id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'picking_details: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_picking_details_lock_before_delete`;
DELIMITER $$
CREATE TRIGGER `trg_picking_details_lock_before_delete`
BEFORE DELETE ON `picking_details`
FOR EACH ROW
BEGIN
    IF `fn_transaction_is_locked`(OLD.`id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'picking_details: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_handover_details_lock_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_handover_details_lock_before_update`
BEFORE UPDATE ON `handover_details`
FOR EACH ROW
BEGIN
    IF `fn_transaction_is_locked`(OLD.`id`)
       AND NOT (NEW.`id` <=> OLD.`id`
               AND NEW.`transaction_type` <=> OLD.`transaction_type`
               AND NEW.`transaction_header_type` <=> OLD.`transaction_header_type`
               AND NEW.`handover_id` <=> OLD.`handover_id`
               AND NEW.`picking_id` <=> OLD.`picking_id`
               AND NEW.`picking_detail_id` <=> OLD.`picking_detail_id`
               AND NEW.`amount` <=> OLD.`amount`
               AND NEW.`unit_of_measurement_id` <=> OLD.`unit_of_measurement_id`
               AND NEW.`base_amount` <=> OLD.`base_amount`
               AND NEW.`remarks` <=> OLD.`remarks`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'handover_details: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_handover_details_lock_before_delete`;
DELIMITER $$
CREATE TRIGGER `trg_handover_details_lock_before_delete`
BEFORE DELETE ON `handover_details`
FOR EACH ROW
BEGIN
    IF `fn_transaction_is_locked`(OLD.`id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'handover_details: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_put_away_details_lock_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_put_away_details_lock_before_update`
BEFORE UPDATE ON `put_away_details`
FOR EACH ROW
BEGIN
    IF `fn_transaction_is_locked`(OLD.`id`)
       AND NOT (NEW.`id` <=> OLD.`id`
               AND NEW.`transaction_type` <=> OLD.`transaction_type`
               AND NEW.`transaction_header_type` <=> OLD.`transaction_header_type`
               AND NEW.`put_away_id` <=> OLD.`put_away_id`
               AND NEW.`source_header_id` <=> OLD.`source_header_id`
               AND NEW.`plotting_id` <=> OLD.`plotting_id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'put_away_details: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_put_away_details_lock_before_delete`;
DELIMITER $$
CREATE TRIGGER `trg_put_away_details_lock_before_delete`
BEFORE DELETE ON `put_away_details`
FOR EACH ROW
BEGIN
    IF `fn_transaction_is_locked`(OLD.`id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'put_away_details: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_stock_reversal_details_lock_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_stock_reversal_details_lock_before_update`
BEFORE UPDATE ON `stock_reversal_details`
FOR EACH ROW
BEGIN
    IF `fn_transaction_is_locked`(OLD.`id`)
       AND NOT (NEW.`id` <=> OLD.`id`
               AND NEW.`transaction_type` <=> OLD.`transaction_type`
               AND NEW.`transaction_header_type` <=> OLD.`transaction_header_type`
               AND NEW.`stock_reversal_id` <=> OLD.`stock_reversal_id`
               AND NEW.`reversed_transaction_header_id` <=> OLD.`reversed_transaction_header_id`
               AND NEW.`reverses_stock_movement_detail_id` <=> OLD.`reverses_stock_movement_detail_id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'stock_reversal_details: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_stock_reversal_details_lock_before_delete`;
DELIMITER $$
CREATE TRIGGER `trg_stock_reversal_details_lock_before_delete`
BEFORE DELETE ON `stock_reversal_details`
FOR EACH ROW
BEGIN
    IF `fn_transaction_is_locked`(OLD.`id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'stock_reversal_details: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;
