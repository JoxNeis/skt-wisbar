# Warehouse Reject *(planned)*

How material found unfit while it is stored in a warehouse is taken out of its
storage bin and moved into a quarantine bin of another warehouse, so it can no
longer be allocated to any request.

> **Status: planned.** WisBar does not keep records for this flow yet. Today,
> only rejects found when a delivery arrives are recorded (see
> [Item incoming](item_incoming.md)). This page describes the agreed process so
> the records can be built to match it.

## At a glance

| | |
| --- | --- |
| From → To | A storage bin → quarantine bins of another warehouse |
| Starts with | A reject raised by Warehouse Staff |
| Effect on stock | The storage bin goes down at picking; the quarantine bin goes up at put away |

## Who is involved

| Role | What they do |
| --- | --- |
| Warehouse Staff (source) | Finds the unfit material, records the reject with its reason, picks it and hands it over. |
| Warehouse Staff (quarantine) | Checks the rejected material and puts it into a quarantine bin. Must be a different person from the source staff. |

## Steps

### 1. Reject (Warehouse Staff, source)

- Find stored material that can no longer be used, for example:
  - damaged in storage (wet, crushed, torn packaging);
  - **expired**, or too close to expiry to be used;
  - failing a quality check, or recalled by the vendor.
- Record the reject:
  - the **source**: the warehouse the material is stored in;
  - the **destination**: the warehouse whose quarantine bins will hold it,
    which must be a different warehouse;
  - for each batch: the quantity and the reason.

### 2. Allocation and picking (Warehouse Staff, source)

- Reserve and take the rejected material out of its storage bin, by batch. If
  only part of a batch is rejected, only that quantity is taken; the rest stays
  as good stock.

### 3. Handover

- The source staff hands the material to the staff responsible for
  quarantine, who checks each batch and quantity.
  - **Matches:** accept the handover.
  - **Does not match:** recount together; the handover records the quantity
    actually handed over.

### 4. Plotting and put away into quarantine (Warehouse Staff, quarantine)

- Plan and put each item into an active **quarantine bin** with room in the
  destination warehouse. A storage bin, an inactive bin or a full bin cannot be
  used.

| Result | Next step |
| --- | --- |
| $\text{Put away} = \text{Handed over}$ | Reject complete; the material is in quarantine. |
| $\text{Put away} < \text{Handed over}$ | Find the items not yet put away and continue. |

What happens to quarantined material afterwards (return to the vendor, or
disposal) is a separate process, not designed yet.

## What WisBar will need to keep

| What | Why |
| --- | --- |
| Source and destination warehouse, and who raised the reject | Where the material came from and where it is held. |
| Batch, quantity and reason per line | Traceability to the vendor, and evidence for claims or write-offs. |
| Allocation, picking, handover, plotting and put away | The same chain as every flow. |

## For the technical team

No tables yet. The flow becomes one more request type on the shared chain: a
`warehouse_rejects` table under `requests` (source and destination warehouse),
with `warehouse_reject` added to the header type lists, and its lines in
`request_details` with a reason. Allocation, picking, handover, plotting into
quarantine bins, and put away use the shared tables.
