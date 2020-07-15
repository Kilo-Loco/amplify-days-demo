//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SQLite

/// Support data structure used to hold information about `SelectStatement` than
/// can be used later to parse the results.
struct SelectStatementMetadata {

    typealias ColumnMapping = [String: (ModelSchema, ModelField)]

    let statement: String
    let columnMapping: ColumnMapping
    let bindings: [Binding?]

    // TODO remove additionalStatements once sorting support is added to DataStore
    static func metadata(from modelType: Model.Type,
                         predicate: QueryPredicate? = nil,
                         paginationInput: QueryPaginationInput? = nil,
                         additionalStatements: String? = nil) -> SelectStatementMetadata {
        let rootNamespace = "root"
        let schema = modelType.schema
        let fields = schema.columns
        let tableName = schema.name
        var columnMapping: ColumnMapping = [:]
        var columns = fields.map { field -> String in
            columnMapping.updateValue((schema, field), forKey: field.name)
            return field.columnName(forNamespace: rootNamespace) + " as " + field.columnAlias()
        }

        // eager load many-to-one/one-to-one relationships
        let joinStatements = joins(from: schema)
        columns += joinStatements.columns
        columnMapping.merge(joinStatements.columnMapping) { _, new in new }

        var sql = """
        select
          \(joinedAsSelectedColumns(columns))
        from \(tableName) as "\(rootNamespace)"
        \(joinStatements.statements.joined(separator: "\n"))
        """.trimmingCharacters(in: .whitespacesAndNewlines)

        var bindings: [Binding?] = []
        if let predicate = predicate {
            let conditionStatement = ConditionStatement(modelType: modelType,
                                                        predicate: predicate,
                                                        namespace: rootNamespace[...])
            bindings.append(contentsOf: conditionStatement.variables)
            sql = """
            \(sql)
            where 1 = 1
            \(conditionStatement.stringValue)
            """
        }

        if let additionalStatements = additionalStatements {
            sql = """
            \(sql)
            \(additionalStatements)
            """
        }

        if let paginationInput = paginationInput {
            sql = """
            \(sql)
            \(paginationInput.sqlStatement)
            """
        }
        return SelectStatementMetadata(statement: sql,
                                       columnMapping: columnMapping,
                                       bindings: bindings)
    }

    struct JoinStatement {
        let columns: [String]
        let statements: [String]
        let columnMapping: ColumnMapping
    }

    /// Walk through the associations recursively to generate join statements.
    ///
    /// Implementation note: this should be revisited once we define support
    /// for explicit `eager` vs `lazy` associations.
    private static func joins(from schema: ModelSchema) -> JoinStatement {
        var columns: [String] = []
        var joinStatements: [String] = []
        var columnMapping: ColumnMapping = [:]

        func visitAssociations(node: ModelSchema, namespace: String = "root") {
            for foreignKey in node.foreignKeys {
                let associatedModelType = foreignKey.requiredAssociatedModel
                let associatedSchema = associatedModelType.schema
                let associatedTableName = associatedModelType.schema.name

                // columns
                let alias = namespace == "root" ? foreignKey.name : "\(namespace).\(foreignKey.name)"
                let associatedColumn = associatedSchema.primaryKey.columnName(forNamespace: alias)
                let foreignKeyName = foreignKey.columnName(forNamespace: namespace)

                // append columns from relationships
                columns += associatedSchema.columns.map { field -> String in
                    columnMapping.updateValue((associatedSchema, field), forKey: "\(alias).\(field.name)")
                    return field.columnName(forNamespace: alias) + " as " + field.columnAlias(forNamespace: alias)
                }

                let joinType = foreignKey.isRequired ? "inner" : "left outer"

                joinStatements.append("""
                \(joinType) join \(associatedTableName) as "\(alias)"
                  on \(associatedColumn) = \(foreignKeyName)
                """)
                visitAssociations(node: associatedModelType.schema,
                                  namespace: alias)
            }
        }
        visitAssociations(node: schema)

        return JoinStatement(columns: columns,
                             statements: joinStatements,
                             columnMapping: columnMapping)
    }

}

/// Represents a `select` SQL statement associated with a `Model` instance and
/// optionally composed by a `ConditionStatement`.
struct SelectStatement: SQLStatement {

    let modelType: Model.Type
    let metadata: SelectStatementMetadata

    init(from modelType: Model.Type,
         predicate: QueryPredicate? = nil,
         paginationInput: QueryPaginationInput? = nil,
         additionalStatements: String? = nil) {
        self.modelType = modelType
        self.metadata = .metadata(from: modelType,
                                  predicate: predicate,
                                  paginationInput: paginationInput,
                                  additionalStatements: additionalStatements)
    }

    var stringValue: String {
        metadata.statement
    }

    var variables: [Binding?] {
        metadata.bindings
    }

}

// MARK: - Helpers

/// Join a list of table columns joined and formatted for readability.
///
/// - Parameter columns the list of column names
/// - Parameter perLine max numbers of columns per line
/// - Returns: a list of columns that can be used in `select` SQL statements
internal func joinedAsSelectedColumns(_ columns: [String], perLine: Int = 3) -> String {
    return columns.enumerated().reduce("") { partial, entry in
        let spacer = entry.offset == 0 || entry.offset % perLine == 0 ? "\n  " : " "
        let isFirstOrLast = entry.offset == 0 || entry.offset >= columns.count
        let separator = isFirstOrLast ? "" : ",\(spacer)"
        return partial + separator + entry.element
    }
}
