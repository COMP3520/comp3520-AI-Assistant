# SSH Setup for n8n Docker (Windows)

***

## 🔐 Choose Your Authentication Method

n8n supports two ways to authenticate SSH. **Pick one — you do not need both.**

| Method | Complexity | Security | When to Use |
|---|---|---|---|
| **Password** | Simple | Moderate | Quick setup / local use |
| **Private Key** | More steps | High | Production / recommended |

> ✅ **If you are using Password Authentication** — complete the [Windows SSH Setup](#windows-ssh-setup) steps below, then stop. You do **not** need the key generation steps.
>
> 🔑 **If you are using Private Key Authentication** — complete all steps including [Key Setup](#private-key-setup-skip-if-using-password).

***

> Run all commands in **PowerShell as Administrator**

***

## 🔧 Windows SSH Setup

### 1. Start the SSH Service

```powershell
Start-Service sshd

# Check if sshd is running
Get-Service -Name sshd
```

### 2. (Optional) Auto-Start on Boot

> ⚠️ Only enable this if you are comfortable with the security implications.

```powershell
Set-Service -Name sshd -StartupType Automatic
```

### 3. Restrict Firewall to Docker Network Only

Allows inbound SSH only from the Docker bridge network (`172.17.0.0/16`) to enhance safety.

```powershell
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server' `
  -Enabled True -Direction Inbound -Protocol TCP `
  -Action Allow -LocalPort 22 -RemoteAddress 172.17.0.0/16
```

### 4. Set Default Shell to PowerShell

```powershell
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" `
  -Name DefaultShell `
  -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" `
  -PropertyType String -Force
```

> ✅ **Password Authentication users: you are done here.**
> In n8n, create an SSH credential using **Host**, **Port**, **Username**, and **Password**.

***

## 🔑 Private Key Setup *(Skip if Using Password)*

### 5. Generate SSH Key Pair

```powershell
ssh-keygen -t ed25519 -C "n8n-docker" -f "$HOME\.ssh\n8n_key"
# Press Enter twice to skip passphrase
```

### 6. Copy Public Key to Authorized Keys 

```powershell
$pubKey = Get-Content "$HOME\.ssh\n8n_key.pub" -Raw
Add-Content -Force -Path "C:\ProgramData\ssh\administrators_authorized_keys" -Value $pubKey
```

### 7. Fix File Permissions

> SSH will reject the authorized_keys file if permissions are too open.

```powershell
icacls "C:\ProgramData\ssh\administrators_authorized_keys" `
  /inheritance:r `
  /grant "SYSTEM:(F)" `
  /grant "ADMINISTRATORS:(F)"
```

### 8. Copy Private Key into n8n

```powershell
Get-Content "$HOME\.ssh\n8n_key"
```

> Copy the entire output (including `-----BEGIN...-----` and `-----END...-----`) into n8n's **Private Key** field.

### 9. (Optional) Disable Password Authentication

Open `C:\ProgramData\ssh\sshd_config` in Notepad as Administrator and set:

```
PasswordAuthentication no
PubkeyAuthentication yes
```

Then restart SSH:

```powershell
Restart-Service sshd
```

> ⚠️ Make sure you have saved the private key into n8n **before** disabling password auth — or you will be locked out.

***

## 🗑️ Removal / Cleanup

### Stop and Disable SSH

```powershell
Stop-Service sshd
Set-Service -Name sshd -StartupType Disabled
```

### Uninstall OpenSSH Server

```powershell
Remove-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
```

### Remove Firewall Rule

```powershell
Remove-NetFirewallRule -Name "sshd"
```

### Delete Key Files

```powershell
Remove-Item "$HOME\.ssh\n8n_key" -Force
Remove-Item "$HOME\.ssh\n8n_key.pub" -Force
```

### Clear Authorized Keys

```powershell
Remove-Item "C:\ProgramData\ssh\administrators_authorized_keys" -Force
```

***