lttng destroy
lttng create
lttng enable-event -u --tracepoint "mds:req*"
lttng add-context -u -t pthread_id
lttng start
