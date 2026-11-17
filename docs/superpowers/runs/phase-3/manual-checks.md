# Phase 3 run — owner manual checks

Checks will be appended by screen and flow as tasks complete, plus sections for **After the Anthropic key exists** and **The 30-receipt measurement**.

## S8 and S4 — photos on transactions (3A.4)

1. Add an expense with a photo from your phone → the thumbnail shows in the form; saving shows the photo mark on the row in S4; tapping the expense reopens it and the photo opens full-screen (closable by button, Escape, or backdrop).
2. Open the photo's content address (`/api/v1/groups/{id}/attachments/{attachmentId}/content`) in a private window (signed out) → 401/not found; as a viewer in the group, open the expense with photos → photos open full-screen and no `Thêm ảnh` or remove control exists.
