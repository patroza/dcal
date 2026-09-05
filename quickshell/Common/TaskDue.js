.pragma library
.import "EventUtils.js" as EventUtils

function load(task) {
    const hasDue = !!task.due;
    const hasTime = hasDue && !task.allDay;
    const date = hasDue ? EventUtils.localTime(task.due, !!task.allDay) : new Date();
    return { date: date, hasTime: hasTime,
        minutes: hasTime ? date.getHours() * 60 + date.getMinutes() : 9 * 60 };
}

function serialize(date, hasTime, minutes, original) {
    if (!hasTime)
        return EventUtils.wireTime(date, true);
    const hours = Math.floor(minutes / 60);
    const minute = minutes % 60;
    // Preserve seconds and the original DST-fold instant when only other fields
    // changed. The editor does not offer a seconds or UTC-offset control.
    if (original && original.due && !original.allDay) {
        const previous = new Date(original.due);
        if (previous.getFullYear() === date.getFullYear()
                && previous.getMonth() === date.getMonth()
                && previous.getDate() === date.getDate()
                && previous.getHours() === hours && previous.getMinutes() === minute)
            return previous.toISOString();
    }
    const due = new Date(date.getFullYear(), date.getMonth(), date.getDate(), hours, minute);
    // Reject spring-forward gaps rather than silently moving an alarm by an hour.
    if (minutes < 0 || minutes >= 1440 || due.getFullYear() !== date.getFullYear()
            || due.getMonth() !== date.getMonth() || due.getDate() !== date.getDate()
            || due.getHours() !== hours || due.getMinutes() !== minute)
        throw new Error("Invalid local due time");
    return due.toISOString();
}
