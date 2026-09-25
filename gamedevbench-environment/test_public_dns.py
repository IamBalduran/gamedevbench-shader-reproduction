"""Offline checks for the provider DNS pin preflight."""
import io
import json
import urllib.error
import unittest
from unittest.mock import patch

import public_dns


class DNSPinTests(unittest.TestCase):
    def test_uses_second_resolver_after_tls_failure(self):
        response = io.BytesIO(json.dumps({
            'Answer': [{'type': 1, 'data': '198.18.0.175'},
                       {'type': 1, 'data': '104.21.32.1'}]
        }).encode())
        with patch.object(public_dns.urllib.request, 'urlopen',
                          side_effect=[urllib.error.URLError('TLS EOF'), response]) as urlopen:
            pins = json.loads(public_dns.provider_dns_pins())
        self.assertEqual(pins['api.shubiaobiao.cn'], ['104.21.32.1'])
        self.assertIn('cloudflare-dns.com', urlopen.call_args_list[1].args[0].full_url)

    def test_does_not_use_fake_ip_when_both_resolvers_fail(self):
        response = io.BytesIO(json.dumps({
            'Answer': [{'type': 1, 'data': '198.18.0.175'}]
        }).encode())
        with patch.object(public_dns.urllib.request, 'urlopen',
                          side_effect=[urllib.error.URLError('TLS EOF'), response]):
            with self.assertRaisesRegex(RuntimeError, 'no public provider IP'):
                public_dns.provider_dns_pins()


if __name__ == '__main__':
    unittest.main()
