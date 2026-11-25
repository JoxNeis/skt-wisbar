# Scanning Barcode

> Scanning always follows the **same rules, for goods coming in and going out**. A box barcode identifies the **batch** and the content of one box. A bin barcode identifies the **warehouse bin**. Scanning replaces typing, so lines are created from what is physically there.

Related: [Brand & Item](../master_data/brand.md) · [Incoming](../moving_materials/incoming.md) · [Picking](../moving_materials/picking.md) · [Put away](../moving_materials/put_away.md)

---

## 1. Data architecture

```mermaid
erDiagram
    BOX_BARCODE }o--|| batches : "identifies"
    BOX_BARCODE }o--|| items : "of item"
    batches }o--|| items : "lot of"
    batches }o--|| organizations : "origin"
    BIN_BARCODE ||--|| warehouse_bins : "identifies"
    warehouse_bins ||--o{ warehouse_bin_inventories : "holds"
    batches ||--o{ warehouse_bin_inventories : "stocked as"
    BOX_BARCODE }o--o{ incoming_details : "fills"
    BOX_BARCODE }o--o{ production_group_usage_details : "fills"
    BIN_BARCODE }o--o{ stock_movement_details : "confirms bin"
```

`BOX_BARCODE` and `BIN_BARCODE` are not tables. They are the printed labels the scanner reads.

---

## 2. Data structure

### What the box barcode stores

| Barcode part | Saved to |
| --- | --- |
| **Batch code** | `batches.batch_code` |
| **Production date** | `batches.production_date`, which with the item shelf life gives `batches.expiry_date` |
| **Box number** | Counted per line, for example `weighings.box_count` and `production_group_usage_details.box_count` |
| **Amount of item inside the box** | Line `amount` + `unit_of_measurement_id`. The system converts it to `base_amount`. |

The item comes from the label or the delivery note line. The origin organization comes from the sender of the delivery note.

### What the bin barcode stores

| Barcode part | Saved to |
| --- | --- |
| **Bin code** | `warehouse_bins.code` (unique within the warehouse) |

### Device

The scanner or terminal is recorded in `user_sessions.device_identifier`.

---

## 3. What it does & business process

**Purpose:** avoid typing mistakes and make every line traceable to a real box and a real bin.

### Same rules, in and out

1. **Scan the box:** read the batch code, production date, box number and amount.
2. **Resolve the batch:** find the batch by item + origin + batch code. On **incoming**, create it if it is new. On **outgoing**, it must already exist and be in stock.
3. **Check:**
   - The batch must not be `rejected`, and for allocation it must be `released`.
   - The unit must have a conversion to the item base unit.
   - On incoming, compare against the delivery note line.
   - On picking, compare against the allocation.
4. **Scan the bin:** confirm the bin where the box is put (put away) or taken from (picking).
   - On put away it must be the plotted bin.
   - On picking it must be the allocated bin.
5. **Add to the line:** every scan adds a box to the line's amount and box count.
6. **Duplicate check:** the same box number of the same batch is not counted twice on one document. The application enforces this.

### Where scanning is used

| Step | Scan box | Scan bin |
| --- | --- | --- |
| [Incoming](../moving_materials/incoming.md) | ✔ creates or finds the batch | – |
| [Put away](../moving_materials/put_away.md) | ✔ | ✔ plotted bin |
| [Picking](../moving_materials/picking.md) | ✔ | ✔ allocated bin |
| [Handover](../moving_materials/handover.md) | ✔ confirm amount | – |
| [Production usage](../moving_materials/production_usage.md) | ✔ what a group takes or returns | – |
| [Stock movement](../moving_materials/stock_movement.md) | ✔ | ✔ from and to bin |

---

## 4. Flowchart

```mermaid
flowchart TD
    A(["Scan box barcode"]) --> B["Read batch code, production date,<br/>box number, amount"]
    B --> C{"Batch exists?"}
    C -- "No" --> D{"Is this an incoming?"}
    D -- "Yes" --> E["Create batch<br/>expiry = production date + shelf life"] --> F
    D -- "No" --> X1["Reject scan: unknown batch"]
    C -- "Yes" --> F{"Quality status OK?"}
    F -- "rejected / on_hold" --> X2["Warn: blocked batch"]
    F -- "released" --> G{"Box already scanned<br/>on this document?"}
    G -- "Yes" --> X3["Ignore duplicate"]
    G -- "No" --> H{"Unit converts to<br/>base unit?"}
    H -- "No" --> X4["Reject: no conversion"]
    H -- "Yes" --> I{"Bin scan needed?"}
    I -- "No" --> K
    I -- "Yes" --> J{"Bin matches plotted /<br/>allocated bin?"}
    J -- "No" --> X5["Reject: wrong bin"]
    J -- "Yes" --> K["Add box to line<br/>amount and box count"]
    K --> Z(["Next scan"])
```

---

## 5. Swimlane

```mermaid
flowchart LR
    subgraph WS["Warehouse / Staging Staff"]
        direction TB
        w1["1 · Scan box barcode"]
        w2["4 · Scan bin barcode"]
        w3["7 · Fix: rescan or set aside"]
    end
    subgraph SYS["System (WISBAR)"]
        direction TB
        s1["2 · Decode batch, date, box no., amount"]
        s2["3 · Find / create batch<br/>check quality and conversion"]
        s3["5 · Check bin vs plan"]
        s4{"6 · Valid?"}
        s5["8 · Add to document line"]
    end
    subgraph WA["Warehouse Admin"]
        direction TB
        a1["9 · Review lines and submit<br/>for sign-off"]
    end
    w1 --> s1 --> s2 --> w2 --> s3 --> s4
    s4 -- "No" --> w3 --> w1
    s4 -- "Yes" --> s5 --> a1
```
