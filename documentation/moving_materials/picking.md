# Picking (Stock Out)

> A **picking** takes the [allocated](allocation.md) stock of one [request](request.md) **out of its bins**. Every picking line carries out exactly one allocation and is an **OUT** stock line, so signing a picking **lowers bin stock**. The picked material then waits for [handover](handover.md).

Related: [Allocation](allocation.md) · [Handover](handover.md) · [Stock movement](stock_movement.md)

---

## 1. Data architecture

```mermaid
erDiagram
    stock_movements ||--o| pickings : "is a"
    requests ||--o{ pickings : "picked by"
    warehouses ||--o{ pickings : "from"
    pickings ||--|{ picking_details : "has lines"
    stock_movement_details ||--o| picking_details : "is a (OUT line)"
    allocations ||--o| picking_details : "carried out by"
    warehouse_bin_inventories ||--o{ stock_movement_details : "decreased"
    pickings ||--o| handovers : "handed over by"
    picking_details ||--o| handover_details : "handed over as"
```

---

## 2. Data structure

### `pickings`: header

| Field | Stores |
| --- | --- |
| `request_id` | Request being fulfilled |
| `from_warehouse_id` | Every line must come from a bin of this warehouse |

### `picking_details`: one OUT line per allocation

| Field | Stores |
| --- | --- |
| `allocation_id` | The allocation this line carries out |
| `request_id` | Copied (must match) |
| `active_key` | 1 = draft or signed, NULL = reversed or deleted |

It inherits from `stock_movement_details`: `warehouse_bin_inventory_id` (must be the allocation's), `type = out`, `amount`, `pallet_count`, `moved_by`.

---

## 3. What it does & business process

**Purpose:** remove reserved stock from the bins in a controlled, scanned way, so the stock figure drops exactly when material leaves the bin.

1. **Create a picking** for a request, from one warehouse. If allocations span several warehouses, make one picking per warehouse.
2. **Lines from allocations:** the system creates one **OUT** line per `reserved` allocation, on its bin inventory, with its amount.
3. **Pick list:** warehouse staff get the list sorted by bin path (hall, column, position).
4. **Pick and scan:** at each bin, scan the **bin** and the **boxes**. They must match the allocation. Record pallets and `moved_by`.
5. **Bring to staging:** picked pallets wait in the staging area for [handover](handover.md).
6. **Submit**, and the supervisor signs.
7. **On signing:**
   - bin stock **decreases**, and `depleted_at` is set if the bin reaches 0
   - allocations become `picked`
8. **Next:** create the [handover](handover.md).

### Rules

- A picking line is always **out**.
- It must move the bin inventory of its own allocation, from the picking's warehouse.
- One allocation has at most one active picking line.
- One picking has at most one active handover.
- Stock cannot go below zero.

---

## 4. Flowchart

```mermaid
flowchart TD
    A(["Request has reserved allocations"]) --> B["Create picking<br/>request + from warehouse"]
    B --> C["OUT line per allocation"]
    C --> D["Print / show pick list<br/>sorted by bin path"]
    D --> E["Go to bin, scan bin"]
    E --> F{"Bin = allocated bin?"}
    F -- "No" --> E
    F -- "Yes" --> G["Scan boxes"]
    G --> H{"Batch and amount match<br/>allocation?"}
    H -- "No" --> I["Report to admin:<br/>re-allocate"] --> C
    H -- "Yes" --> J["Move pallet to staging area"]
    J --> K{"More lines?"}
    K -- "Yes" --> E
    K -- "No" --> L["Submit for sign-off"]
    L --> M{"Supervisor decision"}
    M -- "Reject" --> E
    M -- "Sign" --> N["Bin stock − amount<br/>allocations = picked"]
    N --> Z(["Ready for handover"])
```

---

## 5. Swimlane

```mermaid
flowchart LR
    subgraph WA["Warehouse Admin"]
        direction TB
        a1["1 · Create picking for request"]
        a2["8 · Fix mismatch: re-allocate"]
        a3["7 · Submit for sign-off"]
    end
    subgraph SYS["System (WISBAR)"]
        direction TB
        y1["2 · OUT line per allocation<br/>pick list by bin path"]
        y2["4 · Check bin and batch"]
        y3["10 · Lower bin stock,<br/>allocations picked"]
    end
    subgraph WS["Warehouse Staff (Picker)"]
        direction TB
        w1["3 · Scan bin and boxes"]
        w2["5 · Take pallet out"]
        w3["6 · Bring to staging area"]
    end
    subgraph SUP["Logistic Supervisor"]
        direction TB
        s1{"9 · Sign or reject"}
    end
    a1 --> y1 --> w1 --> y2
    y2 -- "OK" --> w2 --> w3 --> a3 --> s1
    y2 -- "Mismatch" --> a2 --> y1
    s1 -- "Reject" --> w1
    s1 -- "Sign" --> y3
```
