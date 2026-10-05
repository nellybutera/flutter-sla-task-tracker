# Project & SLA Task Tracker (Flutter)

Group project for Formative Assignment 1 (ALU, course 3141). A Flutter mobile app that lets a small software team create tasks, assign them, set deadlines and see SLA status (On Track, At Risk, Overdue, Completed). No backend; data is stored locally.

## Screens
1. Sign In / User Selection
2. Project Dashboard
3. Task List
4. Task Details
5. Create / Edit Task
6. Team Members / Profile

## Team and branches
| Member | Branch |
|---|---|
| Member A: TBD | `feature/member-a-storage-signin-details` |
| Member B: TBD | `feature/member-b-sla-dashboard-team` |
| Member C: TBD | `feature/member-c-validation-list-form` |

Work only on your own branch. Merge into `main` through pull requests reviewed by a teammate. See [docs/TASK_DISTRIBUTION.md](docs/TASK_DISTRIBUTION.md).

## Planned structure
```
lib/
  main.dart
  models/        task.dart, user.dart
  services/      storage_service.dart, sla_service.dart, stats_service.dart, validators.dart
  screens/       sign_in, dashboard, task_list, task_details, task_form, team
  widgets/       status_chip.dart, task_card.dart
test/            one test file per service
```

## SLA rule (to be agreed by the team)
- Completed: status is done.
- Overdue: not done and deadline has passed.
- At Risk: not done and deadline is within the risk window (proposed: 48 hours, or under 20% of the task's time left).
- On Track: everything else.

## Run
`flutter pub get` then `flutter run` on an emulator or physical device (browser builds are not graded).
