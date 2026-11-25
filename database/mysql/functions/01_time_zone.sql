-- Stored times are UTC; business dates are the local date of the location.
-- A NULL site uses WIB (UTC+7), e.g. for numbers that are not site specific such as employee numbers.

DROP FUNCTION IF EXISTS `fn_site_local_datetime`;
DELIMITER $$
CREATE FUNCTION `fn_site_local_datetime`(
    `p_location_id` BIGINT UNSIGNED,
    `p_utc_datetime` DATETIME
)
RETURNS DATETIME
READS SQL DATA
COMMENT 'Converts a UTC time into the local time of a location (WIB when the site is NULL or unknown)'
BEGIN
    DECLARE v_utc_offset CHAR(6);

    SET v_utc_offset = COALESCE(
        (
            SELECT `pst`.`utc_offset`
            FROM `locations` AS `pst`
            WHERE `pst`.`id` = `p_location_id`
        ),
        '+07:00'
    );

    RETURN CONVERT_TZ(`p_utc_datetime`, '+00:00', v_utc_offset);
END$$
DELIMITER ;

DROP FUNCTION IF EXISTS `fn_site_local_date`;
DELIMITER $$
CREATE FUNCTION `fn_site_local_date`(
    `p_location_id` BIGINT UNSIGNED,
    `p_utc_datetime` DATETIME
)
RETURNS DATE
READS SQL DATA
COMMENT 'Local calendar date of a location for a UTC time (WIB when the site is NULL or unknown)'
BEGIN
    RETURN DATE(`fn_site_local_datetime`(`p_location_id`, `p_utc_datetime`));
END$$
DELIMITER ;
