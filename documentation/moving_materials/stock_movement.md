# Stock Movement (Bin Stock and Bin-to-Bin Move)

> **Stock movement** is the core of WISBAR. Every change to the stock in a bin is a **stock movement detail** line, either **in** or **out** of one bin inventory (bin × batch). The document types that move stock are: picking, put away, item reclassification, stock reversal, and the plain **stock movement** (moving stock between bins inside one warehouse).

Related: [Organization](../master_data/organization.md) · [Picking](picking.md) · [Put away](put_away.md) · [Item reclassification](item_reclassification.md) · [Stock reversal](stock_reversal.md)

---

## 1. Data architecture

```mermaid
erDiagram
    transaction_headers ||--o| stock_movements : "is a"
    stock_movements ||--o| pickings : "is a"
    stock_movements ||--o| put_aways : "is a"
    stock_movements ||--o| item_reclassifications : "is a"
    stock_movements ||--o| stock_reversals : "is a"

    transactions ||--o| stock_movement_details : "is a"
    stock_movements ||--o{ stock_movement_details : "has lines"
    stock_movement_details ||--o| picking_details : "is a (out)"
    stock_movement_details ||--o| put_away_details : "is a (in)"
    stock_movement_details ||--o| stock_reversal_details : "is a"

    warehouse_bin_inventories ||--o{ stock_movement_details : "moved by"
    warehouse_bins ||--o{ warehouse_bin_inventories : "holds"
    batches ||--o{ warehouse_bin_inventories : "stocked as"
```

**In short:** every stock document is a `stock_movements` row. Each of its lines points to **one bin inventory** and says *in* or *out* and *how much*. The sum of signed lines is the bin stock.

---

## 2. Data structure

### `stock_movements` (CTI parent)

`transaction_header_type` is one of `stock_movement`, `picking`, `put_away`, `item_reclassification` or `stock_reversal`. A plain `stock_movement` has no child table. It is a bin move inside one warehouse.

### `stock_movement_details`: one stock line

| Field | Stores |
| --- | --- |
| `warehouse_bin_inventory_id` | Which bin × batch is changed |
| `type` | `in` or `out`. A bin move is one *out* line plus one *in* line. |
| `amount` | Quantity in the item base unit (> 0) |
| `pallet_count` | Pallets moved (NULL means not counted) |
| `moved_by` | Who physically moved it |

### `warehouse_bin_inventories`: the stock balance

| Field | Stores |
| --- | --- |
| `warehouse_bin_id`, `batch_id` | The bin and batch (one row per pair) |
| `current_amount` | Stock now, in base unit (never negative) |
| `current_pallet_amount` | Pallets now |
| `filled_at` | Last time stock went above zero (for **FIFO**) |
| `depleted_at` | Last time stock hit zero |

The balance is a **cache** of the signed stock lines. Rows are never deleted, so an empty bin keeps its history.

---

## 3. What it does & business process

**Purpose:** keep one exact, auditable stock figure per bin and batch, and record why it changed.

### What changes stock

| Document | Direction | Page |
| --- | --- | --- |
| Put away | in | [put_away.md](put_away.md) |
| Picking | out | [picking.md](picking.md) |
| Stock movement (bin move) | out + in, same warehouse | this page |
| Item reclassification | out + in, same bin | [item_reclassification.md](item_reclassification.md) |
| Stock reversal | opposite of the original | [stock_reversal.md](stock_reversal.md) |

### Bin-to-bin move (plain stock movement)

Used to reorganise a warehouse: consolidate half-empty bins, move stock nearer to picking, or empty a bin for maintenance.

1. The warehouse admin creates a **stock movement** document (draft).
2. For each batch to move, add **two lines**:
   - an **out** line from the source bin inventory
   - an **in** line into the target bin inventory, with the same amount and pallets
3. Warehouse staff scan the box and the source bin, move the pallet, and scan the target bin.
4. The supervisor signs.
5. On signing, the bin inventories are updated:
   - the source goes down, and `depleted_at` is set if it reaches 0
   - the target goes up, and `filled_at` is set if it was 0

### Rules

- Stock can never go negative.
- Pallets need stock: pallets above 0 with an amount of 0 is refused.
- A picking line must be *out*, and a put-away line must be *in*.
- Lines of a signed document are locked. Use a stock reversal to cancel one.
- The target bin should be active and designated for the item, with room left.

---

## 4. Flowchart

```mermaid
flowchart TD
    A(["Start: need to move stock<br/>between bins"]) --> B["Create stock movement draft"]
    B --> C["Choose source bin inventory<br/>bin × batch"]
    C --> D{"Enough stock<br/>in source?"}
    D -- "No" --> C
    D -- "Yes" --> E["Choose target bin<br/>active, designated, room left"]
    E --> F["Add OUT line: source<br/>Add IN line: target, same amount"]
    F --> G["Staff scan box + source bin,<br/>move, scan target bin"]
    G --> H["Submit for sign-off"]
    H --> I{"Supervisor decision"}
    I -- "Reject" --> F
    I -- "Sign" --> J["Source stock down<br/>Target stock up"]
    J --> K["Update filled_at / depleted_at"]
    K --> Z(["Done"])
```

---

## 5. Swimlane

```mermaid
flowchart LR
    subgraph WA["Warehouse Admin"]
        direction TB
        a1["1 · Create stock movement draft"]
        a2["2 · Pick source and target bins"]
        a3["3 · Add OUT + IN lines"]
        a4["6 · Submit for sign-off"]
    end
    subgraph WS["Warehouse Staff"]
        direction TB
        w1["4 · Scan box and source bin"]
        w2["5 · Move pallet, scan target bin"]
    end
    subgraph SUP["Logistic Supervisor"]
        direction TB
        s1{"7 · Sign or reject"}
    end
    subgraph SYS["System (WISBAR)"]
        direction TB
        y1["8 · Lock document"]
        y2["9 · Update bin inventories<br/>filled_at / depleted_at"]
    end
    a1 --> a2 --> a3 --> w1 --> w2 --> a4 --> s1
    s1 -- "Reject" --> a3
    s1 -- "Sign" --> y1 --> y2
```
