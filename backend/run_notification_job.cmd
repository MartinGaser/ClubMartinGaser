@echo off
cd /d C:\Users\marti\Documents\ClubMartinGaser\backend
C:\Users\marti\Documents\ClubMartinGaser\backend\.venv\Scripts\python.exe -m app.jobs.send_reservation_reminders >> C:\Users\marti\Documents\ClubMartinGaser\backend\notification_job.log 2>&1
