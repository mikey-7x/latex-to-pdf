#!/bin/bash
#Architect: mikey-7x
#https://github.com/mikey-7x

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
    if command -v lualatex >/dev/null 2>&1; then
        if command -v nano >/dev/null 2>&1; then
            return
        fi
    fi
    echo -e "${YELLOW}[!] Required packages not found. Initializing auto-installer...${NC}"
    if [ -n "$TERMUX_VERSION" ]; then
        pkg update -y
        pkg install -y texlive texlive-installer fontconfig nano
        termux-setup-storage
    elif [ -f /etc/arch-release ]; then
        local SUDO_CMD=""
        if [ "$EUID" -ne 0 ]; then SUDO_CMD="sudo"; fi
        $SUDO_CMD pacman -Sy --needed --noconfirm texlive-basic texlive-latex texlive-latexextra texlive-fontsrecommended texlive-luatex noto-fonts nano
    elif [ -f /etc/debian_version ]; then
        local SUDO_CMD=""
        if [ "$EUID" -ne 0 ]; then SUDO_CMD="sudo"; fi
        $SUDO_CMD apt-get update
        $SUDO_CMD apt-get install -y texlive-latex-base texlive-latex-extra texlive-luatex texlive-fonts-recommended fonts-noto-core nano
    elif [ -f /etc/fedora-release ]; then
        local SUDO_CMD=""
        if [ "$EUID" -ne 0 ]; then SUDO_CMD="sudo"; fi
        $SUDO_CMD dnf install -y texlive-scheme-basic texlive-luatex texlive-latex-extra google-noto-sans-fonts nano
    else
        echo -e "${RED}[X] Unsupported OS.${NC}"
        sleep 3
        return
    fi
    echo -e "${CYAN}[*] Updating LuaLaTeX font cache...${NC}"
    luaotfload-tool --update
    echo -e "${GREEN}[+] Dependencies installed successfully!${NC}"
    sleep 2
}

compile_pdf() {
    local target_tex="$1"
    local base_name="${target_tex%.*}"
    local pdf_name="${base_name}.pdf"
    echo -e "\n${CYAN}[*] Compiling ${BOLD}$target_tex${NC}${CYAN} (Pass 1)...${NC}"
    lualatex --interaction=batchmode "$target_tex" > /dev/null 2>&1
    echo -e "${CYAN}[*] Compiling ${BOLD}$target_tex${NC}${CYAN} (Pass 2 - Resolving References)...${NC}"
    lualatex --interaction=batchmode "$target_tex" > /dev/null 2>&1
    if [ -f "$pdf_name" ]; then
        mkdir -p "$DEFAULT_OUT_DIR"
        mv "$pdf_name" "$DEFAULT_OUT_DIR/"
        echo -e "${GREEN}${BOLD}[+] SUCCESS! PDF saved to: $DEFAULT_OUT_DIR/$pdf_name${NC}"
    else
        echo -e "${RED}[X] COMPILATION FAILED. Please check your LaTeX syntax.${NC}"
    fi
    echo -e "${YELLOW}[*] Cleaning up temporary build files...${NC}"
    rm -f "${base_name}.aux" "${base_name}.log" "${base_name}.out" "${base_name}.toc"
    echo -e "\nPress Enter to continue..."
    read -r
}

create_new_pdf() {
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
    echo -n "Compile this file to PDF now? (y/n): "
    read -r choice
    if [[ "$choice" == [yY]* ]]; then
        compile_pdf "$filename"
    fi
}

list_and_compile() {
    clear
    echo -e "${BOLD}${CYAN} Compile Existing LaTeX Files ${NC}"
    shopt -s nullglob
    local tex_files=(*.tex)
    shopt -u nullglob
    if [ ${#tex_files[@]} -eq 0 ]; then
        echo -e "${RED}[!] No .tex files found.${NC}"
        echo -e "Press Enter to return..."
        read -r
        return
    fi
    echo -e "${YELLOW}Select a file to compile:${NC}\n"
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
            compile_pdf "$selected_file"
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
        echo "  1) Set default PDF Output Path"
        echo "  0) Back to Main Menu"
        echo ""
        echo -n "Select an option: "
        read -r choice
        case $choice in
            1)
                echo -e "\n${YELLOW}Enter FULL PATH where PDFs should be saved:${NC}"
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
    echo "  1) Create New LaTeX PDF"
    echo "  2) Compile Existing LaTeX File"
    echo "  3) Settings (Configure Output Path)"
    echo "  4) Exit Application"
    echo ""
    echo -n "Enter your choice [1-4]: "
    read -r main_choice
    case $main_choice in
        1) create_new_pdf ;;
        2) list_and_compile ;;
        3) settings_menu ;;
        4) echo -e "\n${GREEN}Goodbye!${NC}"; exit 0 ;;
        *) echo -e "${RED}[X] Invalid option.${NC}"; read -r ;;
    esac
done
