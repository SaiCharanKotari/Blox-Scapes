

python serve.py 8000


ngrok http 8000

"C:\Users\saich\.aftman\bin\rojo.exe" serve


<!-- 
import http.server
import os
import posixpath
import urllib.parse
import socketserver
import sys

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8000

class CodebaseViewerHandler(http.server.SimpleHTTPRequestHandler):
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))

    # Extensions that should be viewed directly in browser as readable text instead of downloading or rendering
    TEXT_EXTENSIONS = {
        '.luau', '.lua', '.md', '.markdown', '.toml', '.lock',
        '.json', '.yaml', '.yml', '.txt', '.log', '.gitignore',
        '.sample', '.ts', '.tsx', '.js', '.jsx', '.css', '.py', '.sh',
        '.html', '.htm'
    }

    def translate_path(self, path):
        # Decode path
        path = path.split('?', 1)[0]
        path = path.split('#', 1)[0]

        # Strip /GardenScapes prefix if present (supports both http://localhost:8000/ and http://localhost:8000/GardenScapes/)
        if path.startswith('/GardenScapes/'):
            path = path[len('/GardenScapes'):]
        elif path == '/GardenScapes':
            path = '/'

        # Translate relative to BASE_DIR (GardenScapes root)
        path = posixpath.normpath(urllib.parse.unquote(path))
        words = path.split('/')
        words = [_f for _f in words if _f]

        actual_path = self.BASE_DIR
        for word in words:
            if os.path.dirname(word) or word in (os.curdir, os.pardir):
                continue
            actual_path = os.path.join(actual_path, word)

        if path.endswith('/'):
            actual_path += os.sep

        return actual_path

    def guess_type(self, path):
        # Allow ?render=1 or ?render=true if you ever want to render the HTML UI page
        query = urllib.parse.urlsplit(self.path).query
        params = urllib.parse.parse_qs(query)
        if 'render' in params and params['render'][0].lower() in ('1', 'true', 'yes'):
            return super().guess_type(path)

        ext = os.path.splitext(path)[1].lower()
        # Serve code, markdown, and html files as text/plain so browser displays readable source
        if ext in self.TEXT_EXTENSIONS:
            return 'text/plain; charset=utf-8'
        return super().guess_type(path)

    def end_headers(self):
        # Prevent browser from sniffing text/plain as HTML
        self.send_header('X-Content-Type-Options', 'nosniff')
        # Prevent browser caching so MIME type changes apply immediately
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()

    def send_head(self):
        path = self.translate_path(self.path)

        # Always show directory listing on folders (do NOT auto-render index.html)
        if os.path.isdir(path):
            parts = urllib.parse.urlsplit(self.path)
            if not parts.path.endswith('/'):
                self.send_response(http.server.HTTPStatus.MOVED_PERMANENTLY)
                new_parts = (parts[0], parts[1], parts[2] + '/', parts[3], parts[4])
                self.send_header("Location", urllib.parse.urlunsplit(new_parts))
                self.send_header("Content-Length", "0")
                self.end_headers()
                return None
            return self.list_directory(path)

        return super().send_head()

if __name__ == '__main__':
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("", PORT), CodebaseViewerHandler) as httpd:
        print(f"=======================================================")
        print(f" Codebase Viewer Server running at: http://localhost:{PORT}")
        print(f" - Folders: Always show directory listing")
        print(f" - Both / and /GardenScapes/ URLs supported")
        print(f" - .luau / .md / .toml / .html: Open directly as readable text")
        print(f" - To render HTML UI: visit index.html?render=1")
        print(f"=======================================================")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nServer stopped.")
 -->
