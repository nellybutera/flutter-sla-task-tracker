# Task distribution

Every member gets the same shape of work: 2 screens, 1 service or logic module, 1 shared piece, unit tests for their module. Everyone therefore commits UI code, logic code and tests, so GitHub credit is shared evenly.

## Member A: storage, sign-in, task details
- Project skeleton, `pubspec.yaml`, folder structure (push to `main` first, day 1)
- `models/task.dart`, `models/user.dart` (toJson / fromJson)
- `services/storage_service.dart`: load, save, update, delete tasks and users (SharedPreferences or sqflite; write down why)
- Screen 1: Sign In / User Selection
- Screen 4: Task Details (info, SLA chip, edit, mark complete, delete with confirmation)
- Tests: storage round trip, model serialization

## Member B: SLA logic, dashboard, team
- `services/sla_service.dart`: returns On Track / At Risk / Overdue / Completed
- `services/stats_service.dart`: percent complete, counts per status, tasks needing attention
- App theme and bottom navigation shell (routes for all six screens)
- Screen 2: Project Dashboard
- Screen 6: Team Members / Profile (members with task counts)
- Tests: every SLA boundary case, stats counts

## Member C: validation, task list, create/edit form
- `services/validators.dart`: required title, minimum length, deadline rules, assignee required, priority required
- `widgets/status_chip.dart`, `widgets/task_card.dart` (shared widgets)
- Screen 3: Task List (scrolling, filter by status / priority / assignee, sort by deadline, empty state)
- Screen 5: Create / Edit Task (Form, TextFormField, dropdowns, date picker, error messages)
- Tests: each validator, valid and invalid inputs

## Shared by all
- Own branch, small commits spread over several days, clear messages, pull request per finished piece, reviewed by another member
- Update the contribution tracker after each piece of work
- Record AI use for your own code (what you asked, what you changed, how you tested)
- Be able to open your files in the demo and change something live

## Review pairs (keeps credit and understanding spread)
A reviews B, B reviews C, C reviews A.

## Roles beyond code
- Design lead: Member B (theme, colors, typography, spacing, consistency review of every screen)
- Integration lead: Member A (owns `main`, merges PRs, resolves conflicts)
- QA / demo lead: Member C (test checklist, demo script, recording)

## Dependencies (who is waiting on whom)
| Needs | From | Why |
|---|---|---|
| `Task`, `User` models and `StorageService` interface | A | Everyone's screens read and write tasks. A pushes these within the first 2 hours, as stubs if needed |
| `SlaService.statusFor(task)` signature | B | Dashboard, task card, details and list all show the status. B pushes the signature first, logic after |
| Theme and navigation shell | B | Every screen plugs into it. Until it lands, build screens as plain widgets |
| `StatusChip` and `TaskCard` widgets | C | Dashboard, list and details reuse them |
| `Validators` | C | Sign-in (A) uses the name validator |
| Create/Edit form | C | Details (A) calls it for Edit |

Rule: agree the method signatures in the first 30 minutes, push empty stubs, then everyone works in parallel.

## 3-day plan
| When | Member A | Member B | Member C |
|---|---|---|---|
| Day 1 morning | Skeleton, models, storage stubs pushed to main (blocker for others) | SLA signature + theme + navigation shell pushed | Validators, StatusChip, TaskCard |
| Day 1 afternoon | Storage implementation, Sign-In screen | SLA logic, stats service, Dashboard | Task List screen, start Create/Edit form |
| Day 2 morning | Task Details screen, delete flow | Team screen, polish theme across screens | Finish Create/Edit form and validation |
| Day 2 afternoon | Merge all PRs into main, fix conflicts, test persistence | Unit tests for SLA and stats, design review | Unit tests for validators, full test checklist run |
| Day 3 morning | Bug fixes, tracker, AI declaration | Bug fixes, report (3 pages) | Bug fixes, technical report, demo script |
| Day 3 afternoon | Record demo (everyone speaks), assemble PDF, submit | | |
