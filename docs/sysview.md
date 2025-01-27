SYSVIEW(1) - General Commands Manual

# NAME

**sysview** - static html monitoring dashboard

# SYNOPSIS

**sysview**
\[**-dhuV**]
*directory*

# DESCRIPTION

**sysview**
generates static html monitoring dashboards
from
sysreport(1)
compliant reports received on stdin.
The generated files are written to a given output
*directory*.

To avoid potentially harmful parallel execution,
**sysview**
uses flock to manage per target directory lock files.

The options are as follows:

**-d** *days*

> **sysview**
> uses
> *days*
> to check if hosts or report items are outdated. If any cached
> status is older than
> *days*
> it is displayed as outdated. Default is 1.

**-h**

> Print usage.

**-u**

> Updates dashboard from cache without reading from stdin.

**-V**

> Print version.

# FILES

*$HOME/.cache/sysview*

> Local cache directory containing host data and lock files.

# EXAMPLES

Add or update a host's
sysreport(1)
on a remote
web server's sysview dashboard:

	$ sysreport | ssh www sysview /var/www/htdocs/sysview

Delete host "www" from cache and update dashboard in
*/var/www/htdocs/sysview*:

	$ rm $HOME/.cache/sysview/_var_www_htdocs_sysview/www*
	$ sysview -u /var/www/htdocs/sysview

# SEE ALSO

sysreport(1)

# AUTHORS

Michael Wilson &lt;[mw@1wilson.org](mailto:mw@1wilson.org)&gt;

OpenBSD 7.6 - January 28, 2025
