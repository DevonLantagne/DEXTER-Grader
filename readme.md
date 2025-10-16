# DEXTER Grader

DEXTER Grader (DEXTER) is a grading calculator and gradebook manager. DEXTER’s main goal is to improve the efficiency and consistency of grading. The secondary goal of DEXTER is to provide insights into student performance. 

This is not a unified gradebook. DEXTER acts on individual assignments/exams; you will need a new DEXTER project per assignment. Projects are initialized using a class list and rubric file. See the User Guide on how to find, create, or format these files.

DEXTER is a "standalone" MATLAB App. To use a standalone MATLAB app, you need the MATLAB Runtime. When you install DEXTER, the runtime will also be installed if it is not already on your computer. DEXTER is currently only supported on Windows OS.

<p align="center">
    <picture>
        <img alt="DEXTER UI" src="docs/images/dexter_ui.png" width="500">
    </picture>
</p>

## Installation

Visit the [Releases](https://github.com/DevonLantagne/DEXTER-Grader/releases) pages for all versions. Scroll to the bottom of a release to Assets and download the installer. This will also install dependencies such as the MATLAB Runtime.

> [!IMPORTANT]
> DEXTER Grader is only supported on Windows OS.

## Documentation

Vist the [documentation page](docs/usage.md) for getting started and exploring DEXTER features.

## Features

### Import Rubrics and Student Lists

- **Rubric Import:** Import a grading rubric in Microsoft Excel format. The rubric should contain grading criteria for each problem in the assignment. See the provided examples.
- **Student List Import:** Import a list of student names, typically from Canvas LMS or any other CSV-compatible source. This will create a list of students for easy navigation and grading.

> [!NOTE]
> Canvas integration coming soon!

### Grading Interface

- **Sequential Grading Scheme:** Navigate through your students as you grade one problem before switching to the next, or grade all problems within one student.
- **One problem is displayed at a time**, with its associated grading criteria. Graders can quickly assess each student's work using the rubric.
- **Grading Criteria:** Your Excel rubric dictates grading criteria and point allotment. Quickly select full or no credit and have the option to enter partial credit. You can also set weights for each problem. Grades are calculated automatically.
- **Grading Scale:** Maps numeric scores to a letter grading scale. Default is the Milwaukee School of Engineering. Can be reconfigured.

### Navigation

- Change problems or students using button controls or via customizable keyboard shortcuts.
- Can sort students based on last or first name.

### Project Mangement

- Each assignment is its own project file that is stored on your computer.
- Includes an optional autosave feature that saves after every changing to a new problem or student.

### Reporting

- Export rubric printouts for each student as `.txt` or `.pdf` files.
> [!NOTE]
> Canvas integration coming soon! Will be able to automatically send grade and report printout as a feedback attachment.
- View insights into student performance with aggregate reports for each problem.
