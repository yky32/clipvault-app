import Flutter
import CloudKit
import Foundation

/// Phase E — CloudKit private-database bridge for ClipVal vault sync.
///
/// Uses a **custom record zone** (`ClipValVault`) and zone-change fetch so we
/// never need CKQuery / queryable field indexes (which fail on a fresh
/// Development schema).
///
/// Records carry **already-encrypted** values. Only the user’s private iCloud
/// is used — ClipVal has no server.
///
/// Container: iCloud.com.clipval
/// Record types: ClipItem, Category, VaultMeta
final class CloudKitSyncChannel {
  static let channelName = "com.clipval/icloud_sync"
  static let containerId = "iCloud.com.clipval"
  static let zoneName = "ClipValVault"

  private let container = CKContainer(identifier: CloudKitSyncChannel.containerId)
  private var database: CKDatabase { container.privateCloudDatabase }

  private var zoneID: CKRecordZone.ID {
    CKRecordZone.ID(zoneName: Self.zoneName, ownerName: CKCurrentUserDefaultName)
  }

  func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "gone", message: "Channel deallocated", details: nil))
        return
      }
      self.handle(call, result: result)
    }
  }


  /// Map CloudKit failures to stable FlutterError codes for Dart UX.
  private static func flutterError(from error: Error, fallbackCode: String) -> FlutterError {
    let msg = error.localizedDescription
    let lower = msg.lowercased()
    // Production schema missing a record type (CLIPVAL-CK-001).
    if lower.contains("cannot create new type")
      || lower.contains("production schema")
      || (lower.contains("record type") && lower.contains("production"))
    {
      return FlutterError(
        code: "schema_production",
        message: msg,
        details: ["reason": "production_schema_missing_type"]
      )
    }
    if lower.contains("not authenticated") || lower.contains("no account") {
      return FlutterError(code: "no_account", message: msg, details: nil)
    }
    if lower.contains("network") || lower.contains("offline") || lower.contains("timed out") {
      return FlutterError(code: "network", message: msg, details: nil)
    }
    return FlutterError(code: fallbackCode, message: msg, details: nil)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "engineInfo":
      // Lets Dart confirm the zone-based native binary is installed
      // (hot restart does NOT update Swift — full reinstall required).
      result([
        "engine": "zone-v1",
        "zone": Self.zoneName,
        "container": Self.containerId,
      ])

    case "isAvailable":
      container.accountStatus { status, error in
        if let error {
          result([
            "available": false,
            "status": "error",
            "message": error.localizedDescription,
          ])
          return
        }
        let available = status == .available
        let statusName: String
        switch status {
        case .available: statusName = "available"
        case .noAccount: statusName = "noAccount"
        case .restricted: statusName = "restricted"
        case .couldNotDetermine: statusName = "couldNotDetermine"
        case .temporarilyUnavailable: statusName = "temporarilyUnavailable"
        @unknown default: statusName = "unknown"
        }
        result([
          "available": available,
          "status": statusName,
        ])
      }

    case "fetchAll":
      Task {
        do {
          let payload = try await self.fetchAllRecords()
          DispatchQueue.main.async { result(payload) }
        } catch {
          NSLog("[ClipVal iCloud] FETCH FAIL: %@", error.localizedDescription)
          DispatchQueue.main.async {
            result(Self.flutterError(from: error, fallbackCode: "fetch"))
          }
        }
      }

    case "upsertRecords":
      guard let args = call.arguments as? [String: Any],
            let items = args["items"] as? [[String: Any]],
            let categories = args["categories"] as? [[String: Any]]
      else {
        result(FlutterError(code: "args", message: "items/categories required", details: nil))
        return
      }
      let meta = args["meta"] as? [String: Any]
      Task {
        do {
          try await self.upsert(items: items, categories: categories, meta: meta)
          DispatchQueue.main.async { result(["ok": true]) }
        } catch {
          NSLog("[ClipVal iCloud] UPSERT FAIL: %@", error.localizedDescription)
          DispatchQueue.main.async {
            result(Self.flutterError(from: error, fallbackCode: "upsert"))
          }
        }
      }

    case "deleteRecords":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "args", message: "map required", details: nil))
        return
      }
      let itemIds = args["itemIds"] as? [String] ?? []
      let categoryIds = args["categoryIds"] as? [String] ?? []
      Task {
        do {
          try await self.deleteRecords(itemIds: itemIds, categoryIds: categoryIds)
          DispatchQueue.main.async { result(["ok": true]) }
        } catch {
          NSLog("[ClipVal iCloud] DELETE FAIL: %@", error.localizedDescription)
          DispatchQueue.main.async {
            result(Self.flutterError(from: error, fallbackCode: "delete"))
          }
        }
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Zone

  /// Create custom zone if needed (idempotent).
  private func ensureZone() async throws {
    let zone = CKRecordZone(zoneID: zoneID)
    do {
      _ = try await database.modifyRecordZones(saving: [zone], deleting: [])
    } catch let error as CKError {
      // Already exists / partial success with existing zone → OK
      if error.code == .serverRecordChanged || error.code == .partialFailure {
        return
      }
      // Some OS versions surface zoneAlreadyExists via partialFailure userInfo
      let text = error.localizedDescription.lowercased()
      if text.contains("already exists") || text.contains("server record changed") {
        return
      }
      throw error
    }
  }

  private func makeRecordID(_ name: String) -> CKRecord.ID {
    CKRecord.ID(recordName: name, zoneID: zoneID)
  }

  // MARK: - Fetch (zone changes — no CKQuery / no queryable indexes)

  private func fetchAllRecords() async throws -> [String: Any] {
    try await ensureZone()
    let all = try await fetchAllInZone()

    var items: [[String: Any]] = []
    var categories: [[String: Any]] = []
    var meta: [String: Any]?

    for record in all {
      switch record.recordType {
      case "ClipItem":
        items.append(recordToMap(record))
      case "Category":
        categories.append(recordToMap(record))
      case "VaultMeta":
        meta = recordToMap(record)
      default:
        break
      }
    }

    return [
      "items": items,
      "categories": categories,
      "meta": meta as Any,
    ]
  }

  /// Full dump of the custom zone (nil change token).
  private func fetchAllInZone() async throws -> [CKRecord] {
    try await withCheckedThrowingContinuation { continuation in
      var collected: [CKRecord] = []
      var resumed = false
      let resumeOnce: (Result<[CKRecord], Error>) -> Void = { result in
        guard !resumed else { return }
        resumed = true
        continuation.resume(with: result)
      }

      let config = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
      // previousServerChangeToken = nil → fetch entire zone from scratch

      let op = CKFetchRecordZoneChangesOperation(
        recordZoneIDs: [zoneID],
        configurationsByRecordZoneID: [zoneID: config]
      )
      op.recordWasChangedBlock = { _, result in
        if case .success(let record) = result {
          collected.append(record)
        }
      }
      op.recordWithIDWasDeletedBlock = { _, _ in
        // Full dump callers rebuild from current state; deletes applied client-side via tombstones.
      }
      op.recordZoneFetchResultBlock = { _, result in
        if case .failure(let error) = result {
          // Zone empty / missing — treat as empty vault, not fatal.
          if let ck = error as? CKError,
             ck.code == .zoneNotFound || ck.code == .userDeletedZone {
            return
          }
          let text = error.localizedDescription.lowercased()
          if text.contains("zone") && text.contains("not found") {
            return
          }
          // Don't fail the whole op yet — wait for final block; log only.
          NSLog("[ClipVal] zone fetch partial: \(error.localizedDescription)")
        }
      }
      op.fetchRecordZoneChangesResultBlock = { result in
        switch result {
        case .success:
          resumeOnce(.success(collected))
        case .failure(let error):
          if let ck = error as? CKError,
             ck.code == .zoneNotFound || ck.code == .userDeletedZone {
            resumeOnce(.success([]))
            return
          }
          let text = error.localizedDescription.lowercased()
          if text.contains("zone") && (text.contains("not found") || text.contains("deleted")) {
            resumeOnce(.success([]))
            return
          }
          resumeOnce(.failure(error))
        }
      }
      database.add(op)
    }
  }

  // MARK: - Upsert

  private func upsert(
    items: [[String: Any]],
    categories: [[String: Any]],
    meta: [String: Any]?
  ) async throws {
    try await ensureZone()
    var records: [CKRecord] = []

    for map in items {
      guard let id = map["id"] as? String, !id.isEmpty else { continue }
      let record = CKRecord(
        recordType: "ClipItem",
        recordID: makeRecordID("item_\(id)")
      )
      apply(map: map, to: record)
      records.append(record)
    }

    for map in categories {
      guard let id = map["id"] as? String, !id.isEmpty else { continue }
      let record = CKRecord(
        recordType: "Category",
        recordID: makeRecordID("cat_\(id)")
      )
      apply(map: map, to: record)
      records.append(record)
    }

    if let meta {
      let record = CKRecord(
        recordType: "VaultMeta",
        recordID: makeRecordID("vault_meta")
      )
      apply(map: meta, to: record)
      records.append(record)
    }

    guard !records.isEmpty else { return }

    let chunkSize = 200
    var index = 0
    while index < records.count {
      let end = min(index + chunkSize, records.count)
      let chunk = Array(records[index..<end])
      let result = try await database.modifyRecords(
        saving: chunk,
        deleting: [],
        savePolicy: .allKeys,
        atomically: false
      )
      for (_, saveResult) in result.saveResults {
        if case .failure(let error) = saveResult {
          throw error
        }
      }
      index = end
    }
  }

  private func deleteRecords(itemIds: [String], categoryIds: [String]) async throws {
    try await ensureZone()
    var ids: [CKRecord.ID] = []
    ids.append(contentsOf: itemIds.map { makeRecordID("item_\($0)") })
    ids.append(contentsOf: categoryIds.map { makeRecordID("cat_\($0)") })
    guard !ids.isEmpty else { return }

    let chunkSize = 200
    var index = 0
    while index < ids.count {
      let end = min(index + chunkSize, ids.count)
      let chunk = Array(ids[index..<end])
      _ = try await database.modifyRecords(
        saving: [],
        deleting: chunk,
        savePolicy: .allKeys,
        atomically: false
      )
      index = end
    }
  }

  // MARK: - Map helpers

  private func apply(map: [String: Any], to record: CKRecord) {
    for (key, value) in map {
      if key == "id" { continue }
      switch value {
      case let s as String:
        record[key] = s as CKRecordValue
      case let i as Int:
        record[key] = i as CKRecordValue
      case let b as Bool:
        record[key] = (b ? 1 : 0) as CKRecordValue
      case let d as Double:
        record[key] = d as CKRecordValue
      case let n as NSNumber:
        record[key] = n
      default:
        if let s = value as? NSString {
          record[key] = s
        }
      }
    }
  }

  private func recordToMap(_ record: CKRecord) -> [String: Any] {
    var map: [String: Any] = [:]
    let name = record.recordID.recordName
    if name.hasPrefix("item_") {
      map["id"] = String(name.dropFirst(5))
    } else if name.hasPrefix("cat_") {
      map["id"] = String(name.dropFirst(4))
    } else if name == "vault_meta" {
      map["id"] = "vault_meta"
    } else {
      map["id"] = name
    }
    for key in record.allKeys() {
      guard let value = record[key] else { continue }
      if let s = value as? String {
        map[key] = s
      } else if let n = value as? NSNumber {
        map[key] = n
      } else if let d = value as? Date {
        map[key] = ISO8601DateFormatter().string(from: d)
      }
    }
    return map
  }
}
