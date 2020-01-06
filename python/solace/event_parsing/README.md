To run the parse script on a number of event files, do the following:

python3 parse_stats.py event.log event.log.? event.log.??

This will process the log files in reverse order, e.g. eveng.log.20, event.log.19, event.log.18, ..., event.log.10, eveng.log.9, eveng.log.8, ..., event.log.1, event.log.

The parsed data structure will be saved into a local file dump.pkl.

Then use load_stats.py to load the data structure from load_stats.py and perform further processing

