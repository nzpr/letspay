#!/bin/bash
sed 's/\%address\%/'$2'/g;s/\%log_marker\%/'$3'/g' rho_templates/get_balance.rho  > tmp/get_balance.rho
rnode --grpc-host $1 deploy --private-key bd2946a79be97625b86c09510a48aa037905c408a73fc672f19068dc58c550ee --phlo-limit 10000000000000 --phlo-price 1 tmp/get_balance.rho
#rnode --grpc-host $validator propose