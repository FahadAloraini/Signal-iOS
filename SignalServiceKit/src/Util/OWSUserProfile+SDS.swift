//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation
import GRDBCipher
import SignalCoreKit

// NOTE: This file is generated by /Scripts/sds_codegen/sds_generate.py.
// Do not manually edit it, instead run `sds_codegen.sh`.

// MARK: - Record

public struct UserProfileRecord: SDSRecord {
    public var tableMetadata: SDSTableMetadata {
        return OWSUserProfileSerializer.table
    }

    public static let databaseTableName: String = OWSUserProfileSerializer.table.tableName

    public var id: Int64?

    // This defines all of the columns used in the table
    // where this model (and any subclasses) are persisted.
    public let recordType: SDSRecordType
    public let uniqueId: String

    // Base class properties
    public let avatarFileName: String?
    public let avatarUrlPath: String?
    public let profileKey: Data?
    public let profileName: String?
    public let recipientId: String

    public enum CodingKeys: String, CodingKey, ColumnExpression, CaseIterable {
        case id
        case recordType
        case uniqueId
        case avatarFileName
        case avatarUrlPath
        case profileKey
        case profileName
        case recipientId
    }

    public static func columnName(_ column: UserProfileRecord.CodingKeys, fullyQualified: Bool = false) -> String {
        return fullyQualified ? "\(databaseTableName).\(column.rawValue)" : column.rawValue
    }
}

// MARK: - StringInterpolation

public extension String.StringInterpolation {
    mutating func appendInterpolation(userProfileColumn column: UserProfileRecord.CodingKeys) {
        appendLiteral(UserProfileRecord.columnName(column))
    }
    mutating func appendInterpolation(userProfileColumnFullyQualified column: UserProfileRecord.CodingKeys) {
        appendLiteral(UserProfileRecord.columnName(column, fullyQualified: true))
    }
}

// MARK: - Deserialization

// TODO: Rework metadata to not include, for example, columns, column indices.
extension OWSUserProfile {
    // This method defines how to deserialize a model, given a
    // database row.  The recordType column is used to determine
    // the corresponding model class.
    class func fromRecord(_ record: UserProfileRecord) throws -> OWSUserProfile {

        guard let recordId = record.id else {
            throw SDSError.invalidValue
        }

        switch record.recordType {
        case .userProfile:

            let uniqueId: String = record.uniqueId
            let avatarFileName: String? = record.avatarFileName
            let avatarUrlPath: String? = record.avatarUrlPath
            let profileKeySerialized: Data? = record.profileKey
            let profileKey: OWSAES256Key? = try SDSDeserialization.optionalUnarchive(profileKeySerialized, name: "profileKey")
            let profileName: String? = record.profileName
            let recipientId: String = record.recipientId

            return OWSUserProfile(uniqueId: uniqueId,
                                  avatarFileName: avatarFileName,
                                  avatarUrlPath: avatarUrlPath,
                                  profileKey: profileKey,
                                  profileName: profileName,
                                  recipientId: recipientId)

        default:
            owsFailDebug("Unexpected record type: \(record.recordType)")
            throw SDSError.invalidValue
        }
    }
}

// MARK: - SDSModel

extension OWSUserProfile: SDSModel {
    public var serializer: SDSSerializer {
        // Any subclass can be cast to it's superclass,
        // so the order of this switch statement matters.
        // We need to do a "depth first" search by type.
        switch self {
        default:
            return OWSUserProfileSerializer(model: self)
        }
    }

    public func asRecord() throws -> SDSRecord {
        return try serializer.asRecord()
    }
}

// MARK: - Table Metadata

extension OWSUserProfileSerializer {

    // This defines all of the columns used in the table
    // where this model (and any subclasses) are persisted.
    static let recordTypeColumn = SDSColumnMetadata(columnName: "recordType", columnType: .int, columnIndex: 0)
    static let idColumn = SDSColumnMetadata(columnName: "id", columnType: .primaryKey, columnIndex: 1)
    static let uniqueIdColumn = SDSColumnMetadata(columnName: "uniqueId", columnType: .unicodeString, columnIndex: 2)
    // Base class properties
    static let avatarFileNameColumn = SDSColumnMetadata(columnName: "avatarFileName", columnType: .unicodeString, isOptional: true, columnIndex: 3)
    static let avatarUrlPathColumn = SDSColumnMetadata(columnName: "avatarUrlPath", columnType: .unicodeString, isOptional: true, columnIndex: 4)
    static let profileKeyColumn = SDSColumnMetadata(columnName: "profileKey", columnType: .blob, isOptional: true, columnIndex: 5)
    static let profileNameColumn = SDSColumnMetadata(columnName: "profileName", columnType: .unicodeString, isOptional: true, columnIndex: 6)
    static let recipientIdColumn = SDSColumnMetadata(columnName: "recipientId", columnType: .unicodeString, columnIndex: 7)

    // TODO: We should decide on a naming convention for
    //       tables that store models.
    public static let table = SDSTableMetadata(tableName: "model_OWSUserProfile", columns: [
        recordTypeColumn,
        idColumn,
        uniqueIdColumn,
        avatarFileNameColumn,
        avatarUrlPathColumn,
        profileKeyColumn,
        profileNameColumn,
        recipientIdColumn
        ])
}

// MARK: - Save/Remove/Update

@objc
public extension OWSUserProfile {
    func anyInsert(transaction: SDSAnyWriteTransaction) {
        sdsSave(saveMode: .insert, transaction: transaction)
    }

    // This method is private; we should never use it directly.
    // Instead, use anyUpdate(transaction:block:), so that we
    // use the "update with" pattern.
    private func anyUpdate(transaction: SDSAnyWriteTransaction) {
        sdsSave(saveMode: .update, transaction: transaction)
    }

    @available(*, deprecated, message: "Use anyInsert() or anyUpdate() instead.")
    func anyUpsert(transaction: SDSAnyWriteTransaction) {
        sdsSave(saveMode: .upsert, transaction: transaction)
    }

    // This method is used by "updateWith..." methods.
    //
    // This model may be updated from many threads. We don't want to save
    // our local copy (this instance) since it may be out of date.  We also
    // want to avoid re-saving a model that has been deleted.  Therefore, we
    // use "updateWith..." methods to:
    //
    // a) Update a property of this instance.
    // b) If a copy of this model exists in the database, load an up-to-date copy,
    //    and update and save that copy.
    // b) If a copy of this model _DOES NOT_ exist in the database, do _NOT_ save
    //    this local instance.
    //
    // After "updateWith...":
    //
    // a) Any copy of this model in the database will have been updated.
    // b) The local property on this instance will always have been updated.
    // c) Other properties on this instance may be out of date.
    //
    // All mutable properties of this class have been made read-only to
    // prevent accidentally modifying them directly.
    //
    // This isn't a perfect arrangement, but in practice this will prevent
    // data loss and will resolve all known issues.
    func anyUpdate(transaction: SDSAnyWriteTransaction, block: (OWSUserProfile) -> Void) {
        guard let uniqueId = uniqueId else {
            owsFailDebug("Missing uniqueId.")
            return
        }

        block(self)

        guard let dbCopy = type(of: self).anyFetch(uniqueId: uniqueId,
                                                   transaction: transaction) else {
            return
        }

        // Don't apply the block twice to the same instance.
        // It's at least unnecessary and actually wrong for some blocks.
        // e.g. `block: { $0 in $0.someField++ }`
        if dbCopy !== self {
            block(dbCopy)
        }

        dbCopy.anyUpdate(transaction: transaction)
    }

    func anyRemove(transaction: SDSAnyWriteTransaction) {
        switch transaction.writeTransaction {
        case .yapWrite(let ydbTransaction):
            remove(with: ydbTransaction)
        case .grdbWrite(let grdbTransaction):
            do {
                let record = try asRecord()
                record.sdsRemove(transaction: grdbTransaction)
            } catch {
                owsFail("Remove failed: \(error)")
            }
        }
    }

    func anyReload(transaction: SDSAnyReadTransaction) {
        anyReload(transaction: transaction, ignoreMissing: false)
    }

    func anyReload(transaction: SDSAnyReadTransaction, ignoreMissing: Bool) {
        guard let uniqueId = self.uniqueId else {
            owsFailDebug("uniqueId was unexpectedly nil")
            return
        }

        guard let latestVersion = type(of: self).anyFetch(uniqueId: uniqueId, transaction: transaction) else {
            if !ignoreMissing {
                owsFailDebug("`latest` was unexpectedly nil")
            }
            return
        }

        setValuesForKeys(latestVersion.dictionaryValue)
    }
}

// MARK: - OWSUserProfileCursor

@objc
public class OWSUserProfileCursor: NSObject {
    private let cursor: RecordCursor<UserProfileRecord>?

    init(cursor: RecordCursor<UserProfileRecord>?) {
        self.cursor = cursor
    }

    public func next() throws -> OWSUserProfile? {
        guard let cursor = cursor else {
            return nil
        }
        guard let record = try cursor.next() else {
            return nil
        }
        return try OWSUserProfile.fromRecord(record)
    }

    public func all() throws -> [OWSUserProfile] {
        var result = [OWSUserProfile]()
        while true {
            guard let model = try next() else {
                break
            }
            result.append(model)
        }
        return result
    }
}

// MARK: - Obj-C Fetch

// TODO: We may eventually want to define some combination of:
//
// * fetchCursor, fetchOne, fetchAll, etc. (ala GRDB)
// * Optional "where clause" parameters for filtering.
// * Async flavors with completions.
//
// TODO: I've defined flavors that take a read transaction.
//       Or we might take a "connection" if we end up having that class.
@objc
public extension OWSUserProfile {
    class func grdbFetchCursor(transaction: GRDBReadTransaction) -> OWSUserProfileCursor {
        let database = transaction.database
        do {
            let cursor = try UserProfileRecord.fetchCursor(database)
            return OWSUserProfileCursor(cursor: cursor)
        } catch {
            owsFailDebug("Read failed: \(error)")
            return OWSUserProfileCursor(cursor: nil)
        }
    }

    // Fetches a single model by "unique id".
    class func anyFetch(uniqueId: String,
                        transaction: SDSAnyReadTransaction) -> OWSUserProfile? {
        assert(uniqueId.count > 0)

        switch transaction.readTransaction {
        case .yapRead(let ydbTransaction):
            return OWSUserProfile.fetch(uniqueId: uniqueId, transaction: ydbTransaction)
        case .grdbRead(let grdbTransaction):
            let sql = "SELECT * FROM \(UserProfileRecord.databaseTableName) WHERE \(userProfileColumn: .uniqueId) = ?"
            return grdbFetchOne(sql: sql, arguments: [uniqueId], transaction: grdbTransaction)
        }
    }

    // Traverses all records.
    // Records are not visited in any particular order.
    // Traversal aborts if the visitor returns false.
    class func anyVisitAll(transaction: SDSAnyReadTransaction, visitor: @escaping (OWSUserProfile) -> Bool) {
        switch transaction.readTransaction {
        case .yapRead(let ydbTransaction):
            OWSUserProfile.enumerateCollectionObjects(with: ydbTransaction) { (object, stop) in
                guard let value = object as? OWSUserProfile else {
                    owsFailDebug("unexpected object: \(type(of: object))")
                    return
                }
                guard visitor(value) else {
                    stop.pointee = true
                    return
                }
            }
        case .grdbRead(let grdbTransaction):
            do {
                let cursor = OWSUserProfile.grdbFetchCursor(transaction: grdbTransaction)
                while let value = try cursor.next() {
                    guard visitor(value) else {
                        return
                    }
                }
            } catch let error as NSError {
                owsFailDebug("Couldn't fetch models: \(error)")
            }
        }
    }

    // Does not order the results.
    class func anyFetchAll(transaction: SDSAnyReadTransaction) -> [OWSUserProfile] {
        var result = [OWSUserProfile]()
        anyVisitAll(transaction: transaction) { (model) in
            result.append(model)
            return true
        }
        return result
    }

    class func anyCount(transaction: SDSAnyReadTransaction) -> UInt {
        switch transaction.readTransaction {
        case .yapRead(let ydbTransaction):
            return ydbTransaction.numberOfKeys(inCollection: OWSUserProfile.collection())
        case .grdbRead(let grdbTransaction):
            let sql = "SELECT COUNT(*) FROM \(UserProfileRecord.databaseTableName)"
            return try! UInt.fetchOne(grdbTransaction.database, sql: sql) ?? 0
        }
    }
}

// MARK: - Swift Fetch

public extension OWSUserProfile {
    class func grdbFetchCursor(sql: String,
                               arguments: [DatabaseValueConvertible]?,
                               transaction: GRDBReadTransaction) -> OWSUserProfileCursor {
        var statementArguments: StatementArguments?
        if let arguments = arguments {
            guard let statementArgs = StatementArguments(arguments) else {
                owsFailDebug("Could not convert arguments.")
                return OWSUserProfileCursor(cursor: nil)
            }
            statementArguments = statementArgs
        }
        let database = transaction.database
        do {
            let statement: SelectStatement = try database.cachedSelectStatement(sql: sql)
            let cursor = try UserProfileRecord.fetchCursor(statement, arguments: statementArguments)
            return OWSUserProfileCursor(cursor: cursor)
        } catch {
            Logger.error("sql: \(sql)")
            owsFailDebug("Read failed: \(error)")
            return OWSUserProfileCursor(cursor: nil)
        }
    }

    class func grdbFetchOne(sql: String,
                            arguments: StatementArguments,
                            transaction: GRDBReadTransaction) -> OWSUserProfile? {
        assert(sql.count > 0)

        do {
            guard let record = try UserProfileRecord.fetchOne(transaction.database, sql: sql, arguments: arguments) else {
                return nil
            }

            return try OWSUserProfile.fromRecord(record)
        } catch {
            owsFailDebug("error: \(error)")
            return nil
        }
    }
}

// MARK: - SDSSerializer

// The SDSSerializer protocol specifies how to insert and update the
// row that corresponds to this model.
class OWSUserProfileSerializer: SDSSerializer {

    private let model: OWSUserProfile
    public required init(model: OWSUserProfile) {
        self.model = model
    }

    // MARK: - Record

    func asRecord() throws -> SDSRecord {
        let id: Int64? = nil

        let recordType: SDSRecordType = .userProfile
        guard let uniqueId: String = model.uniqueId else {
            owsFailDebug("Missing uniqueId.")
            throw SDSError.missingRequiredField
        }

        // Base class properties
        let avatarFileName: String? = model.avatarFileName
        let avatarUrlPath: String? = model.avatarUrlPath
        let profileKey: Data? = optionalArchive(model.profileKey)
        let profileName: String? = model.profileName
        let recipientId: String = model.recipientId

        return UserProfileRecord(id: id, recordType: recordType, uniqueId: uniqueId, avatarFileName: avatarFileName, avatarUrlPath: avatarUrlPath, profileKey: profileKey, profileName: profileName, recipientId: recipientId)
    }
}
