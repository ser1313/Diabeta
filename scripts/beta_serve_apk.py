#!/usr/bin/env python3
"""Sirve un APK beta al móvil por la red local (Wi-Fi), sin Artifacts ni Internet.

- Escucha solo en la IP local que se indique (nunca 0.0.0.0 por defecto).
- La URL lleva un token aleatorio de un solo uso: cualquier otra ruta da 404.
- Se apaga sola tras la primera descarga completa o al agotar el tiempo.
- No publica nada: el APK no sale de tu red local.

Uso:
  python3 scripts/beta_serve_apk.py ruta/diabeta-beta.apk --host 192.168.1.20
  (opciones: --port 0 = puerto libre aleatorio, --minutes 10)
"""
import argparse
import hashlib
import http.server
import os
import secrets
import socket
import sys
import threading

CHUNK = 64 * 1024


def lan_ip_guess() -> str:
    """IP local de la interfaz con ruta por defecto (no envía tráfico)."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("192.0.2.1", 9))  # TEST-NET-1 (RFC 5737), no se contacta
        return s.getsockname()[0]
    except OSError:
        return "127.0.0.1"
    finally:
        s.close()


def main() -> int:
    sys.stdout.reconfigure(line_buffering=True)
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("apk")
    ap.add_argument("--host", help="IP local en la que escuchar (por defecto, la de tu Wi-Fi)")
    ap.add_argument("--port", type=int, default=0)
    ap.add_argument("--minutes", type=float, default=10)
    args = ap.parse_args()

    apk = os.path.abspath(args.apk)
    if not apk.endswith(".apk") or not os.path.isfile(apk):
        print("ERROR: indica un archivo .apk existente", file=sys.stderr)
        return 2
    host = args.host or lan_ip_guess()
    if host in ("0.0.0.0", "::"):
        print("ERROR: indica una IP concreta, no todas las interfaces", file=sys.stderr)
        return 2

    size = os.path.getsize(apk)
    sha = hashlib.sha256()
    with open(apk, "rb") as f:
        for b in iter(lambda: f.read(CHUNK), b""):
            sha.update(b)
    token = secrets.token_urlsafe(24)
    name = os.path.basename(apk)
    path = f"/{token}/{name}"
    done = threading.Event()

    class Handler(http.server.BaseHTTPRequestHandler):
        server_version = "diabeta-beta"
        sys_version = ""

        def do_GET(self):  # noqa: N802
            if self.path != path:
                self.send_error(404)
                return
            self.send_response(200)
            self.send_header("Content-Type", "application/vnd.android.package-archive")
            self.send_header("Content-Length", str(size))
            self.send_header("Content-Disposition", f'attachment; filename="{name}"')
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            sent = 0
            try:
                with open(apk, "rb") as f:
                    for b in iter(lambda: f.read(CHUNK), b""):
                        self.wfile.write(b)
                        sent += len(b)
            except (BrokenPipeError, ConnectionResetError):
                return
            if sent == size:
                print(f"Descarga completa desde {self.client_address[0]}. Cerrando.")
                done.set()

        def do_HEAD(self):  # noqa: N802
            self.send_error(405)

        def log_message(self, fmt, *a):
            # No registra el token.
            sys.stderr.write(f"{self.client_address[0]} {self.command} {self.path.split('/')[-1] if self.path == path else '(ruta no válida)'}\n")

    srv = http.server.ThreadingHTTPServer((host, args.port), Handler)
    port = srv.server_address[1]
    url = f"http://{host}:{port}{path}"
    print(f"APK: {name} ({size} bytes)\nSHA-256: {sha.hexdigest()}")
    print(f"\nAbre en el navegador del Samsung (misma Wi-Fi):\n  {url}\n")
    print(f"Se cierra tras la primera descarga completa o en {args.minutes:g} min.")
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    done.wait(timeout=args.minutes * 60)
    srv.shutdown()
    print("Servidor cerrado.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
