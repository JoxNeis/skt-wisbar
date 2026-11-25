# Activity and System Logs

WisBar keeps two kinds of logs. The **activity log** answers business
questions: who did what, to which record, and was it allowed? The **system
log** answers technical questions: what went wrong, where, and how long did it
take?

| | Activity log | System log |
| --- | --- | --- |
| Read by | Supervisors, auditors, administrators | The IT team |
| Records | Business and account actions | Errors, slow operations, background jobs, connections to other systems |
| Changed afterwards? | Never: entries are only ever added | No: entries are written once, for troubleshooting |

## Activity log

One entry for every business or account action, for example "delivery note
created" or "account locked".

| What WisBar keeps | Why |
| --- | --- |
| Who did it (or "system", or nobody signed in) | Accountability. |
| The site, when the action belongs to one | To review one site's activity. |
| The action, the kind of record and which record | What was done, and to what. |
| A readable description | So the entry can be understood without opening the record. |
| The values before and after | Exactly what changed. |
| Result: success, failure or denied | "Denied" shows someone tried something they were not allowed to do. |
| Error code and remarks, when relevant | Why an action failed. |
| Session, network address and browser | Which device it came from, matched to the [sign-in session](../people_and_access/user_accounts_and_sign_in.md). |
| Where it came from: the app, an outside connection, or a background job | To tell people's actions from automatic ones. |
| When | Entries are stored by period so old ones can be archived. |

The activity log complements [signing and corrections](signing_and_corrections.md):
signing proves a document has not changed; the activity log shows everything
people did around it, including attempts that failed or were refused.

## System log

One entry for every technical event worth keeping.

| What WisBar keeps | Why |
| --- | --- |
| Event name and a readable message | What happened. |
| Severity: debug, info, warning, error or critical | How urgent it is. |
| Environment: development, testing, staging or production | So test noise is never mistaken for a live problem. |
| Source, component and operation | Which part of WisBar raised it. |
| Result: started, success, failure, timeout or cancelled | How the operation ended. |
| Web request details: method, address, response code | To reproduce a failing screen or connection. |
| Duration and memory used | To find slow or heavy operations. |
| Error code, error type and error details | To fix the cause. |
| Extra details and measurements | For example how many rows were processed or retried. |
| Links to related events, the user, and the request | To follow one problem through every part of WisBar. |
| When it happened, and when it was written | Entries are stored by period so old ones can be archived. |

Both logs are stored by month. WisBar prepares the next months' storage
automatically, so entries never pile up in one place. The nightly check of
every site's [seal chain](signing_and_corrections.md#the-seal-chain) writes
one system log entry per site: passed, failed (critical) or skipped.

## For the technical team

`activity_logs` (append-only, `location_id`, partitioned by
`created_at`), `system_logs` (partitioned by `occurred_at`; `parent_log_id`,
`trace_id`, `request_id`). `ev_log_partition_roll` runs `sp_log_partition_roll`
monthly to keep partitions three months ahead. Seal verification entries:
`seal.verification.passed`, `.failed` and `.skipped`, written through
`sp_system_log_create`.
