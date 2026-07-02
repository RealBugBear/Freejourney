package de.reflexjourney.app

import android.Manifest
import android.content.ContentValues
import android.content.pm.PackageManager
import android.provider.CalendarContract
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone

class MainActivity : FlutterActivity() {
    private val calendarChannel = "corejourney/calendar"
    private val timezoneChannel = "corejourney/timezone"
    private val calendarPermissionRequest = 4242
    private var pendingCalendarArgs: Map<String, Any?>? = null
    private var pendingCalendarResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            calendarChannel
        ).setMethodCallHandler { call, result ->
            if (call.method != "createEvent") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            @Suppress("UNCHECKED_CAST")
            val args = call.arguments as? Map<String, Any?>
            if (args == null) {
                result.error(
                    "invalid_arguments",
                    "Kalendertermin konnte nicht vorbereitet werden.",
                    null
                )
                return@setMethodCallHandler
            }

            if (hasCalendarPermission()) {
                createCalendarEvent(args, result)
            } else {
                pendingCalendarArgs = args
                pendingCalendarResult = result
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(
                        Manifest.permission.READ_CALENDAR,
                        Manifest.permission.WRITE_CALENDAR
                    ),
                    calendarPermissionRequest
                )
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            timezoneChannel
        ).setMethodCallHandler { call, result ->
            if (call.method == "getIanaTimezone") {
                result.success(TimeZone.getDefault().id)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode != calendarPermissionRequest) return

        val args = pendingCalendarArgs
        val result = pendingCalendarResult
        pendingCalendarArgs = null
        pendingCalendarResult = null

        if (args == null || result == null) return

        if (hasCalendarPermission()) {
            createCalendarEvent(args, result)
        } else {
            result.error(
                "calendar_permission_denied",
                "Kalenderzugriff wurde nicht erlaubt.",
                null
            )
        }
    }

    private fun hasCalendarPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.READ_CALENDAR
        ) == PackageManager.PERMISSION_GRANTED &&
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.WRITE_CALENDAR
            ) == PackageManager.PERMISSION_GRANTED
    }

    private fun createCalendarEvent(args: Map<String, Any?>, result: MethodChannel.Result) {
        val title = args["title"] as? String
        val startMs = (args["startMs"] as? Number)?.toLong()
        val durationMinutes = (args["durationMinutes"] as? Number)?.toLong()

        if (title == null || startMs == null || durationMinutes == null) {
            result.error(
                "invalid_arguments",
                "Kalendertermin konnte nicht vorbereitet werden.",
                null
            )
            return
        }

        val calendarId = findWritableCalendarId()
        if (calendarId == null) {
            result.error(
                "calendar_unavailable",
                "Es wurde kein beschreibbarer Kalender gefunden.",
                null
            )
            return
        }

        val values = ContentValues().apply {
            put(CalendarContract.Events.CALENDAR_ID, calendarId)
            put(CalendarContract.Events.TITLE, title)
            put(CalendarContract.Events.DTSTART, startMs)
            put(CalendarContract.Events.DTEND, startMs + durationMinutes * 60_000)
            put(CalendarContract.Events.EVENT_TIMEZONE, TimeZone.getDefault().id)

            (args["location"] as? String)
                ?.takeIf { it.isNotBlank() }
                ?.let { put(CalendarContract.Events.EVENT_LOCATION, it) }
            (args["description"] as? String)
                ?.takeIf { it.isNotBlank() }
                ?.let { put(CalendarContract.Events.DESCRIPTION, it) }
        }

        try {
            val uri = contentResolver.insert(CalendarContract.Events.CONTENT_URI, values)
            val eventId = uri?.lastPathSegment
            if (eventId == null) {
                result.error(
                    "calendar_save_failed",
                    "Termin konnte nicht im Kalender gespeichert werden.",
                    null
                )
            } else {
                result.success(eventId)
            }
        } catch (error: Exception) {
            result.error(
                "calendar_save_failed",
                "Termin konnte nicht im Kalender gespeichert werden.",
                error.localizedMessage
            )
        }
    }

    private fun findWritableCalendarId(): Long? {
        val projection = arrayOf(
            CalendarContract.Calendars._ID,
            CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL
        )
        val selection =
            "${CalendarContract.Calendars.VISIBLE} = 1 AND " +
                "${CalendarContract.Calendars.SYNC_EVENTS} = 1"

        contentResolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection,
            selection,
            null,
            null
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndexOrThrow(CalendarContract.Calendars._ID)
            val accessIndex = cursor.getColumnIndexOrThrow(
                CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL
            )

            while (cursor.moveToNext()) {
                val accessLevel = cursor.getInt(accessIndex)
                if (accessLevel >= CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR) {
                    return cursor.getLong(idIndex)
                }
            }
        }

        return null
    }
}
