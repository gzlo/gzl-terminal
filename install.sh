#!/bin/bash

# Este script configura un entorno de terminal completo, inspirado en
# la automatización de scripts como el de Chris Titus, pero usando tus
# configuraciones personales.
#

# Asegurarse de que el script se ejecuta con bash
if [ -z "$BASH_VERSION" ]; then
    echo "¡Atención! Este script debería ejecutarse con bash. Reintentando con bash..."
    exec bash "$0" "$@"
fi

#
# install.sh
#
# Pasos que realiza:
# 1. Instala dependencias (git, tmux, herramientas de compilación).
# 2. Instala herramientas modernas de CLI (Starship, eza, bat, fzf).
# 3. Descarga e instala una Nerd Font (FiraCode).
# 4. Instala la última versión de Neovim (AppImage).
# 5. Clona/actualiza este repositorio de dotfiles.
# 6. Crea enlaces simbólicos para las configuraciones.
# 7. Instala el gestor de plugins de Tmux (tpm).
# 8. Sincroniza los plugins de Neovim (LazyVim).
#

set -e


# --- Helper Functions ---
print_info() { echo -e "\e[34mINFO: $1\e[0m"; }
print_success() { echo -e "\e[32mSUCCESS: $1\e[0m"; }
print_error() { echo -e "\e[31mERROR: $1\e[0m"; }

# --- Variables ---
REPO_URL="https://github.com/gzlo/gzl-terminal.git"
DOTFILES_DIR="$HOME/dotfiles" # Se clona aquí, no en .dotfiles, para evitar conflictos con el script
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip"


# --- Confirmation Function ---
ask_for_confirmation() {
    print_info "Este script instalará/configurará lo siguiente:"
    print_info "  - Dependencias del sistema (git, tmux, curl, build-essential, fzf, ripgrep, etc.)"
    print_info "  - La última versión de Neovim (vía PPA diario para Debian/Ubuntu, >=0.10.0)."
    print_info "  - Una Nerd Font (FiraCode) en ~/.local/share/fonts."
    print_info "  - Clonará/actualizará tus dotfiles en ~/dotfiles."
    print_info "  - Creará enlaces simbólicos para Neovim (~/.config/nvim) y Bash (~/.bashrc)."
    print_info "  - Instalará el Tmux Plugin Manager (tpm)."
    print_info "  - Sincronizará los plugins de Neovim (LazyVim)."
    print_info ""
    read -r -p "¿Deseas proceder con la instalación? (escribe 'y' o 'Y' para confirmar y presiona Enter): " REPLY < /dev/tty
    echo # (optional) move to a new line
    if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
        print_info "Instalación cancelada por el usuario."
        exit 0
    fi
}


# --- Installation Functions ---

install_dependencies() {
    print_info "Instalando dependencias del sistema..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get update
        sudo apt-get install -y git tmux curl unzip build-essential fzf ripgrep
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y git tmux curl unzip fzf ripgrep 'dnf-command(builddep)'
        sudo dnf builddep -y neovim
    elif command -v pacman &>/dev/null; then
        sudo pacman -Syu --noconfirm git tmux curl unzip fzf ripgrep base-devel
    else
        print_error "Gestor de paquetes no soportado. Por favor, instala manualmente: git, tmux, curl, unzip, fzf, ripgrep."
        exit 1
    fi
}

install_modern_cli() {
    print_info "Instalando herramientas modernas de CLI..."
    # Starship
    print_info "Instalando Starship prompt..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    
    # Eza (reemplazo de ls)
    if ! command -v eza &>/dev/null; then
        print_info "Instalando eza..."
        cargo install eza
    fi

    # Bat (reemplazo de cat)
    if ! command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
        print_info "Instalando bat..."
        cargo install bat
    fi
}


install_nerd_font() {
    print_info "Instalando FiraCode Nerd Font..."
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
    cd "$FONT_DIR"
    curl -fLo "FiraCode.zip" "$FONT_URL"
    unzip -o FiraCode.zip
    rm FiraCode.zip
    fc-cache -f -v
    cd -
}

install_neovim() {
    print_info "Instalando la última versión de Neovim (vía PPA para Debian/Ubuntu para asegurar >=0.10.0)..."
    if command -v apt-get &>/dev/null; then
        # Check if lsb_release is installed
        if ! command -v lsb_release &>/dev/null; then
            print_info "Instalando lsb-release para detectar la versión de Ubuntu."
            sudo apt-get update && sudo apt-get install -y lsb-release || { print_error "Fallo al instalar lsb-release."; exit 1; }
        fi

        UBUNTU_CODENAME=$(lsb_release -sc) # e.g., noble, jammy

        CURRENT_NVIM_VERSION=$(nvim --version 2>/dev/null | head -n 1 | grep -oP 'NVIM v\K\d+\.\d+')
        NEEDS_UPGRADE=false
        if [[ -z "$CURRENT_NVIM_VERSION" ]]; then # nvim not found
            NEEDS_UPGRADE=true
        else
            NVIM_MAJOR=$(echo "$CURRENT_NVIM_VERSION" | cut -d'.' -f1)
            NVIM_MINOR=$(echo "$CURRENT_NVIM_VERSION" | cut -d'.' -f2)
            if (( NVIM_MAJOR < 0 || (NVIM_MAJOR == 0 && NVIM_MINOR < 10) )); then
                NEEDS_UPGRADE=true
            fi
        fi

        if "$NEEDS_UPGRADE" ; then
            print_info "Actualizando listado de paquetes e instalando software-properties-common."
            sudo apt-get update || { print_error "Fallo al actualizar apt-get."; exit 1; }
            sudo apt-get install -y software-properties-common || { print_error "Fallo al instalar software-properties-common."; exit 1; }

            # Remove stable PPA if it was added
            print_info "Intentando eliminar PPA stable de Neovim si existe."
            sudo add-apt-repository --remove --yes ppa:neovim-ppa/stable || true

            # Add appropriate PPA based on Ubuntu codename
            if [ "$UBUNTU_CODENAME" == "noble" ]; then
                print_info "Detectado Ubuntu Noble. Añadiendo PPA 'unstable' para Neovim."
                sudo add-apt-repository --yes ppa:neovim-ppa/unstable || { print_error "Fallo al añadir PPA 'unstable'."; exit 1; }
            else
                print_info "Usando PPA 'daily' para Neovim diario."
                sudo add-apt-repository --yes ppa:neovim-ppa/daily || { print_error "Fallo al añadir PPA 'daily'."; exit 1; }
            fi
            
            print_info "Actualizando listado de paquetes y instalando Neovim."
            sudo apt-get update || { print_error "Fallo al actualizar apt-get después de añadir PPA."; exit 1; }
            sudo apt-get install -y neovim || { print_error "Fallo al instalar Neovim desde el PPA."; exit 1; }
        else
            print_info "Neovim ya está instalado y es la versión requerida (>=0.10.0)."
        fi
    else
        # Fallback for non-Debian/Ubuntu systems - AppImage
        print_info "Sistema no Debian/Ubuntu o PPA no disponible. Intentando instalar Neovim via AppImage (puede fallar)..."
        # This part of the script is not the current issue, but it should correctly download the AppImage and put it in /usr/local/bin
        if [ ! -f /usr/local/bin/nvim ] || ! /usr/local/bin/nvim --version | grep -q "NVIM v0.10"; then
            curl -fLo "$HOME/nvim.appimage" "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage"
            chmod u+x "$HOME/nvim.appimage"
            sudo mv "$HOME/nvim.appimage" /usr/local/bin/nvim
        else
            print_info "Neovim AppImage ya parece estar instalado y es la versión requerida (>=0.10.0)."
        fi
    fi
}

# --- Main Execution ---

main() {
    ask_for_confirmation # Solicitar confirmación al inicio
    install_dependencies
    # install_modern_cli # Comentado por ahora para evitar dependencias de RUST/Cargo
    install_nerd_font
    install_neovim

    print_info "Clonando/actualizando repositorio de dotfiles..."
    if [ -d "$DOTFILES_DIR" ]; then
        print_info "Directorio de dotfiles encontrado. Actualizando..."
        git -C "$DOTFILES_DIR" pull
    else
        git clone "$REPO_URL" "$DOTFILES_DIR"
    fi
    
    cd "$DOTFILES_DIR"

    print_info "Creando enlaces simbólicos..."
    mkdir -p "$HOME/.config"
    
    # Bash
    ln -sf "$DOTFILES_DIR/bashrc" "$HOME/.bashrc"
    
    # Neovim
    ln -sf "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
    
    # Tmux (solo si existe el archivo)
    if [ -f "$DOTFILES_DIR/tmux.conf" ]; then
        ln -sf "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf"
    fi
    
    print_info "Configurando Starship en .bashrc..."
    # Asegurarse de que no se duplique
    if ! grep -q 'starship init bash' "$HOME/.bashrc"; then
        echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"
    fi
    
    print_info "Instalando Tmux Plugin Manager (tpm)..."
    TPM_DIR="$HOME/.tmux/plugins/tpm"
    if [ ! -d "$TPM_DIR" ]; then
        git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    fi
    
    print_info "Sincronizando plugins de Neovim (LazyVim)..."
    nvim --headless "+Lazy! sync" +qa
    
    print_success "¡Entorno configurado!"
    print_info "Por favor, reinicia tu terminal o ejecuta 'source ~/.bashrc'."
    print_info "En Tmux, recuerda presionar 'prefix + I' para instalar los plugins."
}

main "$@"
