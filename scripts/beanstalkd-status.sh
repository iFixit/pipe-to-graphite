#!/bin/sh
#
# Transform beanstalk status info:
#     WorkerFunctionName 10 3 2
#
# Into this:
#     job-server.WorkerFunctionName.queued 10
#     job-server.WorkerFunctionName.running 3
#     job-server.WorkerFunctionName.workers 2
/home/ifixit/Code/Exec/job-status | 
tail -n +3 |
sed -e "s/::/_/" -e "s/^/job-server./" |
awk '{print $1 ".queued",$2;
      print $1 ".running",$3;
      print $1 ".workers",$4}'
