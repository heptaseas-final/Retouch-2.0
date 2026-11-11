# Playbook: change, fix or refactor existing code

Read `../engineering.md` first.

1. Ask for the current version of every file you will change. Do not rely on memory or an old copy.
2. Make the smallest diff that solves the task. Keep names, order and formatting of everything else.
3. Do not move, rename or reformat code you are not changing. Do not fix unrelated issues, list them in the report instead.
4. If the change would push a file over 300 lines, stop and propose a split. Do not split inline.
5. If the file is a hotspot (see `../engineering.md` section 10), keep the change append-only or minimal and ask who owns it.
6. Changing a tuning number: state old and new value and which acceptance criterion in SPEC.md it affects.
7. Refactor without behavior change:
   - First capture current behavior with a test or a short manual checklist.
   - Then change the code.
   - Moves and logic changes go in separate commits.
   - Delete only code that your change orphaned. List other dead code instead.
8. Report the files changed, what was not verified, and what to check on a real iPhone.
