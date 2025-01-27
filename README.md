# sysview

sysview generates a simple monitoring dashboard from
[sysreport](https://github.com/torarg/sysreport) compliant reports.

Reports are received via STDIN and sysview then creates or updates the detail
view for the host specified in the received report and also updates the
index page.

## screenshots
### index view
![index view](screenshots/index_view.png)

### detail view
![detail view](screenshots/detail_view.png)

## requirements
- POSIX compliant shell
- tested only with OpenBSD userland tools (date, find, sed, ...)


## documentation
[sysview (1)](docs/sysview.md)
