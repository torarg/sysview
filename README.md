# sysview

sysview generates a simple monitoring dashboard from
[sysreport](https://github.com/torarg/sysreport) compliant reports.

Reports are received via STDIN and sysview then re(generates) the detail
view for the host specified in the received report. Also it re(generates) the
index page from it's cache and marks report items older than one day as outdated.




## usage
```
sysreport | ssh www sysview /var/www/htdocs/sysview
```


