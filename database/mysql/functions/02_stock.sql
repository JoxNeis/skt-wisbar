DROP FUNCTION IF EXISTS `fn_warehouse_bin_room`;
DELIMITER $$
CREATE FUNCTION `fn_warehouse_bin_room`(
    `p_warehouse_bin_id` BIGINT UNSIGNED,
    `p_item_id` BIGINT UNSIGNED
)
RETURNS DECIMAL(23, 3)
READS SQL DATA
COMMENT 'Room left for an item in a bin, in the item base unit: maximum amount of the designation valid now - stock of the item in the bin - planned plottings of the item into the bin. NULL = the bin has no designation for the item (no limit)'
BEGIN
    DECLARE v_maximum_amount DECIMAL(20, 3);

    SET v_maximum_amount = (
        SELECT `wbd`.`maximum_amount`
        FROM `warehouse_bin_designations` AS `wbd`
        WHERE `wbd`.`warehouse_bin_id` = `p_warehouse_bin_id`
          AND `wbd`.`item_id` = `p_item_id`
          AND `wbd`.`deleted_at` IS NULL
          AND `wbd`.`valid_from` <= UTC_TIMESTAMP()
          AND (`wbd`.`valid_until` IS NULL OR `wbd`.`valid_until` >= UTC_TIMESTAMP())
        ORDER BY `wbd`.`valid_from` DESC
        LIMIT 1
    );

    IF v_maximum_amount IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN v_maximum_amount
        - (
            SELECT IFNULL(SUM(`inv`.`current_amount`), 0)
            FROM `warehouse_bin_inventories` AS `inv`
            INNER JOIN `batches` AS `bat`
                ON `bat`.`id` = `inv`.`batch_id`
            WHERE `inv`.`warehouse_bin_id` = `p_warehouse_bin_id`
              AND `bat`.`item_id` = `p_item_id`
        )
        - (
            SELECT IFNULL(SUM(`ire`.`amount`), 0)
            FROM `plottings` AS `plt`
            INNER JOIN `inventory_reservations` AS `ire`
                ON `ire`.`id` = `plt`.`id`
            INNER JOIN `warehouse_bin_inventories` AS `inv`
                ON `inv`.`id` = `ire`.`warehouse_bin_inventory_id`
            INNER JOIN `batches` AS `bat`
                ON `bat`.`id` = `inv`.`batch_id`
            WHERE `plt`.`status` = 'planned'
              AND `inv`.`warehouse_bin_id` = `p_warehouse_bin_id`
              AND `bat`.`item_id` = `p_item_id`
        );
END$$
DELIMITER ;
