import http.server
import subprocess
import ssl
import threading
import sys
import os

class H(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        cmd = self.rfile.read(int(self.headers['Content-Length'])).decode()
        if '\n' in cmd:
            subprocess.run(['tmux', 'send-keys', '-t', 'main', '\x1b[200~' + cmd + '\x1b[201~'])
        else:
            subprocess.run(['tmux', 'send-keys', '-t', 'main', cmd])
        subprocess.run(['tmux', 'send-keys', '-t', 'main', 'Enter'])
        self.send_response(200)
        self.end_headers()
        
    def log_message(self, *a):
        pass

# 1. Start ttyd in the background and suppress all screen output
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CERT      = os.path.join(SCRIPT_DIR, "cert.pem")
KEY       = os.path.join(SCRIPT_DIR, "key.pem")
WORKSPACE = os.path.normpath(os.path.join(SCRIPT_DIR, '..', 'workspace'))
os.makedirs(WORKSPACE, exist_ok=True)

session_cmd = sys.argv[1:] if len(sys.argv) > 1 else []
ttyd_cmd = ["ttyd", "-W", "-S", "-C", CERT, "-K", KEY, "tmux", "new-session", "-A", "-s", "main", "-c", WORKSPACE]
if session_cmd:
    ttyd_cmd.extend(session_cmd)

try:
    ttyd_process = subprocess.Popen(
        ttyd_cmd,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )
except FileNotFoundError:
    print("Error: 'ttyd' command not found. Please ensure it is installed.")
    sys.exit(1)

# 2. Initialize and start the Python HTTPServer thread
# Bind to 0.0.0.0 so WSL2's localhost-forwarding proxy can reach it from Windows
server = http.server.HTTPServer(('0.0.0.0', 7682), H)
ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
try:
    ctx.load_cert_chain(CERT, KEY)
except (FileNotFoundError, ssl.SSLError) as e:
    print(f"Error: could not load TLS certificate — {e}")
    print(f"Expected cert: {CERT}")
    print(f"Expected key:  {KEY}")
    ttyd_process.terminate()
    sys.exit(1)
server.socket = ctx.wrap_socket(server.socket, server_side=True)

server_thread = threading.Thread(target=server.serve_forever)
server_thread.daemon = True
server_thread.start()

print("Services successfully started.")
print("Press q + Enter to quit")

# 3. Monitor for the quit command and stop services in order
while True:
    try:
        user_input = input().strip().lower()
        if user_input == 'q':
            print("\nShutting down services...")
            
            # Orderly shutdown step 1: Stop the Python HTTPServer
            print("- Stopping HTTP server...")
            server.shutdown()
            server.server_close()
            
            # Orderly shutdown step 2: Terminate ttyd
            print("- Stopping ttyd...")
            ttyd_process.terminate()
            try:
                ttyd_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                ttyd_process.kill()

            print("All services stopped cleanly.")
            sys.exit(0)

    except (KeyboardInterrupt, SystemExit, EOFError):
        # Fallback to catch Ctrl+C, EOFError (stdin closed), and still close cleanly
        print("\nShutting down services...")
        server.shutdown()
        server.server_close()
        ttyd_process.terminate()
        try:
            ttyd_process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            ttyd_process.kill()
        sys.exit(0)

