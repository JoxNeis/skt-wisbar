-- Lifecycle: unsigned (draft) -> signed (by a signed sign-off of the creator supervisor) -> reversed.
-- A signed document can only become reversed; a reversed document never changes again.
-- A stock document is reversed only by signing a complete stock_reversal; a stock_reversal is never reversed.

DROP TRIGGER IF EXISTS `trg_transaction_headers_before_insert`;
DELIMITER $$
CREATE TRIGGER `trg_transaction_headers_before_insert`
BEFORE INSERT ON `transaction_headers`
FOR EACH ROW
BEGIN
    IF NEW.`status` <> 'unsigned' OR NEW.`deleted_at` IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'transaction_headers: a new document must be an active draft';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_transaction_headers_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_transaction_headers_before_update`
BEFORE UPDATE ON `transaction_headers`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128);

    IF OLD.`status` = 'reversed' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'transaction_headers: a reversed document is read-only';
    END IF;

    IF OLD.`status` = 'signed' THEN
        IF NEW.`status` <> 'reversed'
           OR NOT (NEW.`uuid` <=> OLD.`uuid`
               AND NEW.`transaction_header_type` <=> OLD.`transaction_header_type`
               AND NEW.`location_id` <=> OLD.`location_id`
               AND NEW.`document_number` <=> OLD.`document_number`
               AND NEW.`remarks` <=> OLD.`remarks`
               AND NEW.`created_by` <=> OLD.`created_by`
               AND NEW.`created_at` <=> OLD.`created_at`
               AND NEW.`deleted_at` <=> OLD.`deleted_at`) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'transaction_headers: a signed document can only be reversed';
        END IF;

        IF NEW.`transaction_header_type` = 'stock_reversal' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'transaction_headers: a stock reversal cannot be reversed';
        END IF;

        IF EXISTS (
            SELECT 1
            FROM `stock_movements` AS `smv`
            WHERE `smv`.`id` = NEW.`id`
        ) AND NOT EXISTS (
            SELECT 1
            FROM `stock_reversals` AS `srv`
            INNER JOIN `transaction_headers` AS `thd`
                ON `thd`.`id` = `srv`.`id`
            WHERE `srv`.`reversed_transaction_header_id` = NEW.`id`
              AND `srv`.`active_key` = 1
              AND `thd`.`status` = 'signed'
        ) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'transaction_headers: a stock document is reversed by signing a stock reversal';
        END IF;
    END IF;

    IF OLD.`status` = 'unsigned' THEN
        IF NEW.`status` = 'reversed' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'transaction_headers: only a signed document can be reversed';
        END IF;

        IF NEW.`status` = 'signed' AND (
            NEW.`deleted_at` IS NOT NULL
            OR NOT EXISTS (
                SELECT 1
                FROM `transaction_header_sign_offs` AS `tso`
                WHERE `tso`.`transaction_header_id` = NEW.`id`
                  AND `tso`.`decision` = 'signed'
            )
        ) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'transaction_headers: a document is signed through a signed sign-off';
        END IF;

        IF NEW.`status` = 'signed' AND NEW.`transaction_header_type` = 'stock_reversal' THEN
            SET v_error = `fn_validate_stock_reversal_complete`(NEW.`id`);
            IF v_error IS NOT NULL THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
            END IF;
        END IF;
    END IF;
END$$
DELIMITER ;

-- Reversing or deleting a document frees its active_key rows; deleting a draft also deletes its lines
DROP TRIGGER IF EXISTS `trg_transaction_headers_after_update`;
DELIMITER $$
CREATE TRIGGER `trg_transaction_headers_after_update`
AFTER UPDATE ON `transaction_headers`
FOR EACH ROW
BEGIN
    IF (NEW.`status` = 'reversed' AND OLD.`status` <> 'reversed')
       OR (NEW.`deleted_at` IS NOT NULL AND OLD.`deleted_at` IS NULL) THEN
        CASE NEW.`transaction_header_type`
            WHEN 'delivery_note' THEN
                UPDATE `delivery_notes` SET `active_key` = NULL WHERE `id` = NEW.`id`;
            WHEN 'incoming' THEN
                UPDATE `incomings` SET `active_key` = NULL WHERE `id` = NEW.`id`;
            WHEN 'production_group_usage' THEN
                UPDATE `production_group_usages` SET `active_key` = NULL WHERE `id` = NEW.`id`;
            WHEN 'production_return' THEN
                UPDATE `production_returns` SET `active_key` = NULL WHERE `id` = NEW.`id`;
            WHEN 'picking' THEN
                UPDATE `picking_details` SET `active_key` = NULL WHERE `picking_id` = NEW.`id`;
            WHEN 'handover' THEN
                UPDATE `handovers` SET `active_key` = NULL WHERE `id` = NEW.`id`;
                UPDATE `handover_details` SET `active_key` = NULL WHERE `handover_id` = NEW.`id`;
            WHEN 'put_away' THEN
                UPDATE `put_aways` SET `active_key` = NULL WHERE `id` = NEW.`id`;
                UPDATE `put_away_details` SET `active_key` = NULL WHERE `put_away_id` = NEW.`id`;
            WHEN 'stock_reversal' THEN
                UPDATE `stock_reversals` SET `active_key` = NULL WHERE `id` = NEW.`id`;
                UPDATE `stock_reversal_details` SET `active_key` = NULL WHERE `stock_reversal_id` = NEW.`id`;
            ELSE
                BEGIN
                END;
        END CASE;
    END IF;

    IF NEW.`deleted_at` IS NOT NULL AND OLD.`deleted_at` IS NULL THEN
        UPDATE `transactions`
        SET `deleted_at` = NEW.`deleted_at`
        WHERE `transaction_header_id` = NEW.`id`
          AND `deleted_at` IS NULL;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_transaction_headers_before_delete`;
DELIMITER $$
CREATE TRIGGER `trg_transaction_headers_before_delete`
BEFORE DELETE ON `transaction_headers`
FOR EACH ROW
BEGIN
    IF OLD.`status` <> 'unsigned' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'transaction_headers: a signed document is read-only';
    END IF;
END$$
DELIMITER ;

-- Lines are added to an active draft only, and never change once the document is signed
DROP TRIGGER IF EXISTS `trg_transactions_before_insert`;
DELIMITER $$
CREATE TRIGGER `trg_transactions_before_insert`
BEFORE INSERT ON `transactions`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128) DEFAULT `fn_validate_transaction`(NEW.`transaction_header_id`, NEW.`transaction_type`, NEW.`transaction_header_type`);
    IF v_error IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_transactions_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_transactions_before_update`
BEFORE UPDATE ON `transactions`
FOR EACH ROW
BEGIN
    IF `fn_transaction_header_is_locked`(OLD.`transaction_header_id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'transactions: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_transactions_before_delete`;
DELIMITER $$
CREATE TRIGGER `trg_transactions_before_delete`
BEFORE DELETE ON `transactions`
FOR EACH ROW
BEGIN
    IF `fn_transaction_header_is_locked`(OLD.`transaction_header_id`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'transactions: the document is signed and read-only';
    END IF;
END$$
DELIMITER ;

-- Sign-offs are append-only; a signed one signs its document, and a signed stock reversal reverses its document
DROP TRIGGER IF EXISTS `trg_transaction_header_sign_offs_before_insert`;
DELIMITER $$
CREATE TRIGGER `trg_transaction_header_sign_offs_before_insert`
BEFORE INSERT ON `transaction_header_sign_offs`
FOR EACH ROW
BEGIN
    DECLARE v_error VARCHAR(128) DEFAULT `fn_validate_transaction_header_sign_off`(NEW.`transaction_header_id`, NEW.`decision`, NEW.`remarks`, NEW.`signed_by`);
    IF v_error IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_transaction_header_sign_offs_after_insert`;
DELIMITER $$
CREATE TRIGGER `trg_transaction_header_sign_offs_after_insert`
AFTER INSERT ON `transaction_header_sign_offs`
FOR EACH ROW
BEGIN
    IF NEW.`decision` = 'signed' THEN
        UPDATE `transaction_headers`
        SET `status` = 'signed'
        WHERE `id` = NEW.`transaction_header_id`;

        UPDATE `transaction_headers` AS `thd`
        INNER JOIN `stock_reversals` AS `srv`
            ON `srv`.`reversed_transaction_header_id` = `thd`.`id`
        SET `thd`.`status` = 'reversed'
        WHERE `srv`.`id` = NEW.`transaction_header_id`
          AND `srv`.`active_key` = 1;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_transaction_header_sign_offs_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_transaction_header_sign_offs_before_update`
BEFORE UPDATE ON `transaction_header_sign_offs`
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'transaction_header_sign_offs: sign-offs are read-only';
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_transaction_header_sign_offs_before_delete`;
DELIMITER $$
CREATE TRIGGER `trg_transaction_header_sign_offs_before_delete`
BEFORE DELETE ON `transaction_header_sign_offs`
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'transaction_header_sign_offs: sign-offs are read-only';
END$$
DELIMITER ;
