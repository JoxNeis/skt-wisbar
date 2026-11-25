-- Times are UTC; 20:00 UTC = 03:00 WIB
DROP EVENT IF EXISTS `ev_user_session_purge`;

CREATE EVENT `ev_user_session_purge`
    ON SCHEDULE EVERY 1 DAY
    STARTS (CURRENT_DATE + INTERVAL 1 DAY + INTERVAL 20 HOUR)
    ON COMPLETION PRESERVE
    ENABLE
    COMMENT 'Deletes user_sessions that expired or were revoked more than 30 days ago'
DO
    DELETE FROM `user_sessions`
    WHERE `expires_at` < UTC_TIMESTAMP() - INTERVAL 30 DAY
       OR `revoked_at` < UTC_TIMESTAMP() - INTERVAL 30 DAY;
