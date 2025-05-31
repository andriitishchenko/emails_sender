
# EmailSenderApp

EmailSenderApp is a macOS application for sending bulk personalized email messages with support for templates and CSV recipient files.

## Features

* **Import recipients from a CSV file**: The CSV file must have an `email` column.
* **Template support**: Use templates for subject and body with parameters substituted from the CSV.
* **Markdown editor**: A Markdown editor for the email body with a preview.
* **Send logs**: View and clear sending logs.
* **Asynchronous sending**: Emails are sent asynchronously via AppleScript (Mail.app) with a queue and cancelation option.
* **UI indication**: UI indications of the sending process (icon change, progress bar).
* **Drag & Drop**: Drag and drop CSV file loading.
* **Multiple drafts**: Support for multiple mailing drafts.

---

## How It Works

1.  **Create a new mailing draft**: Click the `+` button.
2.  **Fill in the subject and body**: Use placeholders like `{{name}}`, `{{company}}`, etc.
3.  **Drag and drop your CSV file**: The first row should contain headers, and an `email` column is mandatory.
4.  **Click "Send"**: Emails will be sent sequentially via Mail.app. You can cancel the process at any time.
5.  **View logs**: Sending status for each recipient is displayed in the logs.

---

## Requirements

* macOS 13+
* Mail.app (the standard application)
* Automation permission (AppleScript)

---

## Security

* The application does not store passwords or use third-party SMTP services.
* All actions are performed locally via Mail.app.

---

## Running and Building

1.  Open the project in Xcode.
2.  Build and run EmailSenderApp.
3.  Upon the first launch, grant permission to control Mail.app (AppleScript).

---

## CSV Example

```csv
name,email,company
Ivan,ivan@example.com,Romashka LLC
Maria,maria@example.com,Vasilek LLC
```

---

## License

MIT License