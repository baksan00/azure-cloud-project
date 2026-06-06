<div align="center">
  <a href="https://github.com/baksan00/marinac" target="_blank">
    <img src="assets/chat-app.png" width="160" alt="Marinac Logo">
  </a>

  <h2>Secure Chat — Marinac</h2>
</div>

## 💡 Project overview
An end-to-end encrypted real-time chat application developed for a university Cryptography course project.

Designed for both Windows and Linux operating systems.

Marinac provides secure private communication in a lightweight terminal-based environment using modern cryptographic primitives and secure protocol design principles.


## ✨ Architecture
- Secure authentication
- E2EE messaging
- X25519 key exchange
- AEAD encryption
- Replay protection

## ✨ Prerequisites
- Python 3.11+
- Git

## 👩‍💻 Deployment steps
1. **Clone Repository**
```bash
git clone https://github.com/baksan00/marinac.git
cd marinac
```
## 🛠️  Application deployment
2. **Install**
```bash
cd Server
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```
3. **Run server:**
```
python3 run_server.py
```

The server listens on:
ws://0.0.0.0:8765/ws

## 👩‍💻 Validation
```bash
cd Client
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```
Run client:
```
python3 client.py
```

## 👩‍💻 Cleanup
```Powershell
cd Client
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```
During this step, an error may occur because PowerShell script execution is disabled on the system.
To temporarily allow script execution for the current PowerShell session, run:
```Powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```
Run client:
```bash
python client.py
```
---
# 🔥🔥 Prebuilt Client Executables

Prebuilt client binaries are available in the GitHub Releases section.
Users do not need to install Python or manually install dependencies.
Available at: https://github.com/baksan00/marinac/releases

## Windows Client (PE Executable)
Download:
secure-chat-client (PE)

Run:
```Powershell
.\secure-chat-client.exe
```
## Linux Client (ELF Executable)

Download:
secure-chat-client (ELF)

Make executable:
```bash
chmod +x secure-chat-client
```
Run:
```bash
./secure-chat-client
```