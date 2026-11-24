# Paperless-ngx

Scan, OCR and search all your paper documents.

Runs 5 containers: Paperless, PostgreSQL, Valkey (job queue), Tika and
Gotenberg (Office files and emails become searchable PDFs).

## Install
```bash
./homeserver install paperless   # needs PAPERLESS_DB_PASSWORD in .env
```
1. Open `http://<SERVER_IP>:8000` and create the admin account (the first
   account is the admin).
2. Settings (top right) > **Settings**: language, date display, dark mode.
3. Phone (optional): any Paperless-ngx app (e.g. Swift Paperless on iPhone), server
   `http://<SERVER_IP>:8000`.

## Adding documents
- **Web page**: drag files onto the page.
- **Consume folder** (`PAPERLESS_CONSUME_DIR`): drop files in, they are
  imported and removed. Point your scanner's "scan to folder" here.
  - Subfolders become tags: `consume/Bills/Power/x.pdf` gets `Bills`, `Power`.
  - Scanner only does one side? Scan all fronts into `consume/double-sided/`,
    then all backs (last page first). Paperless merges them into one document.
- **Email**: Mail (left menu) > add your mail account and a rule, e.g. "import
  attachments from emails sent to me+paperless@...".

Accepted: PDF, images, Word/Excel/PowerPoint, LibreOffice, emails (.eml), text.

## Barcode sheets
Print these as QR codes and put them in your scanner stack:

| Code | What it does |
|---|---|
| `PATCHT` | Separator page: splits one scan into several documents |
| `ASN00042` | Archive number 42: write it on the paper folder to find the original |
| `TAG:Bills` | Adds the tag `Bills` |

## Worth setting up in the web page
- **Correspondents, document types, tags**: set a few by hand, then leave
  "Matching: Auto". Paperless learns from you and fills them in for new files.
- **Workflows**: rules like "from bank X: tag Finance, owner Rashed".
- **Saved views**: e.g. "Inbox" on the dashboard.
- **Custom fields**: amount, due date, contract end...
- **Share links**, **notes** and **trash** (kept 30 days) work out of the box.

## Folders
```
~/.local/share/paperless/
  media/documents/originals/   your files, as 2026/My bank/Statement.pdf
  media/documents/archive/     OCR'd PDF versions
  data/                        search index, learned auto-matching
  export/                      latest backup (made by ./homeserver backup)
  database/                    live database: never copy while running
PAPERLESS_CONSUME_DIR/         drop files here
```
Don't move or delete files in `media/` by hand. Delete in the web page.

## Backup to USB
```bash
./homeserver backup paperless --to /media/$USER/<usb-name>
```
Runs Paperless's exporter (all documents + database contents), then copies only
new files. To restore on a fresh install: put the backup in
`~/.local/share/paperless/export/` and run
`podman exec paperless-webserver document_importer /usr/src/paperless/export`.

## Other languages
`PAPERLESS_OCR_LANGUAGE` in `.env` (default `deu+eng`). English, German,
French, Italian and Spanish are built in. Others go in `PAPERLESS_OCR_LANGUAGES`
(e.g. `ben ara`) and add to `PAPERLESS_OCR_LANGUAGE` (e.g. `deu+eng+ben`).

## Opening by name instead of IP
Paperless only accepts the address it was told about. To use e.g.
`http://paperless.lan:8000`, add `Environment=PAPERLESS_ALLOWED_HOSTS=paperless.lan`
and `Environment=PAPERLESS_CSRF_TRUSTED_ORIGINS=http://paperless.lan:8000` to
`paperless-webserver.container.in`, then install again.

## Upgrade
1. Back up to USB.
2. Read the [release notes](https://github.com/paperless-ngx/paperless-ngx/releases).
3. Change `PAPERLESS_VERSION` in `.env`, run `./homeserver install paperless`.

PostgreSQL stays on version 18. A later major version needs a manual upgrade
(export, purge, reinstall, import).

`./homeserver uninstall paperless --purge` DELETES all documents and the database (asks first).
