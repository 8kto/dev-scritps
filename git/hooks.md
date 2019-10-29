#### Add a ticket no in the commit message
```shell script
cp .git/hooks/prepare-commit-msg.sample .git/hooks/prepare-commit-msg
```

```shell script
#!/bin/sh

TICKET_NO=$(git rev-parse --abbrev-ref HEAD | egrep -i 'saefrnt\-[0-9]+' -o)

if [ -n "$TICKET_NO" ]; then
  sed -i "1i$TICKET_NO " $1
fi
```
