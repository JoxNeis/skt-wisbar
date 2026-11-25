# Document Numbers and Files

How WisBar gives documents readable numbers, and how it keeps the files people
upload.

## Document numbers

Every document type, for example a production order, gets its own numbering
rule at each site, so people can refer to "PO2410230001" instead of a long
internal reference. The number is given when the document is recorded and
stays on it.

A number is built from three parts:

| Part | Example | Meaning |
| --- | --- | --- |
| Prefix | `PO` | Fixed text that names the document type. |
| Period | `241023` | The site's local date in a set format (for example year, month, day). Optional. |
| Running number | `0001` | Counts up within the period, padded with zeros to a set length. |

When the period changes, for example on a new day, the running number starts
again from 1. A new day starts at local midnight of the site.

| What WisBar keeps for each document type | Why |
| --- | --- |
| The document type and site it numbers | Each type has exactly one numbering rule per site. |
| Prefix, period format and number length (1 to 18 digits) | How the number looks. |
| The current period and the last number issued in it | So the next number is always unique and never repeated. A deleted draft keeps its number, so it is not issued again. |

## Files

People can upload files, such as product photos or specification sheets, and
attach them to records. Files are attached to [items](../master_data/items_and_batches.md), and to
documents or one of their lines, for example photos of a rejected delivery as
evidence for a claim. Each file belongs to one item or one document.

| What WisBar keeps | Why |
| --- | --- |
| File kind: image, document or other | To show it the right way. |
| File name, extension and file format | To download it with its original name and open it with the right program. |
| Where the file is stored | WisBar keeps a pointer to the file, not the file itself. |
| A fingerprint of the file's contents | To detect a changed or duplicate file. |
| Size | Must be above zero; used to manage storage. |
| Description for screen readers (optional) | So people who cannot see the image know what it shows. |
| Valid from and valid until (the end can stay open) | A specification sheet can be replaced by a newer one without deleting the old. |

## Rules

- A file's valid-until cannot be before its valid-from.
- Deleting hides a record but keeps it for history.

## For the technical team

`document_sequences` (`document_type`, `location_id`, `prefix`,
`period_format` as a MySQL `DATE_FORMAT` pattern, `current_period`,
`current_value`, `padding_length`), issued by `sp_document_number_next` under a
row lock; `transaction_headers.document_number`; `attachments`
(`checksum_sha256`), `item_attachments`, `transaction_attachments`.
