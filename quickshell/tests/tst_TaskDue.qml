import QtQuick
import QtTest
import "../Common/TaskDue.js" as TaskDue

TestCase {
    name: "TaskDue"

    function test_loadTimedMinutePrecision() {
        const due = new Date(2026, 8, 5, 17, 22).toISOString();
        const form = TaskDue.load({due: due, allDay: false});
        verify(form.hasTime);
        compare(form.minutes, 17 * 60 + 22);
        compare(form.date.getDate(), 5);
    }

    function test_allDayKeepsLiteralDateInEveryTimezone() {
        const task = {due: "2026-09-05T00:00:00.000Z", allDay: true};
        const form = TaskDue.load(task);
        verify(!form.hasTime);
        compare(form.date.getDate(), 5);
        compare(TaskDue.serialize(form.date, false, 540, task), task.due);
    }

    function test_metadataOnlyEditPreservesSeconds() {
        const task = {due: new Date(2026, 8, 5, 17, 22, 37).toISOString(), allDay: false};
        const form = TaskDue.load(task);
        compare(TaskDue.serialize(form.date, true, form.minutes, task), task.due);
    }

    function test_changeTimeAndDateSeparately() {
        const task = {due: new Date(2026, 8, 5, 17, 22).toISOString(), allDay: false};
        const form = TaskDue.load(task);
        const changedTime = new Date(TaskDue.serialize(form.date, true, 10 * 60 + 7, task));
        compare(changedTime.getDate(), 5);
        compare(changedTime.getHours(), 10);
        compare(changedTime.getMinutes(), 7);
        const changedDate = new Date(TaskDue.serialize(new Date(2026, 8, 6), true, form.minutes, task));
        compare(changedDate.getDate(), 6);
        compare(changedDate.getHours(), 17);
        compare(changedDate.getMinutes(), 22);
    }

    function test_midnightIsTimed() {
        const task = {due: new Date(2026, 8, 5, 0, 0).toISOString(), allDay: false};
        const form = TaskDue.load(task);
        verify(form.hasTime);
        compare(form.minutes, 0);
        compare(TaskDue.serialize(form.date, true, 0, task), task.due);
    }

    function test_switchBetweenDateOnlyAndTimed() {
        const task = {due: "2026-09-05T00:00:00.000Z", allDay: true};
        const form = TaskDue.load(task);
        const timed = TaskDue.serialize(form.date, true, 17 * 60 + 22, task);
        compare(new Date(timed).getHours(), 17);
        compare(TaskDue.serialize(form.date, false, form.minutes, task), task.due);
        verify(!TaskDue.load({}).hasTime);
    }

    function test_dstChangesPreserveClock() {
        if (new Date(2026, 2, 28, 9).getTimezoneOffset() !== -60
                || new Date(2026, 2, 29, 9).getTimezoneOffset() !== -120)
            skip("Berlin DST test");
        const task = {due: "2026-03-28T08:15:00Z", allDay: false};
        compare(TaskDue.serialize(new Date(2026, 2, 29), true, 555, task), "2026-03-29T07:15:00.000Z");
        let rejected = false;
        try {
            TaskDue.serialize(new Date(2026, 2, 29), true, 150, task);
        } catch (error) {
            rejected = true;
        }
        verify(rejected);
        const fold = {due: "2026-10-25T01:30:37Z", allDay: false};
        compare(TaskDue.serialize(TaskDue.load(fold).date, true, 150, fold), "2026-10-25T01:30:37.000Z");
    }
}
