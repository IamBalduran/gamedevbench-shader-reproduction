"""Resolve the selected provider through public HTTPS DNS, without keys."""
import ipaddress
import json
import urllib.request

def provider_dns_pins():
    host = 'api.shubiaobiao.cn'
    resolvers = (
        ('https://dns.google/resolve?name=' + host + '&type=A', {}),
        ('https://cloudflare-dns.com/dns-query?name=' + host + '&type=A',
         {'Accept': 'application/dns-json'}),
    )
    for url, headers in resolvers:
        try:
            request = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(request, timeout=10) as response:
                answer = json.load(response)
            addresses = []
            for record in answer.get('Answer', []):
                if record.get('type') != 1:
                    continue
                try:
                    address = ipaddress.ip_address(record['data'])
                except (KeyError, ValueError):
                    continue
                if address.is_global:
                    addresses.append(str(address))
            if addresses:
                return json.dumps({host: addresses})
        except (OSError, TimeoutError, ValueError):
            continue
    raise RuntimeError('Both public DNS resolvers failed or returned no public provider IP; no model request was made.')
