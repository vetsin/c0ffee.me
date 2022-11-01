---
layout: post
title: "Adding TLS to edgeos via acme.sh"
tags: [devops]
---


Basic guidelines to setup acme.sh with your dnsapi 

```bash
$ ./acme.sh --install --home /config/auth/.acme.sh --config-home 
# see https://github.com/acmesh-official/acme.sh/wiki/dnsapi
$ ./acme.sh --issue --dns ... your dns here ... -d router.your.domain
$ sudo chown root.root /config/auth/.acme.sh/router.your.domain/*
$ cat /config/auth/.acme.sh/router.your.domain/router.your.domain.key >> /config/auth/.acme.sh/routeryour.domain/fullchain.cer
$ configure
$ set service gui cert-file /config/auth/.acme.sh/router.your.domain/fullchain.cer
$ commit
$ save
```

Got errors? See if the service came up via `service lighttpd status`

Want to see real error messages? `/usr/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf`
