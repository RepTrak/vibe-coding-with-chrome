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
CERT = os.path.join(SCRIPT_DIR, "cert.pem")
KEY  = os.path.join(SCRIPT_DIR, "key.pem")

session_cmd = sys.argv[1:] if len(sys.argv) > 1 else []
ttyd_cmd = ["ttyd", "-W", "-S", "-C", CERT, "-K", KEY, "tmux", "new-session", "-A", "-s", "main"]
if session_cmd:
    ttyd_cmd.extend(session_cmd)

try:
    ttyd_process = subprocess.Popen(
        ttyd_cmd,
        stdout=subprocess.DEVNULL,  # Suppresses standard output
        stderr=subprocess.DEVNULL   # Suppresses error logs
    )
except FileNotFoundError:
    print("Error: 'ttyd' command not found. Please ensure it is installed.")
    sys.exit(1)

# 2. Initialize and start the Python HTTPServer thread
server = http.server.HTTPServer(('127.0.0.1', 7682), H)
ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
ctx.load_cert_chain(CERT, KEY)
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
            ttyd_process.terminate()  # Sends SIGTERM for a clean exit
            ttyd_process.wait()       # Ensure the process has completely closed
            
            print("All services stopped cleanly.")
            sys.exit(0)
            
    except (KeyboardInterrupt, SystemExit):
        # Fallback to catch Ctrl+C and still close ttyd cleanly
        ttyd_process.terminate()
        sys.exit(0)

