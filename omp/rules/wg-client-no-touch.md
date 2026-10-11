---
name: wg-client-no-touch
description: "Never read or modify WireGuard client keys, configs, or database"
condition: "wg0\\.conf|clients_table|wg-easy\\.db|PrivateKey"
scope: "tool:bash"
---

Do not touch WireGuard client material. Never `cat` wg0.conf, `wg show`, copy/query wg-easy.db, SELECT from clients_table, or print PrivateKey/PublicKey/PresharedKey. Client WG config is user-owned. Diagnose server side only (host routes, Sunshine bind/ports, backlog) and ask before any WG change.