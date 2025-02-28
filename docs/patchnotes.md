# 1.2.1
## New Features
### New Project Setup
- Can import class lists from Canvas or myMSOE.
- Student first/last names are identified (if importing via Canvas, DEXTER needs to guess at which is the first and last name).
- Old DEXTER projects will be updated to the new two-name format.
- You can also edit the class list (change names) at any time via menu item "Edit > Class list ...". You cannot add or remove students (yet).
### Sort Student Names
- Students can now be sorted by first or last name in ascending or descending order. See the "View" menu item.
### Grade Reports
- You can now export one large .txt file with all student's grade reports included. The intention is that you can copy this text into Word and then format the reports (i.e., page breaks, font size, etc.).
### New Settings Panel
- A User Settings panel now holds across-project settings such as font name, font sizes, reporting formats, and keyboard shortcuts.
- Keyboard shortcuts are primitive and should not be changed unless you know all the viable options for MATLAB keyboard shortcuts. There is currently no validation for redefining keys.
- Can also reset these settings back to default from the menubar.
### Help
- A menu item in the About menu "Help" now takes you to Sharepoint viewing the User Guide linked to the DEXTER Teams development page.

# 1.1.0
## New Features
### Redesigned the "File > New Project" UI
- Can now select multiple sections within a class list.
### The "Export" menu is now the "Grade Printouts" menu
- Can generate grade reports for one or more students as .txt files.
- [Experimental] Can generate grade reports for one or more students as .pdf files. There is an unknown bug that causes text scaling issues on some computers.
### Added keyboard shortcuts
- Up/Down Arrow keys change student.
- Left/Right Arrow keys change problem.
- Eventually this will be configurable.
### About Page
- Added a basic "About" menu that contains the version number of DEXTER you are currently running.