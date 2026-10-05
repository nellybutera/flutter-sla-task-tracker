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

## Timeline
| Dates | Goal |
|---|---|
| Oct 5-6 | Repo, branches, tracker. A pushes skeleton and models. Agree the At Risk rule. |
| Oct 7-9 | Each member builds their screens and service on their own branch; first PRs open |
| Oct 10 | Integration check-in; merge into `main` |
| Oct 11-12 | Wire everything together, persistence, polish. Feature freeze Oct 12 |
| Oct 13 | Bug fixes, cleanup, rehearse explaining your code |
| Oct 14 | Record demo (10-15 min, everyone speaks) and write reports |
| Oct 15 | Assemble PDF and submit. Oct 16 is buffer |
