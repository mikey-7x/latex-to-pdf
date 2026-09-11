#!/bin/bash
#Architect: mikey-7x
#https://github.com/mikey-7x
#Upgraded for PDF, DOCX, DOC, PPTX, PPT support (Pure CLI Optimized & ARM Fixed)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

CONFIG_FILE="$HOME/.latex_env_config"
DEFAULT_OUT_DIR="$PWD"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

check_dependencies() {
    local missing=0
    command -v lualatex >/dev/null 2>&1 || missing=1
    command -v nano >/dev/null 2>&1 || missing=1
    command -v pandoc >/dev/null 2>&1 || missing=1
    command -v soffice >/dev/null 2>&1 || missing=1

    if [ $missing -eq 0 ]; then
        return
    fi

    echo -e "${YELLOW}[!] Required CLI packages (LaTeX, Pandoc, LibreOffice) not found. Initializing auto-installer...${NC}"
    
    if [ -n "$TERMUX_VERSION" ] && [ ! -f /etc/arch-release ]; then
        # Native Termux
        pkg update -y
        pkg install -y texlive texlive-installer fontconfig nano pandoc curl tar
        termux-setup-storage
        echo -e "${YELLOW}[!] Note: LibreOffice is unavailable in native Termux. Legacy .doc/.ppt conversions will be skipped.${NC}"
    elif [ -f /etc/arch-release ]; then
        # Arch Linux (Proot/Chroot in Termux)
        local SUDO_CMD=""
        if [ "$EUID" -ne 0 ]; then SUDO_CMD="sudo"; fi
        
        local ARCH_PKGS="texlive-basic texlive-latex texlive-latexextra texlive-fontsrecommended texlive-luatex noto-fonts nano curl tar"
        # Prevent conflicts: Only install libreoffice-fresh if soffice is completely missing
        if ! command -v soffice >/dev/null 2>&1; then
            ARCH_PKGS="$ARCH_PKGS libreoffice-fresh"
        fi
        
        $SUDO_CMD pacman -Sy --needed --noconfirm $ARCH_PKGS
    elif [ -f /etc/debian_version ]; then
        # Debian / Ubuntu (Proot)
        local SUDO_CMD=""
        if [ "$EUID" -ne 0 ]; then SUDO_CMD="sudo"; fi
        
        local DEB_PKGS="texlive-latex-base texlive-latex-extra texlive-luatex texlive-fonts-recommended fonts-noto-core nano pandoc curl tar"
        if ! command -v soffice >/dev/null 2>&1; then
            DEB_PKGS="$DEB_PKGS libreoffice-core libreoffice-writer libreoffice-impress"
        fi
        
        $SUDO_CMD apt-get update
        $SUDO_CMD apt-get install -y --no-install-recommends $DEB_PKGS
    elif [ -f /etc/fedora-release ]; then
        # Fedora (Proot)
        local SUDO_CMD=""
        if [ "$EUID" -ne 0 ]; then SUDO_CMD="sudo"; fi
        
        local FED_PKGS="texlive-scheme-basic texlive-luatex texlive-latex-extra google-noto-sans-fonts nano pandoc curl tar"
        if ! command -v soffice >/dev/null 2>&1; then
            FED_PKGS="$FED_PKGS libreoffice-headless"
        fi
        
        $SUDO_CMD dnf install -y $FED_PKGS
    else
        echo -e "${RED}[X] Unsupported OS.${NC}"
        sleep 3
        return
    fi
    
    # Install Pandoc manually if it's still missing (Fix for Arch Linux ARM)
    if ! command -v pandoc >/dev/null 2>&1; then
        echo -e "${YELLOW}[*] Pandoc not found in package manager. Downloading static binary from GitHub...${NC}"
        local ARCH=$(uname -m)
        local PANDOC_ARCH="amd64"
        if [ "$ARCH" = "aarch64" ]; then PANDOC_ARCH="arm64"; fi
        
        local PANDOC_VER="3.1.12.2" # Fallback version
        if command -v curl >/dev/null 2>&1; then
            # Fetch the latest release version tag from GitHub API
            local LATEST=$(curl -s https://api.github.com/repos/jgm/pandoc/releases/latest | grep '"tag_name":' | cut -d '"' -f 4)
            if [ -n "$LATEST" ]; then PANDOC_VER="$LATEST"; fi
        fi

        local TAR_URL="https://github.com/jgm/pandoc/releases/download/${PANDOC_VER}/pandoc-${PANDOC_VER}-linux-${PANDOC_ARCH}.tar.gz"
        
        local SUDO_CMD=""
        if [ "$EUID" -ne 0 ]; then SUDO_CMD="sudo"; fi

        if command -v curl >/dev/null 2>&1 && command -v tar >/dev/null 2>&1; then
            echo -e "${CYAN}[*] Downloading Pandoc ${PANDOC_VER} for ${PANDOC_ARCH}...${NC}"
            curl -sL "$TAR_URL" | tar xz -C /tmp
            if [ -d "/tmp/pandoc-${PANDOC_VER}" ]; then
                $SUDO_CMD cp "/tmp/pandoc-${PANDOC_VER}/bin/pandoc" /usr/bin/
                $SUDO_CMD chmod +x /usr/bin/pandoc
                rm -rf "/tmp/pandoc-${PANDOC_VER}"
                echo -e "${GREEN}[+] Pandoc installed successfully!${NC}"
            else
                echo -e "${RED}[X] Failed to extract Pandoc. Conversion to DOCX/PPTX may fail.${NC}"
            fi
        else
            echo -e "${RED}[X] curl or tar is missing. Cannot download Pandoc.${NC}"
        fi
    fi

    echo -e "${CYAN}[*] Updating LuaLaTeX font cache...${NC}"
    luaotfload-tool --update
    echo -e "${GREEN}[+] Dependencies installed successfully!${NC}"
    sleep 2
}

compile_document() {
    local target_tex="$1"
    local format="$2"
    local base_name="${target_tex%.*}"
    local out_name=""

    # Force LibreOffice to run purely in CLI without looking for X11/Wayland display
    export SAL_USE_VCLPLUGIN=gen

    case "$format" in
        pdf)
            out_name="${base_name}.pdf"
            echo -e "\n${CYAN}[*] Compiling ${BOLD}$target_tex${NC}${CYAN} to PDF (Pass 1)...${NC}"
            lualatex --interaction=batchmode "$target_tex" > /dev/null 2>&1
            echo -e "${CYAN}[*] Compiling ${BOLD}$target_tex${NC}${CYAN} to PDF (Pass 2 - Resolving References)...${NC}"
            lualatex --interaction=batchmode "$target_tex" > /dev/null 2>&1
            ;;
        docx)
            out_name="${base_name}.docx"
            echo -e "\n${CYAN}[*] Converting ${BOLD}$target_tex${NC}${CYAN} to DOCX using Pandoc...${NC}"
            pandoc "$target_tex" -o "$out_name"
            ;;
        pptx)
            out_name="${base_name}.pptx"
            echo -e "\n${CYAN}[*] Converting ${BOLD}$target_tex${NC}${CYAN} to PPTX using Pandoc...${NC}"
            pandoc "$target_tex" -o "$out_name"
            ;;
        doc)
            out_name="${base_name}.doc"
            echo -e "\n${CYAN}[*] Converting ${BOLD}$target_tex${NC}${CYAN} to DOCX using Pandoc...${NC}"
            pandoc "$target_tex" -o "${base_name}.docx"
            echo -e "${CYAN}[*] Converting DOCX to legacy DOC using LibreOffice (Strict Headless CLI)...${NC}"
            if command -v soffice >/dev/null 2>&1; then
                soffice --headless --invisible --nologo --nodefault --convert-to doc "${base_name}.docx" > /dev/null 2>&1
                rm -f "${base_name}.docx"
            else
                echo -e "${RED}[X] LibreOffice (soffice) not found. Cannot convert to legacy .doc format.${NC}"
                return
            fi
            ;;
        ppt)
            out_name="${base_name}.ppt"
            echo -e "\n${CYAN}[*] Converting ${BOLD}$target_tex${NC}${CYAN} to PPTX using Pandoc...${NC}"
            pandoc "$target_tex" -o "${base_name}.pptx"
            echo -e "${CYAN}[*] Converting PPTX to legacy PPT using LibreOffice (Strict Headless CLI)...${NC}"
            if command -v soffice >/dev/null 2>&1; then
                soffice --headless --invisible --nologo --nodefault --convert-to ppt "${base_name}.pptx" > /dev/null 2>&1
                rm -f "${base_name}.pptx"
            else
                echo -e "${RED}[X] LibreOffice (soffice) not found. Cannot convert to legacy .ppt format.${NC}"
                return
            fi
            ;;
    esac

    if [ -f "$out_name" ]; then
        mkdir -p "$DEFAULT_OUT_DIR"
        mv "$out_name" "$DEFAULT_OUT_DIR/"
        echo -e "${GREEN}${BOLD}[+] SUCCESS! File saved to: $DEFAULT_OUT_DIR/$out_name${NC}"
    else
        echo -e "${RED}[X] COMPILATION/CONVERSION FAILED. Please check your LaTeX syntax.${NC}"
    fi

    if [ "$format" == "pdf" ]; then
        echo -e "${YELLOW}[*] Cleaning up temporary build files...${NC}"
        rm -f "${base_name}.aux" "${base_name}.log" "${base_name}.out" "${base_name}.toc"
    fi
    
    echo -e "\nPress Enter to continue..."
    read -r
}

select_format_and_compile() {
    local filename="$1"
    echo -e "\n${YELLOW}Select Output Format for ${BOLD}$filename${NC}:"
    echo "  1) PDF  (Standard LaTeX Compile)"
    echo "  2) DOCX (Word Document - Fast CLI)"
    echo "  3) DOC  (Legacy Word Document)"
    echo "  4) PPTX (PowerPoint Presentation - Fast CLI)"
    echo "  5) PPT  (Legacy PowerPoint)"
    echo "  0) Cancel"
    echo ""
    echo -n "Enter your choice [0-5]: "
    read -r fmt_choice

    case $fmt_choice in
        1) compile_document "$filename" "pdf" ;;
        2) compile_document "$filename" "docx" ;;
        3) compile_document "$filename" "doc" ;;
        4) compile_document "$filename" "pptx" ;;
        5) compile_document "$filename" "ppt" ;;
        0) return ;;
        *) echo -e "${RED}[X] Invalid choice.${NC}"; sleep 1 ;;
    esac
}

create_new_document() {
    clear
    echo -e "${BOLD}${CYAN} Create New LaTeX File ${NC}"
    echo -e "Enter the name for your new file:"
    read -r -e filename
    if [[ "$filename" != *.tex ]]; then
        filename="${filename}.tex"
    fi
    echo -e "${YELLOW}[*] Opening Nano editor. Paste code, save (Ctrl+O, Enter), exit (Ctrl+X).${NC}"
    sleep 2
    nano "$filename"
    echo -e "\n${CYAN}File saved as $filename.${NC}"
    echo -n "Compile/Convert this file now? (y/n): "
    read -r choice
    if [[ "$choice" == [yY]* ]]; then
        select_format_and_compile "$filename"
    fi
}

list_and_compile() {
    clear
    echo -e "${BOLD}${CYAN} Compile/Convert Existing LaTeX Files ${NC}"
    shopt -s nullglob
    local tex_files=(*.tex)
    shopt -u nullglob
    if [ ${#tex_files[@]} -eq 0 ]; then
        echo -e "${RED}[!] No .tex files found.${NC}"
        echo -e "Press Enter to return..."
        read -r
        return
    fi
    echo -e "${YELLOW}Select a file to process:${NC}\n"
    local i=1
    for file in "${tex_files[@]}"; do
        echo "  $i) $file"
        ((i++))
    done
    echo "  0) Cancel and return"
    echo ""
    echo -n "Enter your choice: "
    read -r choice
    if [[ "$choice" == "0" ]]; then
        return
    fi
    if [ "$choice" -gt 0 ] 2>/dev/null; then
        if [ "$choice" -le ${#tex_files[@]} ] 2>/dev/null; then
            local selected_index=$((choice - 1))
            local selected_file="${tex_files[$selected_index]}"
            select_format_and_compile "$selected_file"
            return
        fi
    fi
    echo -e "${RED}[X] Invalid selection.${NC}"
    sleep 1
}

settings_menu() {
    while true; do
        clear
        echo -e "${BOLD}${CYAN} Settings ${NC}"
        echo -e "Current Output Path: ${GREEN}$DEFAULT_OUT_DIR${NC}\n"
        echo "  1) Set default Output Path"
        echo "  0) Back to Main Menu"
        echo ""
        echo -n "Select an option: "
        read -r choice
        case $choice in
            1)
                echo -e "\n${YELLOW}Enter FULL PATH where files should be saved:${NC}"
                read -r -e new_dir
                new_dir="${new_dir/#\~/$HOME}"
                if [ -n "$new_dir" ]; then
                    DEFAULT_OUT_DIR="$new_dir"
                    echo "DEFAULT_OUT_DIR=\"$DEFAULT_OUT_DIR\"" > "$CONFIG_FILE"
                    echo -e "${GREEN}[+] Path saved!${NC}"
                    sleep 1
                fi
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}[X] Invalid choice.${NC}"
                sleep 1
                ;;
        esac
    done
}

check_dependencies

while true; do
    clear
    echo -e "${BOLD}${CYAN}"
    echo " LATEX WORKSPACE CLI "
    echo -e "${NC}"
    echo -e "Target Output Directory: ${GREEN}$DEFAULT_OUT_DIR${NC}\n"
    echo "  1) Create New LaTeX Document"
    echo "  2) Compile/Convert Existing LaTeX File"
    echo "  3) Settings (Configure Output Path)"
    echo "  4) Exit Application"
    echo ""
    echo -n "Enter your choice [1-4]: "
    read -r main_choice
    case $main_choice in
        1) create_new_document ;;
        2) list_and_compile ;;
        3) settings_menu ;;
        4) echo -e "\n${GREEN}Goodbye!${NC}"; exit 0 ;;
        *) echo -e "${RED}[X] Invalid option.${NC}"; read -r ;;
    esac
done
