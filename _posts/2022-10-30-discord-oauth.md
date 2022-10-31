---
layout: post
title: "Adding a new discord bot"
---

When writing a discord bot, even if only for your own server, you need to use oauth to validate it. I wrote the following script to make it easy on myself, since i'm more than likely to do it again and forget how in the future. Make sure you have `bottle`, `requests` and `discordpy` (the bot framework i was writing in) runt hen simply browse to http://localhost:8080

Note that this requests `Permissions(8)` which is Administrator and only the scopes `bot`. You can change that at will - infact I suggest you don't grant Admin.

```python
import os, requests, string, random
from bottle import request, route, run, abort, redirect
from discord.utils import oauth_url
from discord import Permissions

state = ''.join(random.choice(string.ascii_letters) for i in range(10))


@route('/')
def index():
  redirect(oauth_url(os.environ['CLIENT_ID'], permissions=Permissions(8), redirect_uri='http://localhost:8080/oauth', scopes=['bot'], state=state))

@route('/oauth')
def exchange_code():
  code = request.query.code
  incstate = request.query.state
  if incstate != state:
    abort(401, "State mismatch somehow, are you being hacked...?")
  data = {
    'client_id': os.environ['CLIENT_ID'],
    'client_secret': os.environ['CLIENT_SECRET'],
    'grant_type': 'authorization_code',
    'code': code,
    'redirect_uri': 'http://localhost:8080/oauth'
  }
  headers = {'Content-Type': 'application/x-www-form-urlencoded'}
  r = requests.post('https://discord.com/api/oauth2/token', data=data, headers=headers)
  if 400 > r.status_code >= 200:
    rdata = r.json()
    access_token = rdata['access_token']
    return "Successfully added bot"
  print(r.text)
  abort(401, "Failed to use code to auth")


if __name__ == '__main__':
  if os.path.isfile('.env'):
    with open('.env') as f:
      for line in f:
        k, v = line.strip().split('=', 1)
        os.environ[k] = v
  assert 'CLIENT_ID' in os.environ
  assert 'CLIENT_SECRET' in os.environ
  assert 'BOT_TOKEN' in os.environ

  print('Open http://localhost:8080 in your browser')
  run(host='localhost', port=8080, debug=True)


```
