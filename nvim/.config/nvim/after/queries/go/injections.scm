(call_expression
  (selector_expression
    operand: (identifier) @operand
    field: (field_identifier) @field (#contains? @field "QueryRow" "Exec" "Query" ))
  (argument_list
    (raw_string_literal) @sql
)
)
