(expression_list
  (raw_string_literal) @sql 
    (#match? @sql "(SELECT|UPDATE|INSERT|DELETE|CREATE|ALTER|DROP|WITH)" )
    (#not-match? @sql "%" )
)
