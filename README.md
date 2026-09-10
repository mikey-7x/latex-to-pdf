# 📄 latex-to-pdf

**Latex-to-PDF** is a highly intelligent, interactive Command-Line Interface (CLI) workspace for Linux and Android (Termux). It provides a seamless, distraction-free environment to write, manage, and compile LaTeX documents into beautifully formatted PDFs without needing heavy graphical IDEs.

Whether you are writing lab manuals on your Android phone via Termux or drafting research papers on a desktop Linux distro, this tool handles all the heavy lifting—including dependency management, silent compilation, and file cleanup.

---

## ✨ Key Features

*   **🤖 Smart OS Detection & Auto-Installation:** Never worry about missing packages again. The script automatically detects your environment (Termux, Arch Linux, Debian/Ubuntu, or Fedora) and installs the required LaTeX engine (`lualatex`), fonts (`noto-fonts`), and text editor (`nano`) only if they are missing.
*   **🎨 Interactive CLI UI:** A beautiful, color-coded terminal interface that is easy to navigate using simple numerical inputs.
*   **📝 Integrated Workflow:** Create new `.tex` files directly from the menu. The tool automatically opens `nano` for you to write or paste your code, and prompts you to compile the moment you exit.
*   **📂 Dynamic File Discovery:** Automatically scans your current working directory for existing `.tex` files and presents them in a selectable, numbered list for quick compilation.
*   **⚙️ Persistent Output Settings:** Choose exactly where you want your generated PDFs to go (e.g., your Android `/storage/emulated/0/Documents` folder or Desktop). The tool saves this path to a hidden config file (`~/.latex_env_config`) so it remembers your preference forever.
*   **🧹 Auto-Cleanup & Smart Compilation:** Uses `batchmode` to hide messy LaTeX compilation logs. It automatically runs two passes to resolve document references, outputs the final PDF to your target directory, and instantly deletes all temporary junk files (`.aux`, `.log`, `.out`, `.toc`).

---

## 💻 Supported Platforms

The auto-installer natively supports:
*   **Android:** Termux (Native & PRoot Arch Linux)
*   **Arch Linux** / Manjaro / EndeavourOS
*   **Debian** / Ubuntu / Linux Mint
*   **Fedora**

---

## 🚀 Installation & Setup

1. **Clone or Download the script:**
   Create a new file named `latex_builder.sh` on your system and paste the script code into it.
   
   *Alternatively, download it via terminal:*
   ```bash
   curl -O https://raw.githubusercontent.com/YOUR_USERNAME/latex-to-pdf/main/latex_builder.sh
   ```

2. **Make the script executable:**
   ```bash
   chmod +x latex_builder.sh
   ```

3. **Run the tool:**
   ```bash
   ./latex_builder.sh
   ```
   *Note: On its first run, the script may ask for `sudo` password to install required TeX Live packages depending on your OS.*

---

## 🛠️ How to Use

When you launch the script, you will be greeted by the Main Menu:

### Option 1: Create New LaTeX PDF
*   Prompts you for a file name (automatically appends `.tex` if you forget).
*   Opens the `nano` editor.
*   Write or paste your LaTeX code here. Press `Ctrl + O` (then Enter) to save, and `Ctrl + X` to exit.
*   The script will immediately ask if you want to compile it into a PDF.

### Option 2: Compile Existing LaTeX File
*   Scans the folder you launched the script from.
*   Lists all `.tex` files with numbers.
*   Simply type the number of the file you want to compile and press Enter.

### Option 3: Settings (Configure Output Path)
*   By default, PDFs are saved in the folder where the script is run.
*   Use this option to set a **custom global output path**.
*   *Example for Android users:* `/storage/emulated/0/Download`
*   *Example for Desktop users:* `~/Desktop/PDFs`
*   This setting is saved permanently until you change it again.

### Option 4: Exit
*   Safely closes the workspace.

---

## ⚠️ Troubleshooting (Android / Termux Users)

If you are copying LaTeX code or scripts from a web browser on Android and pasting them into the Termux terminal, Android's clipboard sometimes injects **invisible "Zero-Width Space" characters**. These invisible characters can cause bash syntax errors or LaTeX compilation failures.

**The Fix:**
If your script fails to run after copy-pasting it, run this command to instantly clean the file of invisible formatting bugs:
```bash
tr -cd '\11\12\15\40-\176' < latex_builder.sh > clean.sh && mv clean.sh latex_builder.sh && chmod +x latex_builder.sh
```

---
## 👨‍🔬 Author Info

**Project Creator:** *Mikey-7x / Yogesh R. Chauhan*  
**GitHub:** [github.com/mikey-7x](https://github.com/mikey-7x)  
**License:** [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)  
**Date:** 10 September 2026 
