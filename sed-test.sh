#!/bin/bash

sed -n -e '/Summary run status/,/Has app-specific actions/ p' test.log |
sed 's/ \{2,\}/\t/g' |
awk -F'\t' 'BEGIN{OFS="\t"} {printf "%-41s %-30s\n", $1, $2}'
