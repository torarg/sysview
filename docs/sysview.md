SYSVIEW(1) - General Commands Manual

# NAME

**sysview** - static html monitoring dashboard

# SYNOPSIS

**sysview**
\[**-dhV**]
*directory*

# DESCRIPTION

**sysview**
generates static html monitoring dashboards
from
sysreport(1)
compliant reports received on stdin.
The generated files are written to a given web root
*directory*.

The options are as follows:

**-h**

> Print usage.

**-V**

> Print version.

**-d** *days*

> **sysview**
> uses
> *days*
> to check if hosts or report items are outdated. If any cached
> status is older than
> *days*
> it is displayed as outdated. Default is 1.

# EXAMPLES

Add or update a host's
sysreport(1)
on a remote
web server's sysview dashboard:

	$ sysreport | ssh www sysview /var/www/htdocs/sysview

Delete host from cache:

	$ rm ~/.cache/sysview/HOSTNAME*

# SEE ALSO

sysreport(1)

# AUTHORS

Michael Wilson &lt;[mw@1wilson.org](mailto:mw@1wilson.org)&gt;

OpenBSD 7.6 - January 10, 2025
