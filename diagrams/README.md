# Life Link — Thesis Diagrams

Finished diagram images for the thesis. Just drag the file you need into your
thesis document — nothing to render or install.

All images live in the `images/` folder.

| # | Diagram | Image files (in `images/`) |
|---|---------|----------------------------|
| 1 | **Entity Relationship Diagram (ERD)** | `01_ERD.png` · `01_ERD.svg` |
| 2 | **Use Case Diagram** (classic UML, recommended) | `02_use_case_UML.png` · `02_use_case_UML.svg` |
| 2b | Use Case Diagram (Mermaid style, alternative) | `02_use_case.png` · `02_use_case.svg` |
| 3 | **DFD — Level 0 (Context)** | `03_DFD_level0_context.png` · `.svg` |
| 4 | **DFD — Level 1** | `04_DFD_level1.png` · `.svg` |

> **PNG** = drop directly into Word / Google Docs.
> **SVG** = vector, stays sharp at any zoom or print size — use it if your editor
> supports it (best for a printed thesis).

---

## Notes on the system these diagrams describe

- **Backend:** Firebase (Firestore database, Firebase Auth, Firebase Storage, Firebase Cloud Messaging).
- **Actors:** *Donor / User* (standard app user) and *Admin* (manages ambulances,
  organizations and volunteers). Both authenticate through Firebase Auth.
- **Core entities:** User, Blood Request, Chat, Message, Notification, Organization,
  Ambulance, Volunteer.
