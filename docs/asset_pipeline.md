# Asset Pipeline

Asset flow:
1. Requests are written in `assets/requests/`.
2. Raw or generated candidates go to `assets/incoming/`.
3. Reviewed production assets move to `assets/final/`.
4. References are stored in `assets/references/`.

Rules:
- Keep source request, incoming asset, and final asset paths linked in the task.
- Do not overwrite final assets without a task.
- Factory tiles for first pass use `assets/incoming/factory/`.
- Art tasks must define size, palette direction, and expected file output.
