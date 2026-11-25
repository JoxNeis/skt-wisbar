DROP FUNCTION IF EXISTS `fn_item_base_amount`;
DELIMITER $$
CREATE FUNCTION `fn_item_base_amount`(
    `p_item_id` BIGINT UNSIGNED,
    `p_amount` DECIMAL(20, 3),
    `p_unit_of_measurement_id` BIGINT UNSIGNED
)
RETURNS DECIMAL(20, 3)
READS SQL DATA
COMMENT 'An amount of an item in its base unit: unchanged when the unit is the base unit, else converted with item_unit_conversions. NULL = the unit has no conversion for the item'
BEGIN
    DECLARE v_base_unit_of_measurement_id BIGINT UNSIGNED;
    DECLARE v_factor_to_base DECIMAL(20, 6);

    SET v_base_unit_of_measurement_id = (
        SELECT `itm`.`unit_of_measurement_id`
        FROM `items` AS `itm`
        WHERE `itm`.`id` = `p_item_id`
    );

    IF v_base_unit_of_measurement_id IS NULL OR `p_amount` IS NULL THEN
        RETURN NULL;
    END IF;

    IF `p_unit_of_measurement_id` = v_base_unit_of_measurement_id THEN
        RETURN `p_amount`;
    END IF;

    SET v_factor_to_base = (
        SELECT `iuc`.`factor_to_base`
        FROM `item_unit_conversions` AS `iuc`
        WHERE `iuc`.`item_id` = `p_item_id`
          AND `iuc`.`unit_of_measurement_id` = `p_unit_of_measurement_id`
          AND `iuc`.`deleted_at` IS NULL
        LIMIT 1
    );

    IF v_factor_to_base IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN ROUND(`p_amount` * v_factor_to_base, 3);
END$$
DELIMITER ;
