import Flutter
import EventKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let eventStore = EKEventStore()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    registerCalendarChannel()
    registerTimezoneChannel()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func registerTimezoneChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }

    let channel = FlutterMethodChannel(
      name: "corejourney/timezone",
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { call, result in
      guard call.method == "getIanaTimezone" else {
        result(FlutterMethodNotImplemented)
        return
      }

      result(TimeZone.current.identifier)
    }
  }

  private func registerCalendarChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }

    let channel = FlutterMethodChannel(
      name: "corejourney/calendar",
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "createEvent" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard
        let self = self,
        let args = call.arguments as? [String: Any],
        let title = args["title"] as? String,
        let startMs = args["startMs"] as? Double,
        let durationMinutes = args["durationMinutes"] as? Double
      else {
        result(FlutterError(
          code: "invalid_arguments",
          message: "Kalendertermin konnte nicht vorbereitet werden.",
          details: nil
        ))
        return
      }

      let start = Date(timeIntervalSince1970: startMs / 1000.0)
      let end = start.addingTimeInterval(durationMinutes * 60.0)
      let location = args["location"] as? String
      let notes = args["description"] as? String

      self.requestCalendarAccess { granted in
        guard granted else {
          result(FlutterError(
            code: "calendar_permission_denied",
            message: "Kalenderzugriff wurde nicht erlaubt.",
            details: nil
          ))
          return
        }

        guard let calendar = self.eventStore.defaultCalendarForNewEvents else {
          result(FlutterError(
            code: "calendar_unavailable",
            message: "Es wurde kein beschreibbarer Kalender gefunden.",
            details: nil
          ))
          return
        }

        let event = EKEvent(eventStore: self.eventStore)
        event.calendar = calendar
        event.title = title
        event.startDate = start
        event.endDate = end
        if let location = location, !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          event.location = location
        }
        if let notes = notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          event.notes = notes
        }

        do {
          try self.eventStore.save(event, span: .thisEvent)
          result(event.eventIdentifier)
        } catch {
          result(FlutterError(
            code: "calendar_save_failed",
            message: "Termin konnte nicht im Kalender gespeichert werden.",
            details: error.localizedDescription
          ))
        }
      }
    }
  }

  private func requestCalendarAccess(_ completion: @escaping (Bool) -> Void) {
    if #available(iOS 17.0, *) {
      eventStore.requestFullAccessToEvents { granted, _ in
        DispatchQueue.main.async {
          completion(granted)
        }
      }
    } else {
      eventStore.requestAccess(to: .event) { granted, _ in
        DispatchQueue.main.async {
          completion(granted)
        }
      }
    }
  }
}
