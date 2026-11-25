# Business Processes

This folder explains, in plain language, every process WisBar supports: what
happens on the floor, who does it, and what WisBar keeps about it and why.
Each document ends with a short **For the technical team** section that names
the database records behind the process; everything above it is written for
the people who run the process.

## Where to start

| I want to know… | Read |
| --- | --- |
| How stock moves through the warehouse, step by step | [Warehouse execution process](warehouse_execution/warehouse_execution_process.md) |
| What has to be set up before anything can move | [Master data](#master-data) |
| Who can log in and what they are allowed to do | [People and access](#people-and-access) |
| How records are locked, corrected and traced | [Records and audit](#records-and-audit) |

## Warehouse execution

Everything that physically moves stock, or changes what WisBar says is on the
shelf. All flows follow the same pattern, described in
[Warehouse execution process](warehouse_execution/warehouse_execution_process.md).

| Process | What it covers |
| --- | --- |
| [Delivery notes](warehouse_execution/delivery_notes.md) | The paperwork that travels with a shipment, and how it links a sender to a receiver |
| [Item incoming](warehouse_execution/item_incoming.md) | Receiving a delivery: brand check, count, weighing, accepting or rejecting |
| [Item put away](warehouse_execution/item_put_away.md) | Moving received material into storage bins, and rejected material into quarantine bins |
| [Production order](warehouse_execution/production_order.md) | At the beginning of the day, production orders material into its staging storage: from its return storage first, the rest from the main warehouse |
| [Production usage and end-of-day report](warehouse_execution/production_usage_and_report.md) | The day sheet of material taken, rejected and brought back by production groups, the end-of-day count, and the loss or gain |
| [Production return](warehouse_execution/production_return.md) | The day's leftover moves from staging into the production's return storage |
| [Internal transfer](warehouse_execution/internal_transfer.md) | Stock moves from one warehouse to another in the same organization |
| [Outbound](warehouse_execution/outbound.md) | Stock leaves for another organization, with a delivery note |
| [Item reclassification](warehouse_execution/item_reclassification.md) | Stock in a bin is recorded under a different item, code or batch |
| [Warehouse reject](warehouse_execution/warehouse_reject.md) *(planned)* | Material found unfit in storage goes to quarantine |

## Master data

The things every process refers to. They are set up once and changed rarely.

| Process | What it covers |
| --- | --- |
| [Organizations and sites](master_data/organizations_and_sites.md) | Companies, vendors, manufacturing sites, site areas, and which brands a site handles |
| [Facilities and bins](master_data/facilities_and_bins.md) | Warehouses, production facilities, bins, bin designations, and how bin stock is counted |
| [Items and batches](master_data/items_and_batches.md) | Brands, materials, items, item files, batches and units of measurement |

## People and access

| Process | What it covers |
| --- | --- |
| [User accounts and sign-in](people_and_access/user_accounts_and_sign_in.md) | Accounts, passwords, sign-in, lockout and sessions |
| [Employees and jobdesks](people_and_access/employees_and_jobdesks.md) | Employee records, supervisors, jobdesks and where each employee works |
| [Permissions](people_and_access/permissions.md) | What each jobdesk or employee is allowed to do, and for how long |

## Records and audit

| Process | What it covers |
| --- | --- |
| [Signing and corrections](records_and_audit/signing_and_corrections.md) | How a record is signed and locked, and how a locked record is corrected or cancelled |
| [Document numbers and files](records_and_audit/document_numbers_and_files.md) | How document numbers are issued, and how uploaded files are kept |
| [Activity and system logs](records_and_audit/activity_and_system_logs.md) | Who did what, and what went wrong |

## Glossary

| Term | Meaning |
| --- | --- |
| **Site** | A location: a manufacturing plant. It is one organization, has its own time zone, and is split into site areas. |
| **Facility** | A warehouse or a production facility inside a site area. |
| **Bin** | One stock location inside a warehouse, such as a rack position or floor spot. Every piece of stock is in exactly one bin. |
| **Batch** | A quantity of one item that arrived or was produced together. It has its own code, production date and expiry date. |
| **Bin stock** | How much of one batch is in one bin. WisBar always counts stock per bin and batch, in the item's base unit. |
| **Base unit** | The one unit all stock of an item is kept in. Other units people use are converted into it. |
| **Stock count** | A count of bins that sets WisBar's stock to what was counted. The end-of-day count is one. |
| **FIFO** | First in, first out: the oldest stock is used first. |
| **FEFO** | First expired, first out: the batch closest to expiry is used first. |
| **Staging storage** | The warehouse next to a production facility where its material waits to be used. |
| **Return storage** | The warehouse where a production facility's unused leftover is kept. |
| **Quarantine** | Bins and warehouses for rejected or suspect stock. Stock in quarantine can never be ordered or used. |
| **Production group** | A team inside one production facility that takes material from staging to its line. |
| **Day sheet** | One document per production per day holding all of that day's group usages, rejects and returns. Signed once, at the end of the day. |
| **Group return** | Unused material a production group brings back to staging during the day. Not the same as a production return, which moves the counted leftover from staging to the return storage. |
| **Allocation** | A reservation of specific stock (bin and batch) that is going to be taken. |
| **Plotting** | A plan of which bin received stock is going to be put into: planned, put away or cancelled. |
| **Handover** | The moment material passes from one person's responsibility to another's. |
| **Signing** | A responsible person confirms a record. After signing, the record is locked, and a record that moves stock changes the stock. |
| **Reversal** | The only way to undo a signed record: it is cancelled (a stock record by a stock reversal with the opposite lines) and a new one is recorded. |
