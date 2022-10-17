import sys
import sqlparse

contents = sys.stdin.read()
for identifier in range(10):
    contents = contents.replace(f"?{identifier}",f"__id_{identifier}")

result = sqlparse.format(contents
                         , indent_columns=True
                         , keyword_case='upper'
                         , reindent=True
                         , output_format='sql'
                         , indent_after_first=True
                         , wrap_after=80
                         )

for identifier in range(10):
    result = result.replace(f"__id_{identifier}",f"?{identifier}")

print(result.strip())
